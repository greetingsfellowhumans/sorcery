defmodule Sorcery.StoreAdapter.Ecto.Thread do
  @moduledoc ~s"""
  Since we are translating SrcQL into SQL, there are some oddities.
  One is how we handle completely unrelated lvars that are not joined.
  So in this adapter we call cluster a group of where clauses and joins together, and call it a thread.
  We must call Repo.all(thread) seperately with each thread.
  """
  import Sorcery.Helpers.Maps

  defstruct [
    order: [],
    where_groups: %{},
  ]

  def new(lvar, group) do
    groups = %{}
            |> Map.put(lvar, group)

    struct(__MODULE__, %{order: [lvar], where_groups: groups})
  end

  def put(thread, lvar, group) do
    thread
    |> put_in_p([:where_groups, lvar], group)
    |> Map.update!(:order, fn li -> li ++ [lvar] end)
  end

  defp is_new_thread?(group), do: !Enum.any?(group, &(&1.right_type == :lvar))

  defp get_associations(group) do
    Enum.reduce(group, [], fn 
      %{other_lvar: nil}, acc -> acc
      %{other_lvar: lvar}, acc -> [lvar | acc]
    end)
  end

  def all([]), do: raise "You are trying to call a query with no clauses"
  def all(wheres) do
    gw = Enum.group_by(wheres, &(&1.lvar))
    lvar_order = Enum.map(wheres, &(&1.lvar)) |> Enum.uniq()
    [hd_lvar | tl_lvar] = lvar_order
    first_thread = new(hd_lvar, gw[hd_lvar])
    all(gw, tl_lvar, [first_thread])
  end

  def all(_grouped_wheres, [], threads), do: threads
  def all(grouped_wheres, [hd_lvar | tl_lvar], threads) do
    group = grouped_wheres[hd_lvar]
    if is_new_thread?(group) do
      thread = new(hd_lvar, group)
      all(grouped_wheres, tl_lvar, [thread | threads])
    else
      associations = get_associations(group)
      threads = Enum.map(threads, fn thread ->
        if Enum.any?(associations, fn asc -> asc in thread.order end) do
          put(thread, hd_lvar, group)
        else
          thread
        end
      end)
      all(grouped_wheres, tl_lvar, threads)
    end
  end



end
