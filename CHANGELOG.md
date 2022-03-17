## [0.2.0] March 16, 2022

### Breaking Changes
- Src insert placeholder ids must now include the tablekey. i.e.: "$sorcery:user:1" instead of "$sorcery:1"

### Deprecations
- Src Access implementation still exists but should not be used directly. Use Src.get_in and Src.put_in, instead of get_in and put_in.

### Other Changes
- Updated Readme
- Added the ability to insert multiple entities, that refer to other placeholder entities, on the fly.
- Rebuilt the entire Ecto.Adapter, with better tests, type contracts, and reliability.
