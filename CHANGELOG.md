# Changelog

Dates are in the format of yyyy-mm-dd

## [Unreleased]

- Better documentation.
- Clean up the demo app

## [0.4.15] - 2025-04-06

### Changed

- Made dependencies more lenient

## [0.4.14] - 2024-11-20

### Added

- add handle_sorcery middleware for GenServerHelpers

## [0.4.13] - 2024-11-18

### Added

- handle_sorcery now has some documentation.
- handle_sorcery now allows middleware hooks (hook_before, hook_after)

## [0.4.12] - 2024-11-03

### Fixed

- When using LiveHelpers portal_view or portal_one, raises if searching for a portal that doesn't exist.

## [0.4.11] - 2024-11-03

### Fixed

- When using LiveHelpers portal_view or portal_one, raises if searching for an lvar that doesn't exist in that portal.

## [0.4.10] - 2024-11-01

This is a complete rewrite of the query engine for the Ecto adapter.
Instead of manually building an entire query, we now leverage Ecto.Multi.
In SrcQL, every clause per Lvar will be put into its own Multi.all(...), and is given access to the previous results.
Just as before, it is important that SrcQL clauses come in an order that makes sense. Do not reference an Lvar that appears later.
This change fixes several bugs with queries.

### Fixed

- Several SrcQL query bugs

## [0.4.9] - 2024-09-22

### Added

- New field type :decimal, for whenever you are working with :numeric fields in ecto migrations.

## [0.4.8] - 2024-09-15

### Added

- You can now put a handle_success/2 callback into spawn_portal

## [0.4.7] - 2024-08-18

### Fixed

- Optimistic updates were not respecting lvar names

## [0.4.6] - 2024-08-05

### Fixed

- table not found error, usually when app is starting up.
- Fixed a bug with the reverse query when not all dependencies are met.
- Fixed a bug where reverse query broke while deleting entities

## [0.4.5] - 2024-08-01

### Fixed

Broken handle_success and handle_fail options for mutations

### Changed

handle_success and handle_fail options with LiveHelpers now update the socket instead of sorcery state.

## [0.4.4] - 2024-07-29

### Fixed

Broken call to put_flash

## [0.4.3] - 2024-07-21

### Added

Mutation.send_mutation now takes an optional 3rd argument.
This must be a keyword list of options.
There are three options
  :optimistic     | true | Whether to try to do an optimistic update. Does not work well when creating new entities.
  :handle_fail    | nil | a function that takes the error, and the state. Returns state.
  :handle_success | nil | a function that takes the error, and the state. Returns state.

### Fixed

Ecto Adapter error handling when a transaction fails.

## [0.4.2] - 2024-07-06

### Fixed

- A bug that would crash mutations whenever the portal had an empty value for an lvar.

## [0.4.1] - 2024-06-22

### Fixed

- Several bugs with the SrcQL Ecto Adapter
- Add a :pending_portals list to inner_state, and a has_loaded? function to LiveHelpers.
- A bug when you insert multiple entities and one depends on the other.
Note there might still be an ecto foreign key constraint error. Dropping the constraint solved it for me, but I wish there were a cleaner solution.

- Allow spawn_portal to work even in an environment without the html helpers

- Fix a bug in which only one portal per pid could ever be found by the reverse query

### Breaking Changes

When creating new entities, it will no longer autofill missing data with randomly generated content.

### Added

- SrcQL Ecto adapter now handles nil comparison safely.
- Mutation.skip/3
- Mutation.validate/3
- LiveHelpers add an optimistic_mutations function

## [0.4.0] - 2024-06-22

### Fixed

A lot of the automatic data generation was broken. Rebuilt much of it, added some pretty thorough prop tests.

### Breaking Changes

The Schema defaults are somewhat different, so you should be aware that:

- List and map fields now default to optional?: false because it makes more sense for an empty list to be `[]` than `nil`

## [0.3.7] - 2024-06-19

### Fixed

- Typespec warnings
- Issues when Phoenix mounts twice, particularly the first time when the expected data is not present

## [0.3.6] - 2024-06-19

### Fixed

- Conflict when starting tests on an app that depends on sorcery.
workaround for now is setting an environment varialbe SORCERY_DEVELOPMENT=true when working on sorcery itself
- Cleaned up several warnings

## [0.3.5] - 2024-06-18

### Fixed

Mutation.create_entity was broken. I fixed it.

## [0.3.4] - 2024-06-17

### Added

- New field types for schemas: float, boolean, list, map
Note that list fields must contain a :coll_of type. for example:

```elixir
my_items: %{t: :list, coll_of: :integer}
```

While using ecto/postgres, lists and maps are stored as json. I have not tested this with anything else

## [0.3.3] - 2024-06-17

### Added

- The Killbot module
  This is basically a garbage collection system. Since SorceryDb stores a lot of entities in :mnesia, and some other portal data in :ets, Killbot is a process that periodically checks which entities are no longer being used anywhere, and safely removes them.

### Changed

New options for your Src module

```elixir
use Sorcery,
    killbot: %{
      interval: int,
      postmortem_delay: int
    }
```

These are optional.
In theory, Killbot should not require any setup, it is initialized by the `use Sorcery` under the hood.

### Breaking Changes

None (in theory)

## [0.3.2] - 2024-06-01

### Added

- Optimistic Updates
  Now when you send a mutation, it will return a :temp_data field, guessing at the changes. This allows us to see the updated data long before the changes reach the parent portal_server or database.
  temp_data is reset after the real data comes in
  Mutations cannot be run on a portal that already has temp_data. That would be too complex. Extra mutations are silently dropped.
- More documentation, especially for Sorcery.Query

### Changed

- %Sorcery.PortalServer.InnerState{}
  This has eased a lot of confusion and unveiled bugs waiting to happen.
- Turned Sorcery.Query into a behaviour, and the __using__ macro into an implementation of it.
    Now in exdoc, all the functions defined by Use are well documented with examples that pass tests.
