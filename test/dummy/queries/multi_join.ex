defmodule Src.Queries.MultiJoin do
  # This is my new favourite example query. It is its own stress test, and elegantly covers most use cases.

  use Sorcery.Query, %{
    find: %{
      "?player" => :*,
      "?spell_type" => :*,
      "?spells" => :*,
    },
    args: %{
      player_id: :integer
    },
    where: [
      [ "?player", :player, :id, :args_player_id],
      [ "?spell_type", :spell_type, :power, {:>, 0}],

      [ "?spells", :spell_instance, [
        {:player_id, "?player.id"},
        {:type_id, "?spell_type.id"},
      ]],          

    ]
  }

end
