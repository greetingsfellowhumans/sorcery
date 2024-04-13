defmodule Sorcery.Mutation.Diff do
  defstruct [
    tks_affected: [],
    rows: [],
  ]
end

defmodule Sorcery.Mutation.DiffRow do
  defstruct [
    tk: nil,
    id: nil,
    before: [],
    after: [],
    changed_keys: [],
  ]
end
