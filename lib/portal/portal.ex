defmodule Sorcery.PortalPresence do
  defstruct [:pid, :phx_ref, :portal]
end

defmodule Sorcery.Portal do
  use Norm
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT
  alias Sorcery.Specs.Portals, as: PT

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

  def format_indices(portal) do 
    li = case Map.get(portal, :indices) do
      li when is_list(li) -> [:id | li]
      m when is_map(m) -> [:id | Map.keys(m)]
      _ -> [:id]
    end
    Enum.reduce(li, %{}, fn k, acc ->
      Map.put(acc, k, MapSet.new())
    end)
  end


  @contract all_portals(AdapterT.client_state()) :: coll_of(PT.portal())
  def all_portals(state) do
    tks = Map.keys(state.db)
    Enum.flat_map(tks, fn tk ->
      state.presence.list("portals:#{tk}")
      |> Enum.map(fn {_ref, %{metas: [portal]}} -> portal end)
    end)
  end


  def new(portal) when is_struct(portal), do: __MODULE__.new(Map.from_struct(portal))
  def new(%{tk: tk, guards: guards} = attr) do
    attr = attr
    |> Map.put_new(:id, tk_ref(tk))
    |> Map.put_new(:key, tk)
    |> Map.put(:indices, format_indices(attr))
    |> Map.put_new(:resolved_guards, guards)

    struct(__MODULE__, attr)
  end


end
