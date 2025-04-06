defmodule Sorcery.LiveHelpers do
  @moduledoc ~s"""
  Functions for combining Sorcery and LiveViews
  """
alias ElixirLS.LanguageServer.Plugins.Phoenix

  # {{{ callback docs
  @doc ~s"""
  Wherever you keep your handle_info functions, put this: 
  ```elixir
  defmodule MyModule do
    use Sorcery.LiveHelpers

    def handle_info({:sorcery, _} = msg, socket), do: handle_sorcery(msg, socket)
    # If you have any other handle_info's, put them BELOW
  end
  ```
  By doing this, the socket will automatically communicate with the rest of Sorcery.
  For example whenever we receive new data about a portal, this is where it happens.

  You can optionally pass in an options argument, which is handy for writing your own middleware.
  
  ```elixir
  defmodule SomeModule do
    def my_func(socket, msg), {:ok, socket}
    def another_func(socket, msg), {:ok, socket}
  end

  defmodule MyModule do
    use Sorcery.LiveHelpers

    def handle_info({:sorcery, _} = msg, socket), do: handle_sorcery(msg, socket,
      hook_before: [&SomeModule.my_func/2],
      hook_after: [&SomeModule.another_func/2],
    )
  end
  ```
  Note that every middleware function must return a tuple. Either {:ok, socket} or {:error, socket}

  In this case, every time the LiveView receives a sorcery message, it will:

  1. Call all the functions in hook_before, in order
  2. Do some sorcery magic behind the scenes
  3. Call all the functions in hook_after, in order

  Often in step 2, it will send a message to the parent PortalServer. Then 3 is called before we get a response. "After" means after you SEND the message, not after you RECEIVE a response.
  So this could take some advanced understanding of how Sorcery works, or a lot of fiddling and pattern matching on msg[:command]

  """
  @type hook :: (Phoenix.LiveView.Socket, map() -> {:ok, Phoenix.LiveView.Socket} | {:error, Phoenix.LiveView.Socket})

  @callback handle_sorcery({:sorcery, map()}, Phoenix.LiveView.Socket, list(hook())) :: {:noreply, Phoenix.LiveView.Socket}
  @callback handle_sorcery({:sorcery, map()}, Phoenix.LiveView.Socket) :: {:noreply, Phoenix.LiveView.Socket}


  @doc ~s"""
  Creates a portal between the LiveView and the PortalServer, using the given arguments.

  Takes the socket, returns it unchanged.

  ## Examples
      iex> body = %{portal_server: Postgres, portal_name: :my_portal, query_module: MyQuery, query_args: %{player_id: 1}}
      iex> socket = spawn_portal(socket, body)
  """
  @type socket_type :: %{optional(any) => any, :__struct__ => Phoenix.LiveView.Socket, :assigns => map()} #%{__struct__: Phoenix.LiveView.Socket, assigns: map(), optional(any) => any}

  @callback spawn_portal(socket :: socket_type, body :: %{
    portal_server: module(),
    portal_name: atom(),
    query_module: module(),
    query_args: map(),
  }, opts :: []) :: socket_type


  @doc ~s"""
  Puts a :sorcery key in socket.assigns, with a bunch of stuff used behind the scenes by Sorcery.

  This is mandatory, before you can spawn any portals

  You must pass in the sorcery_module. If you used the generator, it'll just be Src.

  ## Examples
      iex> body = %{sorcery_module: Src}
      iex> socket = initialize_sorcery(socket, body)
  """
  @callback initialize_sorcery(socket :: socket_type, body :: %{
    optional(:sorcery_module) => module(),
    optional(:args) => map(),
    optional(:store_adapter) => module()
  }) :: socket_type


  @doc ~s"""
  Get a list of entities at the given portal/lvar
  You probably want to use this inside heex
  ```elixir
  <% players = portal_view(@sorcery, :my_portal, "?all_players") %>
  ```
  """
  @callback portal_view(sorcery_config :: map(), portal_name :: atom(), lvar :: binary()) :: list()


  @doc ~s"""
  Get a list of entities at the given lvar. 

  If this lvar only exists in ONE portal, you can leave out the portal_name, just know that it might be imperceptibly slower since the function needs to iterate over all portals until it finds one with that lvar..

  ```elixir
  <% players = portal_view(@sorcery, :my_portal, "?all_players") %>
  ```
  """

  #@doc """
  #When a PortalServer needs to send a message to this LiveView, it goes through this.

  #You can still use your own `handle_info` functions with different function heads. But `handle_info({:sorcery, _}, socket)` is reserved.
  #"""


  # }}}

  defmacro __using__(_) do
    quote do
      @behaviour Sorcery.LiveHelpers

      # {{{ spawn_portal/3
      def spawn_portal(socket, body), do: spawn_portal(socket, body, [])

      @impl true
      def spawn_portal(socket, %{portal_server: parent, portal_name: name, query_module: mod, query_args: args} = body, opts) do
        passes_checks = cond do
          !function_exported?(__MODULE__, :connected?, 1) -> true
          apply(__MODULE__, :connected?, [socket]) -> true
          true -> false
        end
        args = Enum.into(opts, args)
        if passes_checks do
          msg = %{
            command: :create_portal,
            portal_name: name,
            #query_module: Module.concat(socket.assigns.sorcery.config_module, mod),
            query_module: mod,
            child_pid: self(),
            args: args,
          }
          send(Module.concat([socket.assigns.sorcery.config_module, "PortalServers", parent]), {:sorcery, msg})
        end

        sorcery = socket.assigns[:sorcery]
                  |> Map.update(:pending_portals, [name], &([name | &1]))
                  |> Map.put(:has_loaded?, false)

        assign(socket, :sorcery, sorcery)
      end
      @impl true
      def spawn_portal(_, body, _) do
        expected = [:portal_server, :portal_name, :query_module, :query_args]
        expected_str = Enum.reduce(expected, "", fn k, acc -> ":#{k} " <> acc end)

        actual = Map.keys(body)
        actual_str = Enum.reduce(actual, "", fn k, acc -> ":#{k} " <> acc end)

        missing = MapSet.difference(MapSet.new(expected), MapSet.new(actual)) |> MapSet.to_list()
        missing_str = Enum.reduce(missing, "", fn k, acc -> ":#{k} " <> acc end)

        raise ~s"""
        You called spawn_portal/2 in #{__MODULE__}, which is a good start, but you're missing some data.

        The second argument of spawn_portal requires the following keys
        #{expected_str}

        But you passed in
        #{actual_str}

        Which is missing
        #{missing_str}

        """

      end
      # }}}


      # {{{ initialize_sorcery/2
      @impl true
      def initialize_sorcery(socket, body \\ %{}) do
        mod = Map.get(body, :sorcery_module, Src)
        assigns = Sorcery.PortalServer.add_portal_server_state(socket.assigns, %{
          config_module: mod,
          store_adapter: Map.get(body, :store_adapter, Sorcery.StoreAdapter.InMemory),
          args: Map.get(body, :args, %{})
        })
        socket = assign(socket, :sorcery, assigns.sorcery)

        socket
      end
      # }}}

    def has_loaded?(%{has_loaded?: true}), do: true
    def has_loaded?(_), do: false


    # {{{ handle_sorcery({:sorcery, msg}, socket)
    def handle_sorcery(msg, socket), do: handle_sorcery(msg, socket, [])

    @impl true
    def handle_sorcery({:sorcery, msg}, socket, opts) do
      before_hooks = Keyword.get(opts, :hook_before, [])
      after_hooks = Keyword.get(opts, :hook_after, [])

      # hook_before
      socket = Enum.reduce_while(before_hooks, socket, fn cb, socket ->
        case cb.(socket, msg) do
          {:ok, socket} -> {:cont, socket}
          {:error, socket} -> {:halt, socket}
          _ -> raise "Invalid middleware #{cb}, it must return {:ok, socket}"
        end
      end)

      # run_command
      socket = handle_sorcery(msg, socket)

      # hook_after
      socket = Enum.reduce_while(after_hooks, socket, fn cb, socket ->
        case cb.(socket, msg) do
          {:ok, socket} -> {:cont, socket}
          {:error, socket} -> {:halt, socket}
        end
      end)

      {:noreply, socket}
    end

    def handle_sorcery(%{command: :mutation_failed, args: %{error: error, handle_fail: cb}} = msg, socket, _opts) when is_function(cb) do
      socket = cb.(error, socket)
      inner_state = Sorcery.PortalServer.handle_info(msg, socket.assigns.sorcery)
      assign(socket, :sorcery, inner_state)
    end
    def handle_sorcery(%{command: :mutation_failed, args: %{error: %{reason: reason} }} = msg, socket, _opts) do
      socket = Phoenix.LiveView.put_flash(socket, :error, reason)
      inner_state = Sorcery.PortalServer.handle_info(msg, socket.assigns.sorcery)
      assign(socket, :sorcery, inner_state)
    end
    def handle_sorcery(%{command: :mutation_success, args: %{data: data, handle_success: cb}} = msg, socket, _opts) when is_function(cb) do
      socket = cb.(data, socket)
      inner_state = Sorcery.PortalServer.handle_info(msg, socket.assigns.sorcery)
      assign(socket, :sorcery, inner_state)
    end
    def handle_sorcery(%{command: :portal_merge, portal: new_portal, args: %{handle_success: cb}} = msg, socket, _opts) when is_function(cb) do
      inner_state = Sorcery.PortalServer.handle_info(msg, socket.assigns.sorcery)
      socket = assign(socket, :sorcery, inner_state)
      socket = cb.(new_portal, socket)

      socket
    end
    def handle_sorcery(msg, socket, _opts) do
      inner_state = Sorcery.PortalServer.handle_info(msg, socket.assigns.sorcery)
      assign(socket, :sorcery, inner_state)
    end
    # }}}


    # {{{ portal_view(sorcery, portal_name, lvar)
    @impl true
    def portal_view(sorcery, portal_name, lvar) do
      Sorcery.PortalServer.Portal.get_in(sorcery, portal_name, lvar)
    end
    # }}}

    def portal_one(sorcery, portal_name, lvar) do
      case Sorcery.PortalServer.Portal.get_in(sorcery, portal_name, lvar) do
        [hd | _] -> hd
        _ -> nil
      end
    end
     

      # {{{ optimistic_mutation(mutation, socket)
      def optimistic_mutation(mutation, socket, opts \\ []) do
        case Sorcery.Mutation.send_mutation(mutation, socket.assigns.sorcery, opts) do

          {:ok, new_sorcery} -> 
            assign(socket, :sorcery, new_sorcery)

          {:error, {:skip, kind, reason}} when is_binary(reason) ->
            Phoenix.LiveView.put_flash(socket, kind, reason)

        end
      end
      # }}}

      
    end
  end



end
