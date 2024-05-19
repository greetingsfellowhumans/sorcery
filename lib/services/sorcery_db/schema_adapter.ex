defmodule Sorcery.SorceryDb.SchemaAdapter do
  @moduledoc false

  # Take: MyApp.Sorcery.Schemas.Player
  # Return: [:id, :name, :age, ...]
  def get_attrs_list(schema_mod) do
    attrs = schema_mod.fields()
            |> Map.keys()
            |> Enum.sort()
    [:id | attrs] 
    |> Enum.uniq()
  end


  def get_variable_attrs_list(li) when is_list(li) do
    li = Enum.with_index(li)

    Enum.map(li, fn {_, i} -> String.to_atom("$#{i + 1}") end)
    #|> List.to_tuple()
  end
  def get_variable_attrs_list(schema_mod), do: schema_mod |> get_attrs_list |> get_variable_attrs_list()


  # Take: MyApp.Sorcery
  # Return: %{player: [:id, :name, ...], ...}
  def tk_attrs_map(schemas) do
    schemas
    |> Enum.reduce(%{}, fn {tk, schema_mod}, acc ->
      Map.put(acc, tk, get_attrs_list(schema_mod))
    end)
  end


  # Take: "/schemas/player.ex",  MyApp.Sorcery.Schemas
  # Return: {:player, MyApp.Sorcery.Schemas.Player}
  def parse_schema_module(filename, root_mod) do
    [name | _] = String.split(filename, ".")
    tk = String.to_atom(name)
    mod_suffix = Macro.camelize(name)

    full_mod = Module.concat([root_mod, mod_suffix])
    {tk, full_mod}
  end

  def attr_to_pos(attrs_map, tk, attr) do
    attrs = attrs_map[tk]
    i = Enum.find_index(attrs, &(&1 == attr))
    String.to_atom("$#{i + 1}")
  end


end
