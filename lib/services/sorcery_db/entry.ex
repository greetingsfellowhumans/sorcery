defmodule Sorcery.SorceryDb do
  @moduledoc false
  import Sorcery.SorceryDb.SchemaAdapter
  import Sorcery.SorceryDb.MnesiaAdapter
  import Sorcery.SorceryDb.Query
  import Sorcery.Helpers.Maps
  alias Sorcery.SorceryDb.ReverseQuery, as: RQ


  # {{{ SorceryDb


  # {{{ build_mnesia_table
  def build_mnesia_table(tk, schema_mod) do
    attrs = get_attrs_list(schema_mod)
    :mnesia.create_table(tk, [attributes: attrs])
  end
  # }}}

  defdelegate get_all_portal_names(), to: RQ
  defdelegate get_all_portal_instances(portal_name, opts), to: RQ

  def remove_entities(tk_ids) do
    :mnesia.transaction(fn ->
      for {tk, ids} <- tk_ids do
        for id <- ids do
          :mnesia.delete(tk, id, :write)
        end
      end
    end)
  end


  def remove_pids(pid_portals) do
    for {pid, portal_name, _query, _args} <- pid_portals do
      table_name = RQ.get_portal_table_name(portal_name)
      :ets.delete(table_name, pid)
    end
  end



  # {{{ query_portal(pid_portal)
  def query_portal(%{args: args, query_module: mod} = _portal, schemas) do
    schemas_attrs = tk_attrs_map(schemas)
    clauses = mod.clauses()
    lvar_names = Enum.map(clauses, &(&1.lvar)) |> Enum.uniq()
    lvar_clauses = Enum.group_by(clauses, &(&1.lvar))
    :mnesia.transaction(fn ->
      query_lvars(lvar_names, lvar_clauses, %{}, args, schemas_attrs)
    end)
  end

  defp query_lvars([], _clauses, data, _args, _), do: {:ok, data}
  defp query_lvars([lvar | all_lvars], all_clauses, data, args, schemas_attrs) do
    clauses = Map.get(all_clauses, lvar)
    [%{tk: tk} | _] = clauses

    head = get_variable_attrs_list(schemas_attrs[tk])
    head = [tk | head] |> List.to_tuple()
    Enum.reduce_while(clauses, [], fn clause, acc ->
      case where_to_guard(clause, data, args, schemas_attrs) do
        :unmet_deps -> 
          {:halt, :unmet_deps}
        guard -> {:cont, [guard | acc]}
      end
    end)
    |> case do
      :unmet_deps ->
        retried_lvars = Map.get(args, :retried_lvars, [])
        if lvar in retried_lvars do
          # Last chance to resolve this lvar
          query_lvars(all_lvars, all_clauses, data, args, schemas_attrs)
        else
          # Try again after other lvars have resolved.
          all_lvars = all_lvars ++ [lvar]
          args = update_in_p(args, [:retried_lvars], [lvar], &([lvar | &1]))
          query_lvars(all_lvars, all_clauses, data, args, schemas_attrs)
        end
      guards ->
        ret = [:"$$"]
        entity_table = :mnesia.select(tk, [{ head, guards, ret} ])
        |> Enum.reduce(%{}, fn values_list, acc ->
          entity = list_to_entity(values_list, schemas_attrs[tk])
          Map.put(acc, entity[:id], entity)
        end)

        data = Map.update(data, lvar, entity_table, fn old -> deep_merge(old, entity_table) end)
        query_lvars(all_lvars, all_clauses, data, args, schemas_attrs)
    end
  end


  # }}}



  # }}}


  # {{{ use macro / GenServer

  defmacro __using__(opts) do
    quote do
      use GenServer

      # {{{ Setup
      def start_link(_state) do
        GenServer.start_link(__MODULE__, %{})
      end

      @impl true
      def init(state) do
        :mnesia.create_schema([node()])
        :mnesia.start()

        killbot_config = unquote(opts)[:opts]
                         |> Keyword.put(:src, __MODULE__)

        Sorcery.Killbot.start_link(killbot_config)

        for {tk, mod} <- __MODULE__.config().schemas do
          Sorcery.SorceryDb.build_mnesia_table(tk, mod)
        end

        {:ok, %{}}
      end
      # }}}


      # {{{ Client

      def run_mutation(mutation, diff) do
        schemas = __MODULE__.config().schemas
        :mnesia.transaction(fn ->
          Sorcery.SorceryDb.MnesiaAdapter.apply_changes(mutation, schemas)
        end)
        timestamp = Time.utc_now()

        RQ.reverse_query(diff) # returns [ {pid, portal_name, query_mod, args} | _]
        |> Enum.each(&(run_queries(&1, schemas, timestamp)))
      end


      def run_queries({pid, name, query, args}, schemas, timestamp) do
          pid_portal = %{pid: pid, portal_name: name, query_module: query, args: args}
          case Sorcery.SorceryDb.query_portal(pid_portal, schemas) do
            {:atomic, {:ok, data}} -> 
              data = to_string_keys(data, 1) # convert :"?lvar" into "?lvar"
              msg = %{
                command: :portal_put,
                data: data,
                updated_at: timestamp,
                portal_name: name
              }
              send(pid, {:sorcery, msg})

            err -> 
              raise err
          end
      end

      # }}}

    end
  end

  # }}}

end
