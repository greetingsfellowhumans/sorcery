defmodule Sorcery.Storage.PresenceMock do
  use Agent


  def start_link(default \\ %{}, opts \\ [name: __MODULE__]) do
    Agent.start_link(fn -> default end, opts)
  end


  def track(_pid, "portals:" <> tk_str, portal_ref, portal) do
    tk = String.to_existing_atom(tk_str)
    presence = %{metas: [portal]}
    Agent.update(__MODULE__, fn topics ->
      Map.update(topics, tk, %{portal_ref => presence}, fn topic ->
        Map.put(topic, portal_ref, presence)
      end)
    end)
    {:ok, "ok"}
  end


  def list("portals:" <> tk_str) do
    tk = String.to_existing_atom(tk_str)
    Agent.get(__MODULE__, fn topics -> topics[tk] end)
  end


  def get_by_key("portals:" <> tk_str, ref) do
    tk = String.to_existing_atom(tk_str)
    Agent.get(__MODULE__, fn topics -> 
      topics[tk] 
      |> Map.get(ref)
    end)
  end


end
