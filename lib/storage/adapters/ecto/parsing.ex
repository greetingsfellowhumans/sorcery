defmodule Sorcery.Storage.Adapters.Ecto.Parsing do
  use Norm
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Utils.Maps

  @moduledoc false

  # This is probably the entrypoint you are looking for
  @contract get_ordered_inserts(T.src()) :: coll_of({T.tk(), T.id(), T.entity()})
  def get_ordered_inserts(src) do
    src = mv_changes_inserts(src)
    li = list_inserts_deps(src)
    ids = inserts_id_order(li)

    Enum.map(ids, fn id -> 
      {tk, _, _} = Enum.find(li, fn {_, sorcery_id, _} -> sorcery_id == id end)
      entity = Map.get(src.inserts[tk], id)
      {tk, id, entity}
    end)
    
  end
  

  # Moves entities from changes_db into :inserts.
  @contract mv_changes_inserts(spec(is_struct(Sorcery.Src))) :: spec(is_struct(Sorcery.Src))
  def mv_changes_inserts(src) do
    Enum.reduce(src.changes_db, src, fn {tk, table}, src_acc ->
      Enum.reduce(table, src_acc, fn 
        {"$sorcery:" <> _ = id, entity}, src_acc ->
          src_acc
          |> Maps.put_in_p([:inserts, tk, id], entity)
          |> Maps.delete_in([:changes_db, tk, id])
        {_id, _entity}, src_acc -> src_acc
      end)
    end)
  end

  
  @contract list_inserts_deps(spec(is_struct(Sorcery.Src))) :: coll_of({spec(is_atom), spec(is_binary), coll_of(spec(is_binary()))})
  def list_inserts_deps(src) do
    Enum.reduce(src.inserts, [], fn {tk, table}, src_acc ->
      Enum.reduce(table, src_acc, fn {id, entity}, src_acc ->
        deps = Enum.reduce(entity, [], fn 
          {_, "$sorcery:" <> _ = dep}, acc -> [dep | acc]
          _, acc -> acc
        end)
        [{tk, id, deps} | src_acc]
      end)
    end)
  end

  
  @contract inserts_id_order(coll_of({spec(is_atom), spec(is_binary), coll_of(spec(is_binary()))})) :: coll_of(spec(is_binary()))
  def inserts_id_order(curr) do
    inserts_id_order(curr, [], [])
  end
  def inserts_id_order([], [], acc), do: Enum.reverse(acc)
  def inserts_id_order([], pending, acc), do: inserts_id_order(pending, [], acc)
  def inserts_id_order([hd | tl], pending, acc) do
    case hd do
      {_tk, id, []} -> inserts_id_order(tl, pending, [id | acc])
      {tk, id, deps} ->
        new_deps = Enum.filter(deps, fn k -> k not in acc end)
        inserts_id_order(tl, [{tk, id, new_deps} | pending], acc)
    end
  end

  
end
