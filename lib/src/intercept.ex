defmodule Sorcery.Src.Intercept do
  
  def src_intercept(%{interceptors: []} = src), do: src
  def src_intercept(%{interceptors: [hd | _]} = src) do
    new_src = hd.(src)
              |> time_forward()
              |> src_intercept()
  end
  
  
  def time_forward(src, steps) do
    Enum.reduce(0..(steps - 1), src, fn _, acc ->
      time_forward(acc)
    end)
  end
  defp time_forward(%{interceptors: []} = src), do: src
  defp time_forward(%{interceptors: [hd | tl], complete_interceptors: past} = src) do
    src
    |> Map.put(:interceptors, tl)
    |> Map.put(:complete_interceptors, [hd | past])
  end

  
  def time_backward(src, steps) do
    interim_src = Enum.reduce(0..(steps - 1), src, fn _, acc ->
      time_backward(acc)
    end)
    past = interim_src.complete_interceptors |> Enum.reverse()
    future = interim_src.interceptors

    Sorcery.Src.new(src.original_db, src.args)
    |> Map.put(:interceptors, past)
    |> src_intercept()
    |> Map.put(:interceptors, future)
  end
  defp time_backward(%{complete_interceptors: []} = src), do: src
  defp time_backward(%{interceptors: future, complete_interceptors: [hd | tl]} = src) do
    src
    |> Map.put(:interceptors, [hd | future])
    |> Map.put(:complete_interceptors, tl)
  end


end
