defmodule Sorcery.Src.Access do
  alias Sorcery.Src.Utils
  @moduledoc """
  Functions to help implement Access for the Src struct.
  """


  def fetch(%{changes_db: ch, original_db: og, deletes: del}, k) do
    db = Map.merge(og, ch) |> Utils.remove_dels_from_db(del)
    Map.fetch(db, k)
  end


  def get_and_update(%{changes_db: ch} = src, k, cb) do
    case fetch(src, k) do
      {:ok, value} ->
        case cb.(value) do
          {current_value, new_value} ->
            new_changes = Map.put(ch, k, new_value)
            new_data    = Map.put(src, :changes_db, new_changes)
            {current_value, new_data}
          :pop ->
            new_data = Map.delete(src, k)
            {value, new_data}
        end
      :error ->
        case cb.(nil) do
          {current_value, new_value} ->
            new_changes = Map.put(ch, k, new_value)
            new_data    = Map.put(src, :changes_db, new_changes)
            {current_value, new_data}
          :pop ->
            new_data = Map.delete(src, k)
            {nil, new_data}
        end
    end
  end
  def get_and_update(src, k, cb) do
    value = Map.get(src, k)
    case cb.(value) do
      {current_value, new_value} -> 
        new_data = Map.put(src, k, new_value)
        {current_value, new_data}

      :pop ->
        new_data = Map.delete(src, k)
        {value, new_data}
    end
  end


  def pop(src, k) do
    value = Map.get(src, k)
    data = Map.delete(src, k)
    {value, data}
  end

  # Return a changes_db, excluding any keys that are in the original_db
  # We need for when get_and_update starts off with a fetch, which merges them.
  def diff(%{original_db: og, changes_db: ch}) do
    Enum.reduce(ch, %{}, fn {tk, table}, db_acc ->
      og_table = Map.get(og, tk)
      if og_table do
        new_table = Enum.reduce(table, %{}, fn {id, entity}, table_acc ->
          og_entity = Map.get(og_table, id)
          if og_entity do
            new_entity = Enum.reduce(entity, %{}, fn {k, v}, entity_acc ->
              og_v = Map.get(og_entity, k)
              if og_v do
                if og_v == v do
                  entity_acc
                else
                  Map.put(entity_acc, k, v)
                end
              else
                Map.put(entity_acc, k, v)
              end
            end)
            if Enum.empty?(new_entity) do
              table_acc
            else
              Map.put(table_acc, id, new_entity)
            end
          else
            Map.put(table_acc, id, entity)
          end
        end)
        if Enum.empty?(new_table) do
          db_acc
        else
          Map.put(db_acc, tk, new_table)
        end
      else
        Map.put(db_acc, tk, table)
      end
    end)
  end

end
