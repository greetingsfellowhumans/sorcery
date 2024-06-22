# Changelog

## [Unreleased]
- Better documentation.
- Clean up the demo app


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
