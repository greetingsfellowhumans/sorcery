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


end
