defmodule Sorcery.Helpers do
  @moduledoc """
  Misc utility functions that don't fit anywhere better.
  """


  alias Sorcery.Helpers, as: S

  @doc """
  Given a directory, and a starting module scheme, returns a map. 

  Note that it is not actually opening the files and checking module names. It uses the FILE names to generate module names.

  So use the usual elixir naming conventions. 

  ## Examples
      iex> path = "test/dummy/schemas"
      iex> mod_root = MyApp.Schemas
      iex> files = File.ls!(path)
      iex> "player.ex" in files
      true
      iex> modules_map = Sorcery.Helpers.build_modules_map(path, mod_root)
      iex> modules_map.player
      MyApp.Schemas.Player
  """
  defdelegate build_modules_map(path, module_root), to: S.Files

  @doc """
  Take a schema module and return the tk as a string
  ## Examples
    iex> Sorcery.Helpers.mod_to_tk_str(MyApp.Schemas.BattleArena)
    "battle_arena"
  """
  defdelegate mod_to_tk_str(mod), to: S.Names


  @doc """
  Take a schema module and return the tk as an atom
  ## Examples
    iex> Sorcery.Helpers.mod_to_tk(MyApp.Schemas.BattleArena)
    :battle_arena
  """
  defdelegate mod_to_tk(mod), to: S.Names
end
