defmodule Sorcery.PortalServer.Commands.MutationSuccess do
  @moduledoc false

  def entry(_msg, %Sorcery.PortalServer.InnerState{} = inner_state) do
    inner_state
  end


end


