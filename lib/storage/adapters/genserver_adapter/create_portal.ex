defmodule Sorcery.Storage.GenserverAdapter.CreatePortal do
  @moduledoc """
  Pure functions for pulling a list of entities out of a portal.
  """
  use Norm
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Specs.Portals, as: PT
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT


  def create_portal_map(attrs, pid) do
    attrs
    |> Map.put(:pid, pid)
    |> Sorcery.Portal.new()
    |> Map.from_struct()
  end



end
