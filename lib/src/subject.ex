defmodule Sorcery.Src.Subject do
  @moduledoc """
  When keeping track of data, it is important to decide *what* data you care about.
  Sometimes you need to query it directly from the database.
  Other times you receive a dump from another node, and need to filter for  only what you want.

  A 'Subject' is a struct that defines the data you want. Similar to a pubsub topic, but allows something more complex than a simple string with arguments.

  Every subject has two functions, :filter and :query.

  The filter takes a db and returns a subset of it in the same format.
  The query is called with the Src where you can put arguments and see previously queried data.
  Every query must return {:ok, db} to be considiered valid.
  """

  use Norm
  alias Sorcery.{Msg, Src}
  alias Src.Subject
  alias Sorcery.Specs.Primative, as: T

  defstruct [
    filter: &__MODULE__.default_filter/2,
    query: &__MODULE__.default_query/1
  ]


  def default_filter(_src, _db), do: %{}
  def default_query(_src), do: %{}


  @contract filter_db(T.db(), T.src()) :: T.db()
  @doc """
  Given a DB and Src, return only the subset of the DB we care about.
  """
  def filter_db(db, src) do
    Enum.map(src.subjects, fn %{filter: filter} -> filter.(src.args, db) end)
    |> Enum.reduce(%{}, fn db, acc -> Map.merge(acc, db) end)
  end


  @contract query_all(T.src) :: T.msg()
  @contract query_all(T.src, T.msg(), coll_of(T.subject())) :: T.msg()
  @doc """
  Given a Src, pull all the data from Subject Queries. Does not apply Subject filters.
  Returns either %Msg{status: :ok, body: db} or %Msg{status: :error, error: error}
  """
  def query_all(src), do: query_all(src, %Msg{}, src.subjects)
  def query_all(_src, %Msg{} = msg, []), do: msg
  def query_all(src, %Msg{status: :ok, body: body} = msg, [%__MODULE__{query: query} | tl]) do

    new_msg = case query.(src) do
      {:ok, data} -> 
        new_data = Map.merge(body, data)
        Map.put(msg, :body, new_data)
      error -> %Msg{body: error, status: :error, flash: "Bad Query"}
    end
    query_all(src, new_msg, tl)

  end
  def query_all(_src, %Msg{status: :error} = msg, _), do: msg


  @contract fulfill_all(T.src()) :: T.msg()
  @doc """
  Take the Src, call All the queries, filter by all the filters, and return a Msg.
  """
  def fulfill_all(src) do
    case query_all(src) do
      %Msg{status: :ok, body: body} = msg -> 
        Map.put(msg, :body, filter_db(body, src))
      msg -> msg
    end
  end


  def is_relevant?(%Subject{filter: filter}, %Src{args: args, changes_db: db}) do
    !Enum.empty?(filter.(args, db))
  end

end
