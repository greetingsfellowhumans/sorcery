defmodule Sorcery.PortalServer.Portal do

  @moduledoc """
  A Portal represents an ongoing Query.
  Rather than grabbing data and ending, it continues watching for changes to the results set.

  A copy of any given Portal is found in the state of two different PortalServers; the parent, and the child PortalServer.
  """
  alias Sorcery.PortalServer
  defstruct [
    :query_module,
    :child_pids,
    :parent_pid,
    :ref,
    #:reverse_query,
    args: %{}, # Is this even necessary? Might be useable for optimizing?
    known_matches: %{},
    fwd_find_set: MapSet.new([]),
    rev_find_set: MapSet.new([]),
  ]

  def new(body \\ %{}) do
    body = Map.put(body, :ref, make_ref())
    struct(__MODULE__, body)
  end
end
