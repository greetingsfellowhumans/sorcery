defmodule Sorcery.SorceryDb do
  @moduledoc false
  import Sorcery.SorceryDb.SchemaAdapter
  import Sorcery.SorceryDb.MnesiaAdapter
  import Sorcery.SorceryDb.Query
  import Sorcery.Helpers.Maps


  # {{{ SorceryDb


  # {{{ build_mnesia_table
  def build_mnesia_table(tk, schema_mod) do
    attrs = get_attrs_list(schema_mod)
    :mnesia.create_table(tk, [attributes: attrs])
  end
  # }}}



  # {{{ query_portal(pid_portal)
  def query_portal(%{args: args, query_module: mod} = pid_portal, schemas) do
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
        # Try again after other lvars have resolved.
        all_lvars = all_lvars ++ [lvar]
        query_lvars(all_lvars, all_clauses, data, args, schemas_attrs)
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
      def init(_) do
        watchers_table = :ets.new(:sorcery_watchers, [:named_table, :duplicate_bag, :public, read_concurrency: true, write_concurrency: true])
        :mnesia.create_schema([node()])
        :mnesia.start()

        schema_files =
          unquote(opts)
          |> Keyword.get(:opts)
          |> Keyword.get(:paths)
          |> Map.get(:schemas)
          |> File.ls!()

        for filename <- schema_files do
          {tk, schema_mod} = Sorcery.SorceryDb.SchemaAdapter.parse_schema_module(filename, __MODULE__.Schemas)
          Sorcery.SorceryDb.build_mnesia_table(tk, schema_mod)
        end

        {:ok, %{}}
      end
      # }}}


      # {{{ Client
      def cache_pid_entity(pid, portal, timestamp, tk, entity), do: :ets.insert(:sorcery_watchers, {pid, portal, timestamp, tk, entity})
      # @TODO unchache_pid_entity

      def run_mutation(mutation, pid_portals, parent_pid) do
        schemas = __MODULE__.config().schemas
        timestamp = Time.utc_now()
        :mnesia.transaction(fn ->
          Sorcery.SorceryDb.MnesiaAdapter.apply_changes(mutation, schemas)
        end)

        new_portals = run_queries(pid_portals, schemas)
        for {pid, portal_name, data} <- new_portals do
          args = %{updated_at: timestamp, data: data, portal_name: portal_name, parent: parent_pid}
          send(pid, {:sorcery, %{command: :replace_portal, args: args}})
        end
      end

      def run_queries(pid_portals, schemas) do
        Enum.map(pid_portals, fn pid_portal ->
          case Sorcery.SorceryDb.query_portal(pid_portal, schemas) do
            {:atomic, {:ok, data}} -> 
              data = to_string_keys(data, 1)
              {pid_portal.pid, pid_portal.portal_name, data}
            err -> raise err
          end
        end)
      end

      # }}}

    end
  end

  # }}}

end
