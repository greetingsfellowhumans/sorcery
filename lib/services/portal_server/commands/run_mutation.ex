defmodule Sorcery.PortalServer.Commands.RunMutation do
  @moduledoc """
  First a user creates a chain of mutations.
  Then it gets sent to the parent portal_server
  > You are here < RunMutation is called, and the mutations are converted into a Diff
  After the parent applies the diff to it's own store it must:
    Check the reverse queries to see which children care about it
    send the diff to those children via RunDiff

  A child receives a message from a parent and calls RunDiff
  It updates the store, and portals.
  """
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ
  alias Sorcery.ReturnedEntities, as: RE
  import Sorcery.Helpers.Maps


  def entry(%{args: _args} = msg, state) do
    "@TODO"
    state
  end


end

