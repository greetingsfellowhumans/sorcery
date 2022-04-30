defmodule Sorcery.SpecDb.EctoHelpers do
  @moduledoc false


  defmacro build_ecto_schema(name, spec_table, opts \\ []) do
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
                  li when is_list(li) ->
                    hd = List.first(li)
                    cond do
                      is_binary(hd) -> :string
                      is_integer(hd) -> :integer
                      is_float(hd) -> :float
                      is_atom(hd) -> :atom
                      is_boolean(hd) -> :boolean
                    end
                  other -> other
                end
                field k, {:array, inner_t}
              _ -> field k, t, kwli
            end
          end
        end

        unless Keyword.get(unquote(opts), :timestamps) == false do
          timestamps()
        end

      end

    end
  end


end
