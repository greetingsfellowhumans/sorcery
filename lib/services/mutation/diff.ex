defmodule Sorcery.Mutation.Diff do
  @moduledoc false
  import Sorcery.Helpers.Maps

  defstruct [
    tks_affected: MapSet.new([]),
    rows: [],
  ]

  def new(%Sorcery.Mutation.ChildrenMutation{} = mutation) do
    struct(__MODULE__, %{
      tks_affected: get_tks(mutation),
      rows: get_rows(mutation)
    })
  end

  defp get_tks(mutation) do
    Map.keys(mutation.inserts) ++ Map.keys(mutation.updates) ++ Map.keys(mutation.deletes)
    |> MapSet.new()
  end

  defp get_rows(mutation) do
    acc = []

    # Add Inserts
    acc = Enum.reduce(mutation.inserts, acc, fn {tk, table}, acc ->
      Enum.reduce(table, acc, fn {_id, entity}, acc ->
        row = Sorcery.Mutation.DiffRow.new(%{tk: tk, new_entity: entity})
        [row | acc]
      end)
    end)

    # Add Updates
    acc = Enum.reduce(mutation.updates, acc, fn {tk, table}, acc ->
      Enum.reduce(table, acc, fn {id, entity}, acc ->
        old_entity = get_in_p(mutation, [:old_data, tk, id])
        row = Sorcery.Mutation.DiffRow.new(%{tk: tk, new_entity: entity, old_entity: old_entity})
        [row | acc]
      end)
    end)

    # Add Deletes
    acc = Enum.reduce(mutation.deletes, acc, fn {tk, ids}, acc ->
      Enum.reduce(ids, acc, fn id, acc ->
        old_entity = get_in_p(mutation, [:old_data, tk, id])
        row = Sorcery.Mutation.DiffRow.new(%{tk: tk, old_entity: old_entity, id: id})
        [row | acc]
      end)
    end)

    acc
  end
  

end

defmodule Sorcery.Mutation.DiffRow do
  @moduledoc false
  defstruct [
    tk: nil,
    id: nil,
    old_entity: %{},
    new_entity: %{},
    changes: [],
  ]

  def new(%{tk: tk, old_entity: old, new_entity: new_entity}) do
    changes =
      old
      |> Enum.map(fn {k, old_v} ->
        new_v = new_entity[k]
        {k, old_v, new_v}
      end)
      |> Enum.filter(fn {_, a, b} -> a != b end)

    body = %{
      tk: tk,
      id: old[:id] || new_entity[:id],
      changes: changes,
      old_entity: old,
      new_entity: new_entity
    }
    struct(__MODULE__, body)
  end

  def new(%{tk: tk, new_entity: new_entity}) do
    body = %{
      tk: tk,
      id: new_entity.id,
      changes: Enum.map(new_entity, fn {k, v} -> {k, nil, v} end),
      new_entity: new_entity,
      old_entity: nil
    }
    struct(__MODULE__, body)
  end

  def new(%{tk: tk, old_entity: old_entity, id: id}) do
    old_entity = if is_nil(old_entity), do: %{id: id}, else: old_entity
    body = %{
      tk: tk,
      id: old_entity.id,
      changes: Enum.map(old_entity, fn {k, v} -> {k, v, nil} end),
      new_entity: nil,
      old_entity: old_entity
    }
    struct(__MODULE__, body)
  end

end
