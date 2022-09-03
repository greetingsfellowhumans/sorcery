defmodule Sorcery.Storage.EctoAdapter do
  @moduledoc false

  use Norm
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT
  alias Sorcery.Storage.Adapters.Ecto.Parsing
  #alias Sorcery.Utils.Maps



  @contract persist_src(T.src(), AdapterT.client_state()) :: T.db()
  @doc """
  Takes the src, and makes it permanent with an ecto transaction
  """
  def persist_src(src, client) do
    %{repo: repo} = client
    multi = multi_mod(client).new()


    multi
    |> build_multi_inserts(src, client)
    |> build_multi_updates(src, client)
    |> build_multi_deletes(src, client)
    |> repo.transaction()
    |> case do
      {:ok, ops} ->
        Enum.reduce(ops, %{}, fn {name, entity}, acc ->
            tk_str = case String.split(name, ":") do
              [tk_str, _id_str] -> tk_str
              ["$sorcery", tk_str, _id_str] -> tk_str
            end
            tk = String.to_existing_atom(tk_str)
            acc
            |> Map.put_new(tk, %{})
            |> put_in([tk, entity.id], Map.from_struct(entity))
        end)

      error -> error

    end
  end


  defp build_multi_inserts(multi, src, client) do
    Parsing.get_ordered_inserts(src)
    |> Enum.reduce(multi, fn {tk, id, entity}, multi ->
      table = client.tables[tk]
      if is_nil(table), do: raise "Invalid table #{tk}. Check your App.Sorcery module, or the Src your are pushing."
      schema = client.tables[tk].schema
      #multi_mod(client).insert(multi, id <> ":#{tk}", fn ops ->
      multi_mod(client).insert(multi, id, fn ops ->
        new_entity = resolve_placeholder_ids(entity, ops)
        schema.sorcery_insert(struct(schema), new_entity)
      end)
    end)
  end


  defp build_multi_updates(multi, src, client) do
    Enum.reduce(src.changes_db, multi, fn {tk, table}, multi ->
      Enum.reduce(table, multi, fn 
        {id_str, _}, multi when is_binary(id_str) -> multi

        {id, entity}, multi ->
        # Every id here should be an integer
        schema = client.tables[tk].schema
        multi_mod(client).update(multi, "#{tk}:#{id}", fn prev_ops ->
          original_entity = get_original_entity(client.db, tk, id, schema)
          new_entity = resolve_placeholder_ids(entity, prev_ops)
          cs = schema.sorcery_update(original_entity, new_entity)
          cs
        end)
      end)
    end)
  end


  defp get_original_entity(db, tk, id, schema) do
    table = Map.get(db, tk, %{})
    entity = Map.get(table, id, %{})
    defaults = struct(schema)
    Map.merge(defaults, entity)
  end


  defp build_multi_deletes(multi, src, client) do
    Enum.reduce(src.deletes, multi, fn {tk, id}, multi ->
      schema = client.tables[tk].schema
      cs = struct(schema, %{id: id})
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


  
  # Returns an %Ecto.Multi{} struct
  defp multi_mod(%{ecto: ecto}) do
    Module.concat([ecto, "Multi"])
  end


end
