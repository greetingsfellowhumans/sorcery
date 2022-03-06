defmodule Sorcery.Storage.EctoAdapter do
  use Norm
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT

  def int_id(), do: spec(is_integer())
  def placeholder_id(), do: spec(is_binary() and fn id ->
    "$sorcery:" <> str_int = id
    String.to_integer(str_int)
  end)
  def multi_name(), do: spec(fn name ->
    case name do
      "$sorcery:" <> _ -> true
      "tk:" <> _ -> true
      _ -> false
    end
  end)


  @contract persist_src(T.src(), AdapterT.client_state()) :: T.db()
  @doc """
  Takes the src, and makes it permanent with an ecto transaction
  """
  def persist_src(src, client) do
    %{repo: repo} = client
    multi = multi_mod(client).new()
    src = separate_inserts(src)

    multi
    |> build_multi_inserts(src, client)
    |> build_multi_updates(src, client)
    |> build_multi_deletes(src, client)
    |> repo.transaction()
    |> case do
      {:ok, ops} ->
        Enum.reduce(ops, %{}, fn {name, entity}, acc ->
          [tk_str, _id_str] = String.split(name, ":")
          tk = String.to_existing_atom(tk_str)
          acc
          |> Map.put_new(tk, %{})
          |> put_in([tk, entity.id], Map.from_struct(entity))
        end)

      error -> error

    end
  end



  defp build_multi_inserts(multi, src, client) do
    Enum.reduce(src.inserts, multi, fn {tk, table}, multi ->
      Enum.reduce(table, multi, fn {id, entity}, multi ->
        # Every id here should be in the format of "$sorcery:int"
        schema = client.tables[tk].schema
        cs = schema.sorcery_insert(struct(schema), entity)
        multi_mod(client).insert(multi, id, cs)
      end)
    end)
  end


  defp build_multi_updates(multi, src, client) do
    Enum.reduce(src.changes_db, multi, fn {tk, table}, multi ->
      Enum.reduce(table, multi, fn {id, entity}, multi ->
        # Every id here should be an integer
        schema = client.tables[tk].schema
        multi_mod(client).update(multi, "#{tk}:#{id}", fn prev_ops ->
          entity = resolve_placeholder_ids(entity, prev_ops)
          cs = schema.sorcery_update(struct(schema, %{id: id}), entity)
          cs
        end)
      end)
    end)
  end


  defp build_multi_deletes(multi, src, client) do
    Enum.reduce(src.deletes, multi, fn {tk, id}, multi ->
      schema = client.tables[tk].schema
      cs = schema.sorcery_update(struct(schema, %{id: id}), %{})
      multi_mod(client).delete(multi, "#{tk}:#{id}", cs)
    end)
  end

  defp resolve_placeholder_ids(entity, ops) do
    Enum.reduce(entity, entity, fn {k, v}, acc ->
      case v do
        "$sorcery:" <> _ -> 
          new_v = Map.get(ops, v).id
          Map.put(acc, k, new_v)
        _ -> acc
      end
    end)
  end


  # We must be careful to handle the placeholders first.
  # They can go under :inserts
  # And they can be removed from :changes_db
  defp separate_inserts(src) do
    empty_src =
      src
      |> Map.from_struct()
      |> Map.put(:inserts, %{})
      |> Map.put(:changes_db, %{})

    Enum.reduce(src.changes_db, empty_src, fn {tk, table}, acc ->
      {i, u} = Enum.reduce(table, {%{}, %{}}, fn {id, entity}, {i, u} ->
        case id do
          "$sorcery:" <> _ -> {Map.put(i, id, entity), u}
          _ -> {i, Map.put(u, id, entity)}
        end
      end)

      inserts = Map.merge(acc.inserts, i)
      updates = Map.merge(acc.changes_db, u)

      acc
      |> put_in([:inserts, tk], inserts)
      |> put_in([:changes_db, tk], updates)

    end)

  end

  # Helpers
  defp multi_mod(%{ecto: ecto}) do
    Module.concat([ecto, "Multi"])
  end

end
