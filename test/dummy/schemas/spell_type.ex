defmodule MyApp.Sorcery.Schemas.SpellType do
  use Sorcery.Schema, 
    meta: %{ optional?: false },
    fields: %{
      name: %{t: :string, min: 4, max: 45, default: "Nameless"},
      cost: %{t: :integer},
      power: %{t: :integer},
    }
end
