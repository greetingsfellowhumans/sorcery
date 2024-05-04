defmodule Sorcery.PortalServer.Commands.RunDiff do
  @moduledoc """
  First a user creates a chain of mutations.
  Then it gets sent to the parent portal_server
  RunMutation is called, and the mutations are converted into a Diff
  After the parent applies the diff to it's own store it must:
    Check the reverse queries to see which children care about it
    send the diff to those children via RunDiff

  > You are here < A child receives a message from a parent and calls RunDiff
  It updates the store, and portals.
  """
#  alias Sorcery.PortalServer.Portal
#  alias Sorcery.Query.ReverseQuery, as: RQ
#  alias Sorcery.ReturnedEntities, as: RE
#  import Sorcery.Helpers.Maps
#

  def entry(%{args: _args} = _msg, state) do
    "@TODO"
    state
  end


end


