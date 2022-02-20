defmodule Sorcery.Src do
  use Norm
  #alias Specs.Primative, as: T
  alias Sorcery.Msg
  alias Sorcery.Src
  alias Sorcery.Src.Utils


  @moduledoc """
  This is the quintessential single source of truth in the app.

  # The db format
  The first thing to understand is the concept of a 'db'.
  Every DB is in the following format:
  db = %{
    Users => %{
      1 => %{id: 1, name: "Aaron"},
      3 => %{id: 3, name: "Not Aaron"},
    },
    Comments => %{
      78 => %{id: 78, user_id: 1, body: "Hello"}
    }
  }

  Note the the top level keys are module names related to an ecto schema.
  There are a few reasons for this. The schema module is expected to implement the SrcSchema behaviour.


  For example

  src = Src.new(%{
    User => %{id: 1, name: "..."},
    User => %{id: 2, name: "..."},
  })

  get_in(src, [User, 1]) => %User{id: 1, name: "..."}
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

    # List of functions that take a src and return a source.
    interceptors: [],

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
  def all_ids(src, tk), do: Map.keys(src[tk])


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

