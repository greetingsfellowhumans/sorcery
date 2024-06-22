defmodule Src.Schemas.Types do
  use Sorcery.Schema, fields: %{
    bool_mandatory: %{t: :boolean, optional?: false},
    bool_optional: %{t: :boolean, optional?: true},
    int_mandatory: %{t: :integer, optional?: false, min: 0, max: 10},
    int_optional: %{t: :integer, optional?: true, min: -10, max: 10},
    float_mandatory: %{t: :float, optional?: false, min: 0.0, max: 10.0},
    float_optional: %{t: :float, optional?: true, min: -10.0, max: 10.0},
    string_mandatory: %{t: :string, optional?: false, min: 10, max: 20},
    string_optional: %{t: :string, optional?: true, min: 10, max: 20},
    list_mandatory: %{t: :list, coll_of: :integer, min: 10, max: 20},
    list_optional:  %{t: :list, coll_of: :string, optional?: true,  min: 10, max: 20},
    list_inner: %{t: :list, coll_of: :string, inner: %{min: 15, max: 25}, min: 5, max: 10},
    map_mandatory: %{t: :map, optional?: false},
    map_optional: %{t: :map, optional?: true},
  }
end
