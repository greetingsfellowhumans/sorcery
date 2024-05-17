defmodule Sorcery.SorceryDb do
  @moduledoc false


  # {{{ SorceryDb

  # {{{ build_mnesia_table
  def build_mnesia_table(tk, schema_mod) do
    attrs = schema_mod.fields()
            |> Map.keys()
            |> Enum.sort()
    attrs = [:id | attrs] |> Enum.uniq()
    :mnesia.create_table(tk, [attributes: attrs])
  end
  # }}}


  # {{{ parse_schema_module
  def parse_schema_module(name, root_mod) do
    [name | _] = String.split(name, ".")
    tk = String.to_atom(name)
    mod_suffix = Macro.camelize(name)

    full_mod = Module.concat([root_mod, mod_suffix])
    {tk, full_mod}
  end
  # }}}

  # }}}


  # {{{ use macro

  defmacro __using__(opts) do
    quote do
      use GenServer

      # {{{ Setup
      def start_link(_state) do
        GenServer.start_link(__MODULE__, %{})
      end

      @impl true
      def init(_) do
        watchers_table = :ets.new(:sorcery_watchers, [:named_table, :duplicate_bag, :public, read_concurrency: true, write_concurrency: true])
        :mnesia.create_schema([node()])
        :mnesia.start()

        schema_files =
          unquote(opts)
          |> Keyword.get(:opts)
          |> Keyword.get(:paths)
          |> Map.get(:schemas)
          |> File.ls!()

        for filename <- schema_files do
          {tk, schema_mod} = Sorcery.SorceryDb.parse_schema_module(filename, __MODULE__.Schemas)
          Sorcery.SorceryDb.build_mnesia_table(tk, schema_mod)
        end

        {:ok, %{}}
      end
      # }}}


      # {{{ Client
      def cache_pid_entity(pid, portal, timestamp, tk, entity), do: :ets.insert(:sorcery_watchers, {pid, portal, timestamp, tk, entity})
      # @TODO unchache_pid_entity

      # }}}


      # {{{ Server
      # }}}
      
    end
  end

  # }}}

end
