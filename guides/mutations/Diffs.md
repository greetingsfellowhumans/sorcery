# Diffs

This is the low level struct being used under the hood. In theory you should never need to use it directly. Use Mutations and Modifications instead.

When the canonical PortalServer receives a Mutation, it applies its data store to convert that into a Diff

```elixir
# Here we have only one diff row, which has only one change. The age has increased
diff = [
  %{tk: :player, id: 1, new_entity: %{id: 1, name: "Jose", age: 21}, changes: [

    # Format:
    # attr, old, new
    {:age,  20,  21}
  ]}
]
```
