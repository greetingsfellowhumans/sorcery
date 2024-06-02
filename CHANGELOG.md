# Changelog

## [Unreleased]
- Most likely optimistic updates will break when the mutation creates new entities. Still need to figure out what to do there.
- Create the killbot module to periodically trim data from SorceryDb when pids are dead.
- Better document SorceryDb.

## [0.4.0] - 2024-06-01
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
