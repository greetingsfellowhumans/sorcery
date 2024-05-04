defmodule Sorcery.Mutation.Diff do
  @moduledoc false
  defstruct [
    tks_affected: MapSet.new([]),
    rows: [],
  ]
  
  def new(rows) do
    tks = Enum.map(rows, &(&1.tk)) |> Enum.uniq()
    struct(__MODULE__, %{tks_affected: tks, rows: rows})
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

  def new(%{tk: tk, old_entity: entity, changes: changes}) do
    new(%{tk: tk, old_entity: entity, new_entity: Map.merge(entity, changes)})
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

end
