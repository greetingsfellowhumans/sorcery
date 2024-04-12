defmodule Sorcery.Schema.Norm do
  @moduledoc false
  @comment """
  This module is for converting a Sorcery.Schema fields map into a Norm spec.
  
  Words to keep in mind:
  Schema = The entity type. Has many Fields inside it.
  Field = This is a struct like FieldType.Integer or FieldType.String
  attr = The keys inside a field struct
  val = Whatever the entity is trying to use for a given field
  """
  use Norm
  import Sorcery.Specs
  alias Sorcery.Schema.FieldType, as: FT
  
  def build_spec(full_fields) do
    spec_map = Enum.reduce(full_fields, %{}, fn {k, field_struct}, acc ->
      Map.put(acc, k, struct_to_spec(field_struct))
    end)
    required = find_required(full_fields)
    selection(schema(spec_map), required)
  end


  defp find_required(full_fields) do
    full_fields
    |> Enum.filter(fn
      {k, %{optional?: false}} -> true
      _ -> false
    end)
    |> Enum.map(fn {k, _} -> k end)
  end

  defp solves_field?(field, v) do
    ft = field.__struct__

    field
    |> Map.from_struct()
    |> Enum.all?(fn {attr_k, attr_v} -> ft.is_valid?(attr_k, attr_v, v) end)
  end


  defp struct_to_spec(field_struct) do
    base_spec = field_struct.__struct__.base_norm_spec()
    case field_struct do
      optional?: false -> spec(base_spec.() and fn val -> solves_field?(field_struct, val) end)

      _ -> 
        one_of([
          nil?(),
          spec(base_spec.() and fn val -> solves_field?(field_struct, val) end)
        ])
    end
  end

end
