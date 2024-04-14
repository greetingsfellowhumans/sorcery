defmodule MyApp.Schemas.Player do
  use Sorcery.Schema, 
    fields: %{
      name: %{t: :string, min: 4, max: 45, default: "Nameless"},
      age: %{t: :integer, min: 13, max: 99, optional?: false},
      health: %{t: :integer},
      money: %{t: :integer, min: 0},
      team_id: %{t: :fk, module: MyApp.Schemas.Team, optional?: false},
    }
end
