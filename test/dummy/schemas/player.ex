defmodule Src.Schemas.Player do

  use Sorcery.Schema, 
    meta: %{
      optional?: false
    },
    fields: %{
      a_list: %{t: :list, coll_of: :integer},
      name: %{t: :string, min: 4, max: 45, default: "Nameless"},
      age: %{t: :integer, min: 13, max: 99, optional?: true},
      health: %{t: :integer, min: 0, max: 100},
      mana: %{t: :integer, min: 0, max: 500},
      money: %{t: :integer, min: 0, max: 9999},
      team_id: %{t: :fk, module: Src.Schemas.Team},
    }
end
