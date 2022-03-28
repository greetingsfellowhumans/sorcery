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
              :list -> field k, {:array, d.coll_of}
              _ -> field k, t, kwli
            end
          end
        end
      end

    end
  end


end
