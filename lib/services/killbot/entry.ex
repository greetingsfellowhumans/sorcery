defmodule Sorcery.Killbot do
  @moduledoc ~s"""
  This is a garbage collector, of sorts.

  Every time it runs, it will scan SorceryDb for all dead pids and hang onto those until the postmortem_delay is over
  For every pid in which the delay IS over, it will find the entities in their portals, filter out any entities that are being watched in other portals, and then remove them from :mnesia.
  ```elixir
  defmodule MyApp.Sorcery do
    use Sorcery,
      killbot: %{
        # Defaults to 10 minutes
        interval: 10 * 60 * 1_000, 

        # Wait 2 intervals AFTER the pid dies, before wiping the entities       
        # It is likely a user will close a page and come back a few minutes later...
        # So we don't want to uncache things too quickly.
        #
        # Again, I stress that this is NOT milliseconds, but the number of intervals.
        postmortem_delay: 2        
      }
  end
  ```
  """
  import Sorcery.SorceryDb, only: [get_all_portal_names: 0, get_all_portal_instances: 2]
  import Sorcery.Helpers.Maps

  # {{{ Client
  @doc ~s"""
  Start a run immediately. This does speed up the postmortem_delay
  """
  def run_now(), do: GenServer.cast(__MODULE__, :run)

  @doc ~s"""
  Return all the dead portals being watched, which have not yet been removed.
  """
  def get_watched(), do: GenServer.call(__MODULE__, :get_watched)
  # }}}

  # {{{ Server
  use GenServer

  @doc false
  def start_link(opts \\ []) do
    config = Keyword.get(opts, :killbot, %{})
    src = Keyword.get(opts, :src, Src)
    state = Map.merge(%{
      watching: %{},
      interval: 10 *  60 * 1_000, # 10 minutes
      postmortem_delay: 2, # wait 2 intervals AFTER the pid dies, before wiping the entities
      src: src
    }, config)
    {:ok, _pid} = GenServer.start_link(__MODULE__, state, name: __MODULE__)
    schedule_run(state)
  end

  @doc false
  def init(args), do: {:ok, args}

  @doc false
  def schedule_run(%{interval: ms} = _state) do
    Task.start(fn ->
      Process.sleep(ms)
      run_now()
    end)
  end


  def handle_call(:get_watched, _, state), do: {:reply, state.watching, state}


  def handle_cast(:run, state) do
    # Setup. Just gathering data together in one place
    portal_names = get_all_portal_names()
    dead_pid_portals = collect_all_dead_portals(state, portal_names)
    state = put_portals(state, dead_pid_portals)
    portals = complete_watchers(state) # %{pid => %{query_mod: [ {timestamp, args} ]}}

    # Since we are leveraging ReverseQuery, we just need a diff
    diff = get_diff_rows(state, portals)
           |> get_diff()

    portal_names = Sorcery.SorceryDb.ReverseQuery.get_portal_names_affected_by_diff(diff)
    live_pid_portals = Sorcery.SorceryDb.ReverseQuery.reverse_query(diff, portal_names, dead_pid_portals)
                       |> Enum.filter(fn pid_portal -> pid_portal not in dead_pid_portals end)
    live_entities = get_live_entities(state, live_pid_portals) # returns a list of {tk, id}

    # We can safely assume that all of these are no longer tracked by anyone.
    # @TODO is it possible for a race condition to cause issues?
    dead_entities = get_dead_entities(diff, live_entities) # returns %{tk: [ids]}
    Sorcery.SorceryDb.remove_entities(dead_entities)
    Sorcery.SorceryDb.remove_pids(dead_pid_portals)

    state = Enum.reduce(portals, state, fn {pid, _}, state ->
      delete_in(state, [:watching, pid])
    end)

    schedule_run(state)
    {:noreply, state}
  end

  # {{{ get_dead_entities
  defp get_dead_entities(diff, live_entities) do
    dead_entities = Enum.map(diff.rows, fn %{tk: tk, id: id} -> {tk, id} end) |> MapSet.new()
    live_entities = live_entities |> MapSet.new()
    MapSet.difference(dead_entities, live_entities)
    |> Enum.reduce(%{}, fn {tk, id}, acc -> Map.update(acc, tk, [id], &([id | &1])) end)
  end
  # }}}

  # {{{ get_live_entities
  defp get_live_entities(%{src: src}, pid_portals) do
    schemas = src.config().schemas
    Enum.reduce(pid_portals, %{}, fn {_pid, _name, query_mod, args}, acc ->
      lvar_tks = query_mod.raw_struct().lvar_tks
      case Sorcery.SorceryDb.query_portal(%{args: args, query_module: query_mod}, schemas) do
        {:atomic, {:ok, finds}} ->
          Enum.map(finds, fn {lvar, table} ->
            tk = Enum.find_value(lvar_tks, fn {l, t} -> if l == "#{lvar}", do: t, else: nil end)
            Enum.map(table, fn {id, _entity} ->
              {tk, id}
            end)
          end) |> List.flatten()
        _ -> acc
      end
    end)
  end
  # }}}

  # {{{ get_diff(rows)
  @doc false
  def get_diff(diff_rows) do
    tks = Enum.reduce(diff_rows, MapSet.new([]), fn %{tk: tk}, acc -> MapSet.put(acc, tk) end)
    struct(Sorcery.Mutation.Diff, %{tks_affected: tks, rows: diff_rows})
  end
  # }}}


  # {{{ get_diff_rows state, portals
  # Get a map 
  defp get_diff_rows(%{src: src} = _state, portals) do
    schemas = src.config().schemas
    for {_pid, watcher} <- portals do
      for {query_mod, entries} <- watcher do
        lvar_tks = query_mod.raw_struct().lvar_tks
        for {_, _portal_name, args} <- entries do
          case Sorcery.SorceryDb.query_portal(%{args: args, query_module: query_mod}, schemas) do
            {:atomic, {:ok, finds}} ->
              Enum.map(finds, fn {lvar, table} ->
                tk = Enum.find_value(lvar_tks, fn {l, t} -> if l == "#{lvar}", do: t, else: nil end)
                Enum.map(table, fn {id, entity} ->
                  Sorcery.Mutation.DiffRow.new(%{tk: tk, old_entity: entity, changes: [{:id, id, nil}]})
                end)
              end)
            _ -> []
          end
        end
      end
    end
    |> List.flatten()
  end
  # }}}

  # {{{ complete_watchers
  # The portals that have completed their postmortem_delay
  defp complete_watchers(%{watching: watching} = _state) do
    t = get_time_now()
    Map.filter(watching, fn {_pid, watcher} ->
      Enum.any?(watcher, fn {_query_mod, entries} ->
        Enum.any?(entries, fn {delay, _name, _} -> 
          Time.compare(delay, t) in [:lt, :eq]
        end)
      end)
    end)
  end
  # }}}

  # {{{ put_portals(state, portals)
  defp put_portals(state, portals) do
    Enum.reduce(portals, state, fn {pid, portal_name, query_mod, args}, state ->
      duplicate? = get_in_p(state, [:watching, pid, query_mod]) || []
                   |> Enum.any?(fn {_t, _name, old_args} -> old_args == args end)
      if duplicate? do
        state
      else
        row = {get_time_after_delay(state), portal_name, args}
        update_in_p(state, [:watching, pid, query_mod], [row], fn rows -> [row | rows] end)
      end
    end)
  end
  # }}}

  defp get_time_now(), do: Time.utc_now()
  defp get_time_after_delay(%{postmortem_delay: d, interval: i}), do: Time.add(get_time_now(), d * i, :millisecond)

  # {{{ collect_all_dead_portals
  defp collect_all_dead_portals(_state, portal_names) do
    for name <- portal_names do
      get_all_portal_instances(name, [])
      |> Enum.map(fn [pid, query, args] -> {pid, name, query, args} end)
    end
    |> List.flatten()
    |> Enum.filter(fn row -> 
      pid = elem(row, 0)
      !Process.alive?(pid) 
    end)
    |> Enum.uniq()
  end
  # }}}

  # }}}

end
