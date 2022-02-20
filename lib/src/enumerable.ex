defmodule Sorcery.Src.Enumerable do
  alias Sorcery.Src
  @moduledoc """
  Functions to help implement Enumerable for the Src struct.
  """

  defimpl Enumerable, for: Src do

    def count(src) do
      {:ok, MapSet.size(Src.Utils.entities_set(src))}
    end

    def member?(src, element) do
      {:ok, MapSet.member?(Src.Utils.entities_set(src), element)}
    end

    # Start by getting a list of current values like {tk, id, %{...}}
    def reduce(src, acc, fun) when not is_list(src) do
      Src.Utils.entities_set(src)
      |> Enum.map(fn {tk, id} -> 
        current = get_in(src, [tk, id])
        {tk, id, current}
      end)
      |> __MODULE__.reduce(acc, fun)
    end
    def reduce(_list, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(list, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(list, &1, fun)}
    def reduce([], {:cont, acc}, _fun), do: {:done, acc}
    def reduce([head | tail], {:cont, acc}, fun), do: reduce(tail, fun.(head, acc), fun)

    def slice(src) do
      set = Src.Utils.entities_set(src)
      li = MapSet.to_list(set)
      {:ok, MapSet.size(set), fn start, len -> 
        Enum.slice(li, start, len)
      end}
    end

  end

end
