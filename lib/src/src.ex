defmodule Sorcery.Src do
  use Norm
  alias Sorcery.Msg
  alias Sorcery.Src


  @moduledoc """
  This is the quintessential single source of truth in the app.

  # The db format
  The first thing to understand is the concept of a 'db'.
  Every DB is in the following format:
  db = %{
    :user => %{
      1 => %{id: 1, name: "Aaron"},
      3 => %{id: 3, name: "Not Aaron"},
    },
    :comment => %{
      78 => %{id: 78, user_id: 1, body: "Hello"}
    }
  }

  Note the the top level keys are atom names related to an ecto schema.

  For example

  src = Src.new(%{
    :user => %{id: 1, name: "..."},
    :user => %{id: 2, name: "..."},
  })

  Src.get_in(src, [:user, 1]) => %{id: 1, name: "..."}
  Src.get_in(src, [:something, 123]) => %{id: 123, foo: 123421}
  Src.get_in(src, [:something, 123, :foo]) => 123421

  """


  defstruct [
    # Misc private data 
    # i.e. user_id, etc.
    args: %{}, 

    # The shared data
    original_db: %{},
    changes_db: %{},

    # When deleting an entity from the backend. For example: [{:person, 1}]
    deletes: [],

    # Instead of integer ids, use strings starting with "$sorcery:"
    inserts: %{},

    # List of functions that take a src and return a source.
    interceptors: [],
    complete_interceptors: [],

    # If something needs to be displayed to the user, put it here
    # Useful for arbitrary error handling
    msg: %Msg{},
  ]


  def new(db \\ %{}, args \\ %{}) do
    %__MODULE__{original_db: db, args: args}
  end

  def get_in(src, path), do: Kernel.get_in(src, path)
  
  def update_in(src, path, cb) do
    ch = Kernel.update_in(src, path, cb) |> Sorcery.Src.Access.diff()
    Map.put(src, :changes_db, ch)
  end
  def put_in(src, path, cb) do
    ch = Kernel.put_in(src, path, cb) |> Sorcery.Src.Access.diff()
    Map.put(src, :changes_db, ch)
  end
  def delete(%{original_db: og, changes_db: ch} = src, tk, id) do
    ch_table = Map.get(ch, tk, %{}) |> Map.delete(id)
    ch = Map.put(ch, tk, ch_table)
    
    src
    |> Map.put(:changes_db, ch)
    |> Map.update(:deletes, [], fn dels -> [{tk, id} | dels] end)
  end

  @doc """
  Returns all original and/or changed ids for a table.
  Note, this will return an id even after applying Src.delete.
  """
  def all_ids(src, tk) do
    Src.get_in(src, [tk]) |> Map.keys()
  end

  @doc """
  Process a list of interceptor functions, each taking, and returning a Src.
  """
  def intercept(src, interceptors) do 
    src
    |> Map.put(:interceptors, interceptors)
    |> Map.put(:complete_interceptors, [])
    |> intercept()
  end
  def intercept(src), do: Sorcery.Src.Intercept.src_intercept(src)

  @doc """
  Send Src past n interceptors without being changed by them.
  """
  def time_forward(src, steps), do: Sorcery.Src.Intercept.time_forward(src, steps)

  @doc """
  Send Src back in time to its state from n interceptors ago.
  """
  def time_backward(src, steps), do: Sorcery.Src.Intercept.time_backward(src, steps)

  ###############################
  ###############################


  @behaviour Access


  @impl true
  def fetch(ctx, path), do: Src.Access.fetch(ctx, path)

  @impl true
  def get_and_update(ctx, path, cb), do: Src.Access.get_and_update(ctx, path, cb)

  @impl true
  def pop(ctx, k), do: Src.Access.pop(ctx, k)
end

