defmodule Sorcery.Mutation.Temp do
  import Sorcery.Helpers.Maps


  def add_temp_portal(inner_state, %{portal: portal} = mutation) do
    original_data = portal.known_matches.data

    new_data = Enum.reduce(mutation.operations, original_data, fn operation, latest_data ->
      build_temp_portal(operation, original_data, latest_data)
    end)
    |> data_to_lvar_data(inner_state.portals[portal.portal_name])


    portal = Map.put(portal, :temp_data, new_data)

    inner_state
    |> put_in_p([:portals, portal.portal_name], portal)
  end

  defp build_temp_portal({:put, path, v}, _, data), do: put_in_p(data, path, v)
  defp build_temp_portal({:update, path, cb}, original_data, new_data) do
    original_v = get_in_p(original_data, path)
    new_v = get_in_p(new_data, path)
    put_in_p(new_data, path, cb.(original_v, new_v))
  end


  defp data_to_lvar_data(data, portal) do
    Sorcery.Query.from_tk_map(portal.query_module, portal.args, data)
  end


end
