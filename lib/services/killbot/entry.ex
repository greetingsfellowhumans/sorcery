defmodule Sorcery.Killbot.Row do

  defstruct [
    :pid,
    :wait_until,
  ]
  def new(pid, %{interval: ms, postmortem_delay: delay} = _killbot_state) do
    struct(__MODULE__, %{pid: pid, wait_until: ms * delay})
  end
end

defmodule Sorcery.Killbot do
  @moduledoc ~s"""
  This is a garbage collector, of sorts. It periodically checks SorceryDb for dead pids, checks whether any of their watched data is still watched by anything else, and if not, deletes things from SorceryDb.
  """
  import Sorcery.SorceryDb, only: [get_all_portal_names: 0, get_all_portal_instances: 2]
  import Sorcery.Helpers.Maps

  # {{{ Client
  def run_now(), do: GenServer.cast(__MODULE__, :run)
  def get_watched(), do: GenServer.call(__MODULE__, :get_watched)
  # }}}

  # {{{ Server
  use GenServer

  def start_link(opts \\ []) do
    config = Keyword.get(opts, :killbot, %{})
    src = Keyword.get(opts, :src, Src)
    state = Map.merge(%{
      watching: %{},
      interval: 60 * 1_000, # 1 minute
      postmortem_delay: 2,
      src: src
    }, config)
    {:ok, _pid} = GenServer.start_link(__MODULE__, state, name: __MODULE__)
    schedule_run(state)
  end

  def init(args), do: {:ok, args}

  def schedule_run(%{interval: ms} = _state) do
    Task.start(fn ->
      Process.sleep(ms)
      run_now()
    end)
  end


  def handle_call(:get_watched, _, state), do: {:reply, state.watching, state}
  def handle_cast(:run, state) do
    portal_names = get_all_portal_names()
    portals = collect_all_dead_portals(state, portal_names)
              |> Map.filter(fn {pid, _, _} -> !Process.alive?(pid) end) # Fixes a race condition
    dbg portals
    all_dead_pids = Enum.map(portals, &(elem(&1, 0)))
    #pid_portals = Enum.map(portals, fn -> end)
    state = put_portals(state, portals)
    portals = complete_watchers(state) # %{pid => %{query_mod: [ {timestamp, args} ]}}
    diff = get_diff_rows(state, portals)
           |> get_diff()

    portal_names = Sorcery.SorceryDb.ReverseQuery.get_portal_names_affected_by_diff(diff)
    #Sorcery.SorceryDb.ReverseQuery.reverse_query(diff, portal_names, [])
    #|> Enum.filter(fn pid -> pid not in all_dead_pids end)

    #dbg all_dead_pids

    # excluding the watched pids, now grab EVERY portal in the system, run it's query, 
    # Sorcery.SorceryDb.ReverseQuery.reverse_query(diff, portal_names, excluded_pids
    # Get the disjoint entities table
    # Delete those entities from SorceryDb
    # Delete the pids in state.watching

    schedule_run(state)
    {:noreply, state}
  end

  def get_diff(diff_rows) do
    tks = Enum.reduce(diff_rows, MapSet.new([]), fn %{tk: tk}, acc -> MapSet.put(acc, tk) end)
    struct(Sorcery.Mutation.Diff, %{tks_affected: tks, rows: diff_rows})
  end


  # {{{ get_entities state, portals
  # Get a map 
  defp get_diff_rows(%{src: src} = _state, portals) do
    schemas = src.config().schemas
    for {_pid, watcher} <- portals do
      for {query_mod, entries} <- watcher do
        lvar_tks = query_mod.raw_struct().lvar_tks
        for {_, args} <- entries do
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
        Enum.any?(entries, fn {delay, _} -> 
          Time.before?(delay, t) 
        end)
      end)
    end)
  end
  # }}}

  # {{{ put_portals(state, portals)
  defp put_portals(state, portals) do
    Enum.reduce(portals, state, fn {pid, query_mod, args}, state ->
      duplicate? = get_in_p(state, [:watching, pid, query_mod]) || []
                   |> Enum.any?(fn {_t, old_args} -> old_args == args end)
      if duplicate? do
        state
      else
        row = {get_time_after_delay(state), args}
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
      |> Enum.map(&List.to_tuple/1)
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
