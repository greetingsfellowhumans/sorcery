defmodule Sorcery.SpecDb.EctoHelpers do
  @moduledoc false


  defmacro build_ecto_schema(name, spec_table) do
    quote do
      use Ecto.Schema

      schema unquote(name) do
        for {k, %{t: t} = d } <- unquote(spec_table) do
          unless Map.get(d, :ignore) do
            kwli = Map.to_list(d)
            case t do
              :list -> 
                inner_t = case d.coll_of do
                  :trinary -> :boolean
                  other -> other
                end
                field k, {:array, inner_t}
              _ -> field k, t, kwli
            end
          end
        end
      end

    end
  end


end
