defmodule Sorcery.PortalPresence do
  defstruct [:pid, :phx_ref, :portal]
end

defmodule Sorcery.Portal do
  defstruct [
    :id, :pid, :tk, :indices, :guards, :key, :resolved_guards
  ]


  def tk_ref(tk) do
    ref = "#{inspect make_ref()}"
          |> String.split("<")
          |> List.last()
          |> String.split(">")
          |> List.first()
    "#{tk}:#{ref}"
  end


  def new(portal) when is_struct(portal), do: __MODULE__.new(Map.from_struct(portal))
  def new(%{tk: tk, guards: guards} = attr) do
    attr = attr
    |> Map.put_new(:id, tk_ref(tk))
    |> Map.put_new(:key, tk)
    |> Map.put_new(:indices, %{id: MapSet.new()})
    |> Map.put_new(:resolved_guards, guards)

    struct(__MODULE__, attr)
  end


end
