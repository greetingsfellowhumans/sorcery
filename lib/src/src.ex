defmodule Sorcery.Src do
  use Norm
  #alias Specs.Primative, as: T
  alias Sorcery.Msg
  alias Sorcery.Src
  #1alias Sorcery.Src.Utils


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

  get_in(src, [:user, 1]) => %{id: 1, name: "..."}
  get_in(src, [:something, 123]) => %{id: 123, foo: 123421}
  get_in(src, [:something, 123, :foo]) => 123421

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


  @doc """
  Get all ids for a given table
  @TODO This might need more work if you delete an entity and the id is still in original_db.
  """
  def all_ids(%{original_db: og, changes_db: ch, deletes: del}, tk) do
    o = Map.get(og, tk, %{}) |> Map.keys()
    c = Map.get(ch, tk, %{}) |> Map.keys()
    d = Enum.reduce(del, [], fn {t, id}, acc -> if t == tk, do: [id | acc], else: acc end)
    MapSet.new(o ++ c ++ d) |> MapSet.to_list()
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

