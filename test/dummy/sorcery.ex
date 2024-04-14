defmodule MyApp.Sorcery do
  use Sorcery,
    debug: true,
    paths: %{
      schemas: "test/dummy/schemas",
      queries: "test/dummy/queries"
    }
end
