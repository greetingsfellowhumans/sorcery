defmodule MyApp.Schemas.SpellType do
  use Sorcery.Schema, 
    fields: %{
      name: %{t: :string, min: 4, max: 45, default: "Nameless"},
      cost: %{t: :integer, optional?: false},
      power: %{t: :integer},
    }
end
