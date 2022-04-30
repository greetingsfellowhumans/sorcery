# Upcoming

## [0.2.6] April 1, 2022
Improved SrcHelpers
- General code cleanup
- Expand testing
- Allow all argument column types instead of just :id

Tweaked the Src Access functions.
- Src.put_in and Src.update_in will now work even when the path doesn't exist. like `mkdir -p`

===================================================================================
===================================================================================

# Changes

## [0.2.5] March 31, 2022
Started work on Sorcery.SpecDb.SrcHelpers.build_interceptor()

## [0.2.4] March 27, 2022
## Feature
Added SpecDb system
- SchemaModule.t() can be passed into Norm contract.
- SchemaModule.gen(%{}) can be passed into property tests.
- Virtually all Ecto.Changeset stuff can be automated away.

## [0.2.3] March 22, 2022
## Feature
Added Src.put_args and Src.update_args


## [0.2.2] March 16, 2022
### Fix
- Norm specs in some places expected ids to only be integers, which would break when using placeholders.


## [0.2.1] March 16, 2022
### Fix
- Spotted and fixed a potential memory leak. Sometimes during unmount, a race condition would cause the cleanup functionality to not happen, thus the db would theoretically grow forever without being trimmed as people leave.


## [0.2.0] March 16, 2022
### Breaking Changes
- Src insert placeholder ids must now include the tablekey. i.e.: "$sorcery:user:1" instead of "$sorcery:1"

### Deprecations
- Src Access implementation still exists but should not be used directly. Use Src.get_in and Src.put_in, instead of get_in and put_in.

### Other Changes
- Updated Readme
- Added the ability to insert multiple entities, that refer to other placeholder entities, on the fly.
- Rebuilt the entire Ecto.Adapter, with better tests, type contracts, and reliability.
