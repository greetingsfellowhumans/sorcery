defmodule Sorcery.Utils.Maps do


  @doc """
  Like `mkdir -p`, but for elixir maps.
  Safely does put_in, assuming nothing but maps all the way down.
  """
  def put_in_p(m, [hd], value) do
    Map.put(m, hd, value)
  end
  def put_in_p(m, [hd | tl], value) do
    submap = Map.get(m, hd, %{})
             |> put_in_p(tl, value)
    Map.put(m, hd, submap)
  end


  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end

end
