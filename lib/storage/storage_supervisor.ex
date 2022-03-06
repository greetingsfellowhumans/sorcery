defmodule Sorcery.StorageSupervisor do
  @moduledoc """
  Supervisor that manages the storage, regardless of what that is.
  """
  use Supervisor


  def start_link(store, opts) do
    Supervisor.start_link(__MODULE__, {store, opts})
  end


  def init(adapter) do
    children = [adapter]
    Supervisor.init(children, [strategy: :one_for_one])
  end


end
