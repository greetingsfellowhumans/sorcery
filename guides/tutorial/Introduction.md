# Introduction

Every journey starts at the same point: installation and setup.

First, add sorcery to your mix.deps. If you don't know how to do that, then sorcery might be a little too advanced for you. Sorry.

Next, we add your own personal Sorcery module. This is kind of like how you might use Ecto.Repo, in the sense that you dedicate a module of your own app to it, and use that as the entrypoint for everything.

```elixir
defmodule MyApp.Sorcery do
  use Sorcery,
    schemas: Sorcery.Helpers.Files.build_modules_map("./lib/sorcery/schemas", MyApp.Sorcery.Schemas),
    queries: Sorcery.Helpers.Files.build_modules_map("./lib/sorcery/queries", MyApp.Sorcery.Schemas),
    mutations: Sorcery.Helpers.Files.build_modules_map("./lib/sorcery/mutations", MyApp.Sorcery.Schemas),
    modifications: Sorcery.Helpers.Files.build_modules_map("./lib/sorcery/modifications", MyApp.Sorcery.Schemas),
end
```

Most of the time you will want to use Sorcery with a file structure like this:

```bash
/lib
  /sorcery
    /schemas
    /queries
    /mutations
    /modifications
```

And put all appropriate files in there as needed.
