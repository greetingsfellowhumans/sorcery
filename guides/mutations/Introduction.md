# Introduction

We always use mutations when transmitting change across portals. 

A Mutation is kind of like a Query, but instead of receiving data, we are sending it.

## Mutations and Modifications

One mutation holds many Modifications.

A modification is a pure function that takes in the selection from a query, plus some map of arguments, and changes the data somehow. Note that this is all lazy. When you write a mutation, you cannot know what values will be in the selection, because it is going to be executed on another PortalServer.


```elixir
  alias Sorcery.Mutation.Modifications, as: M
  alias Sorcery.Query, as: SrcQL

  def successful_attack_mutation(%{attacker_id: _, defender_id: _} = args) do
      srcql = SrcQL.new(%{
        where: [
          {"?players", :player,  :id, [args.attacker_id, args.defender_id]}
        ],
        find: %{
          "?players" => [:health, :points]
        }
      })

      mutation = Sorcery.Mutation.new(%{
        args: args,
        modifications: [&__MODULE__.modification/2]
      })

      Sorcery.Mutation.push(mutation)
    
  end


  def modification(mutation, args) do
    # A player takes damage
    mutation = M.decrease(mutation, ["?players", args.defender_id, :health], 5)

    # If that player is dead, then the attacker gains a point
    if M.get(["?players", args.defender_id, :health]) <= 0 do
      M.increase(mutation, ["?players", args.attacker_id, :points], 1)
    else
      mutation
    end
  end

```
