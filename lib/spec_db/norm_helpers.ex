defmodule Sorcery.SpecDb.NormHelpers do
  _status = :wip

  @moduledoc """
  [] - Create test/domain/Sorcery.SpecDb.NormHelpers.exs
  [] - Write public fn heads (fill them out later)
  [] - Complete all docs
  [] - Complete all checkboxes, commit, and push..
  """

  use Norm

  @doc """
  Replaces Norm.spec. Expects a map that might contain (required: false)
  Defaults to required.
  If not required, then allow spec(is_nil)
  """
  defmacro opt(attrs, clause) do
      quote do
        if Map.get(unquote(attrs), :required) == false do
          spec(is_nil() or unquote(clause))
        else
          spec(unquote(clause))
        end
      end
  end

  def required_keys(m) do
    Enum.reduce(m, [], fn {k, attrs}, acc ->
      case attrs do
        %{required: false} -> acc
        _ -> [k | acc]
      end
    end)
  end

  def build_schema(m) do
    schema(Enum.reduce(m, %{}, fn {k, attr}, acc ->
      v = case attr do
        #%{put: p} -> spec(fn s -> s == p end)
        %{put: p} -> opt(attr, fn s -> s == p end)
        %{one_of: li} -> one_of(Enum.map(li, fn i ->
          opt(attr, fn value -> i == value end)
        end))
        %{t: :instance, mod: mod} -> mod.t()
        %{t: :list, coll_of: t, length: l} -> coll_of(get_t_spec(t, attr), min_count: l, max_count: l)
        %{t: :list, coll_of: t} -> coll_of(get_t_spec(t, attr))
        %{t: :integer} -> get_t_spec(:integer, attr)
        %{t: :id} -> get_t_spec(:id, attr)
        %{t: :boolean} -> get_t_spec(:boolean, attr)
        %{t: :string} -> get_t_spec(:string, attr)
        %{t: :float} -> get_t_spec(:float, attr)
        %{t: :atom} -> get_t_spec(:atom, attr)
        %{t: :portals} -> get_t_spec(:portals, attr)
      end
      Map.put(acc, k, v)
    end))
    |> selection(required_keys(m))
  end


  def get_t_spec(:id, attrs), do: one_of([
    opt(attrs, is_integer() and fn i -> i >= 1 end),
    opt(attrs, is_binary() and fn
      "$sorcery:" <> _ -> true
      _s -> false
    end)
  ])

  
  def get_t_spec(:portals, %{tables: tables}) do
    Enum.reduce(tables, %{}, fn {tk, %{mod: mod, bodies: bodies}}, portals_acc ->
      table_schema = Enum.reduce(bodies, %{}, fn args, table_acc ->
        Map.put(table_acc, args[:id], mod.t())
      end) |> schema() |> selection()
      Map.put(portals_acc, tk, table_schema)
    end)
    |> schema() 
    |> selection()
  end

  def get_t_spec(:integer, %{min: min, max: max} = attr), do: opt(attr, is_integer() and fn i -> i in min..max end)
  def get_t_spec(:integer, %{min: min} = attr), do: opt(attr, is_integer() and fn i -> i >= min end)
  def get_t_spec(:integer, %{max: max} = attr), do: opt(attr, is_integer() and fn i -> i <= max end)
  def get_t_spec(:integer, attr), do: opt(attr, is_integer())

  def get_t_spec(:float, %{min: min, max: max} = attr), do: opt(attr, is_float() and fn i -> i >= min and i <= max end)
  def get_t_spec(:float, %{min: min} = attr), do: opt(attr, is_float() and fn i -> i >= min end)
  def get_t_spec(:float, %{max: max} = attr), do: opt(attr, is_float() and fn i -> i <= max end)
  def get_t_spec(:float, attr), do: opt(attr, is_float())

  def get_t_spec(:string, %{min: min, max: max} = attr), do: opt(attr, is_binary() and fn i -> String.length(i) in min..max end)
  def get_t_spec(:string, %{min: min} = attr), do: opt(attr, is_binary() and fn i -> String.length(i) >= min end)
  def get_t_spec(:string, %{max: max} = attr), do: opt(attr, is_binary() and fn i -> String.length(i) <= max end)
  def get_t_spec(:string, attr), do: opt(attr, is_binary())


  def get_t_spec(:boolean, attr), do: opt(attr, is_boolean())
  def get_t_spec(:trinary, _attr), do: one_of([true, false, nil])
  def get_t_spec(:atom, attr), do: opt(attr, is_atom())

  def get_t_spec(li, attr) when is_list(li) do
    opt(attr, fn item -> item in li end)
  end


end
