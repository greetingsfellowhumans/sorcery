defmodule MyApp.Queries.AllTeams do
  # This is my new favourite example query. It is its own stress test, and elegantly covers most use cases.

  use Sorcery.Query, %{
    find: %{
      "?all_teams" => :*,
    },
    args: %{},
    where: [
      [ "?all_teams", :team, :id, {:>, 0}],              # Get ALL children
    ]
  }

end

