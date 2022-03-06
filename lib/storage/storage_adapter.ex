defmodule Sorcery.StorageAdapter do
  @moduledoc """
  Implement this behaviour to create your StorageAdapter.

  By default, there are already a Memento and GenServer Implementations.

  """

  def init(opts) do
    # Create schema
    # stuff
  end

  def create_portal(portal_spec) do
  end

  def view_portal(portal_ref) do
  end

  def fill_data(data) do
  end

  def update_data(data) do
  end

end
