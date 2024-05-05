defmodule Sorcery.Mutation.ParentMutation do
  @moduledoc false
  import Sorcery.Helpers.Maps
  #alias Sorcery.PortalServer.Portal

  defstruct [
    :old_data,
    version: 1,
    inserts: %{},
    updates: %{},
    deletes: %{},
  ]

  def init(pre_mutation) do
    body = 
      pre_mutation
      |> Map.from_struct()
      |> Map.put(:inserts, find_inserts(pre_mutation))
      |> Map.put(:updates, find_updates(pre_mutation))
      |> Map.put(:deletes, find_deletes(pre_mutation))
    struct(__MODULE__, body)
  end

  # {{{ find_updates
  defp find_updates(pre_mutation) do
    Enum.reduce(pre_mutation.new_data, %{}, fn {tk, new_table}, acc ->
      Enum.reduce(new_table, acc, fn 
        {"?" <> _, _}, acc -> acc
        {id, new_entity}, acc ->
          old_entity = get_in_p(pre_mutation, [:old_data, tk, id])
          if old_entity == new_entity do
            acc
          else
            put_in_p(acc, [tk, id], new_entity)
          end
        end)
    end)
  end
  # }}}

  # {{{ find_inserts
  defp find_inserts(pre_mutation) do
    Enum.reduce(pre_mutation.new_data, %{}, fn {tk, new_table}, acc ->
      old_table = get_in_p(pre_mutation, [:old_data, tk])
      old_ids = get_id_set(old_table)
      new_ids = get_id_set(new_table)
      inserted_ids = MapSet.difference(new_ids, old_ids) |> MapSet.to_list()
      inserted_table = Map.take(new_table, inserted_ids)
      if Enum.empty?(inserted_table) do
        acc
      else
        Map.put(acc, tk, inserted_table)
      end
    end)
  end
  # }}}

  # {{{ find_deletes
  defp find_deletes(pre_mutation) do
    pre_mutation.deletes
    #Enum.reduce(pre_mutation.new_data, %{}, fn {tk, new_table}, acc ->
    #  old_table = get_in_p(pre_mutation, [:old_data, tk])
    #  old_ids = get_id_set(old_table)
    #  new_ids = get_id_set(new_table)
    #  deleted_ids = MapSet.difference(old_ids, new_ids) |> MapSet.to_list()
    #  if Enum.empty?(deleted_ids) do
    #    acc
    #  else
    #    Map.put(acc, tk, deleted_ids)
    #  end
    #end)
  end
  # }}}

  # {{{ get_id_set
  defp get_id_set(table) do
    table
    |> Map.keys()
    |> MapSet.new()
  end
  # }}}

end
