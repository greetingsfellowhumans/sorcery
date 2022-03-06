defmodule Sorcery.Src.Git do

  @moduledoc """
  Every assigns.src is basically a subset of the backend db.
  We always check the query/2 to ensure only the relevant data is tracked.
  """


  #def filter_pattern(%{subject: %Subject{pattern: pattern}} = src, db) do
  #  pattern.(src, db)
  #end

  #@doc """
  #The usual process is something like this:
  #def mount(_, socket) do
  #  src = %Src{subject: %Subject{pattern: fn src -> db end, query: fn src -> Repo.all!(...) end}}
  #        |> Src.clone()
  #end
  #"""
  #def clone(%{subject: %Subject{pattern: pattern, query: query}}) do
  #  {pattern, query}
  #end
  #def clone(src), do: src


  #@doc """
  #Here, you already have a Src, and you want to merge it with a more recent remote Src.
  #But make no attempt to merge changes into original
  #"""
  #def fetch(%{original_db: _loc_og, changes_db: loc_ch} = local, %{original_db: _rem_og, changes_db: rem_ch} = _remote) do
  #  local
  #  |> Map.put(:original_db, Map.merge(loc_ch, rem_ch))
  #  |> Map.put(:changes_db, Map.merge(loc_ch, rem_ch))
  #end


  #@doc """
  #Here we are pulling a remote Src, 
  #"""
  #def pull(%{original_db: _loc_og, changes_db: loc_ch} = local, %{original_db: _rem_og, changes_db: rem_ch} = _remote) do
  #  local
  #  |> Map.put(:original_db, Map.merge(loc_ch, rem_ch))
  #  |> Map.put(:changes_db, Map.merge(loc_ch, rem_ch))
  #end


end
