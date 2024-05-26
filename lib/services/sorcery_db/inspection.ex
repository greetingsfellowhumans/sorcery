defmodule Sorcery.SorceryDb.Inspection do
  import Sorcery.SorceryDb.SchemaAdapter


  # {:atomic, [ [id, val], [id, val]  ]}
  def view_tk(sorcery_module, tk) do
    schemas = sorcery_module.config().schemas
    schemas_attrs = tk_attrs_map(schemas)

    head = get_variable_attrs_list(schemas_attrs[tk])
    head = [tk | head] |> List.to_tuple()
    :mnesia.transaction(fn -> 
      :mnesia.select(tk, [{ head, [], [:"$$"] }]) 
    end)
  end

  # e.g.
  # [[:battle_portal], [:player_portal]]
  def view_portal_names() do
    :ets.match(:sorcery_portal_names, {:"$1"})
  end

  # e.g.
  # [ [pid, query_module, args] ]
  defdelegate get_all_portal_instances(portal_name), to: Sorcery.SorceryDb.ReverseQuery


end
