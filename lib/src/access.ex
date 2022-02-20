defmodule Sorcery.Src.Access do
  alias Sorcery.Src.Utils
  @moduledoc """
  Functions to help implement Access for the Ctx struct.
  """


  def fetch(%{changes_db: ch, original_db: og}, k) do
    db = Map.merge(og, ch)
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

end
