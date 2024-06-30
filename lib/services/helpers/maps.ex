defmodule Sorcery.Helpers.Maps do
  @moduledoc false


  # {{{ from_struct/1
  @doc ~S"""
  The usual Map.from_struct/1 causes huge trouble because the __meta__ field contains a '#'. Tests break with EOF errors.

  ## Examples
      iex> diff = from_struct(%Sorcery.Portal.Diff{})
      iex> Map.get(diff, :__meta__)
      nil
  """
  def from_struct(strct) do
    Map.from_struct(strct)
    |> Map.delete(:__meta__)
  end
  # }}}


  # {{{ to_atom_keys/1
  @doc ~S"""
  Given a map, converts all string keys into atoms

  ## Examples
      iex> to_atom_keys(%{"a" => 1, b: 2, "c" => %{"foo" => "bar"}})
      %{a: 1, b: 2, c: %{foo: "bar"}}
  """
  def to_atom_keys(map) do
    Enum.reduce(map, %{}, fn 
      {sk, v}, acc when is_binary(sk) -> 
        k = String.to_existing_atom(sk)

        v = case v do
          m when is_map(m) -> to_atom_keys(m)
          v -> v
        end

        Map.put(acc, k, v)
      {k, m}, acc when is_map(m) -> Map.put(acc, k, to_atom_keys(m))
      {k, v}, acc -> Map.put(acc, k, v)
    end)
  end
  # }}}


  # {{{ to_string_keys/1
  @doc ~S"""
  Given a map, converts all string keys into atoms

  ## Examples
      iex> to_string_keys(%{a: 1, b: 2, c: %{foo: "bar"}})
      %{"a" => 1, "b" => 2, "c" => %{"foo" => "bar"}}
      iex> to_string_keys(%{a: 1, b: 2, c: %{foo: "bar"}}, 1)
      %{"a" => 1, "b" => 2, "c" => %{foo: "bar"}}
  """
  def to_string_keys(map, max_depth \\ -1, curr_depth \\ 0) do
    if max_depth == curr_depth do
      map
    else
      Enum.reduce(map, %{}, fn 
        {ak, v}, acc when is_atom(ak) -> 
          sk = "#{ak}"

          v = case v do
            m when is_map(m) -> to_string_keys(m, max_depth, curr_depth + 1)
            v -> v
          end

          Map.put(acc, sk, v)
        {k, m}, acc when is_map(m) -> Map.put(acc, k, to_string_keys(m, max_depth, curr_depth + 1))
        {k, v}, acc -> Map.put(acc, k, v)
      end)
    end
  end
  # }}}


  # {{{ get_in_p/2
  @doc ~S"""
  Safely does get_in, assuming nothing but maps all the way down.

  ## Examples
      iex> m = %{a: %{b: %{c: 5} } }
      iex> get_in_p(m, [:a, :b, :c])
      5
      iex> get_in_p(m, [:a, :b, :c, :d])
      nil
      iex> get_in_p(m, [:a, :b, :x])
      nil
      iex> get_in_p(m, [:x, :y, :z])
      nil
  """
  def get_in_p(other, li) when not is_map(other), do: get_in_p(%{}, li)
  def get_in_p(m, [hd]), do: Map.get(m, hd)
  def get_in_p(m, [hd | tl]) do
    Map.get(m, hd, %{})
    |> get_in_p(tl)
  end
  def get_in_p(_m, _li), do: nil
  # }}}


  # {{{ has_in_p/2
  @doc ~S"""
  Checks whether a value exists at the path

  ## Examples
      iex> m = %{a: %{b: %{c: 5} } }
      iex> has_in_p(m, [:a, :b, :c])
      true
      iex> has_in_p(m, [:a, :b, :x])
      false
      iex> has_in_p(m, [:x, :y, :z])
      false
  """
  def has_in_p(m, [hd]), do: Map.has_key?(m, hd)
  def has_in_p(m, [hd | tl]) do
    Map.get(m, hd, %{})
    |> has_in_p(tl)
  end
  # }}}


  # {{{ find_nil(m, path)
  @doc ~S"""
  Goes through a path, one step at a time, until it finds a key that doesn't exist in the map.

  ## Examples
      iex> find_nil(%{a: %{b: %{}} }, [:c])
      {:nil_at, [:c]}

      iex> find_nil(%{a: %{b: %{}} }, [:a])
      {:no_nil, []}

      iex> find_nil(%{a: %{b: %{}} }, [:a, :b])
      {:no_nil, []}

      iex> find_nil(%{a: %{b: %{}} }, [:a, :b, :c])
      {:nil_at, [:a, :b, :c]}

      iex> find_nil(%{a: %{b: %{}} }, [:a, :b, :c, :d])
      {:nil_at, [:a, :b, :c]}
  """
  def find_nil(m, path), do: find_nil(m, path, [])
  def find_nil(m, [hd | tl], solved_path) when is_map(m) do
    new_solved = solved_path ++ [hd]
    if Map.has_key?(m, hd) do
      find_nil(m[hd], tl, new_solved)
    else
      {:nil_at, new_solved}
    end
  end
  def find_nil(_m, [], _solved_path), do: {:no_nil, []}
  # }}}


  # {{{ put_in_p/3
  @doc ~S"""
  Like `mkdir -p`, but for elixir maps.
  Safely does put_in, assuming nothing but maps all the way down.

  ## Examples
      iex> put_in_p(%{}, [:a, :b], 5)
      %{a: %{b: 5}}
  """
  def put_in_p(m, [hd], value) do
    Map.put(m, hd, value)
  end
  def put_in_p(m, [hd | tl], value) do
    submap = Map.get(m, hd, %{})
             |> put_in_p(tl, value)
    Map.put(m, hd, submap)
  end

  # }}}


  # {{{ update_in_p/1
  @doc ~S"""
  Like `mkdir -p`, but for elixir maps.
  Safely does update_in, assuming nothing but maps all the way down.

  ## Examples
      iex> update_in_p(%{a: %{b: 5}}, [:a, :b], 0, &(&1 * &1))
      %{a: %{b: 25}}
      iex> update_in_p(%{a: %{b: 5}}, [:x, :c], 0, &(&1 * &1))
      %{a: %{b: 5}, x: %{c: 0}}
  """
  def update_in_p(m, [hd], default, value) do
    Map.update(m, hd, default, value)
  end
  def update_in_p(m, [hd | tl], default, value) do
    submap = Map.get(m, hd, %{})
             |> update_in_p(tl, default, value)
    Map.put(m, hd, submap)
  end

  # }}}


  # {{{ delete_in/1
  @doc ~S"""
  Deletes a key inside a map, at the given path. Returns the map.
  Even if the path doesn't exist.

  ## Examples
      iex> delete_in(%{a: %{b: 5}}, [:a, :b])
      %{a: %{}}
      iex> delete_in(%{a: %{b: 5}}, [:a, :x, :c])
      %{a: %{b: 5}}

  """
  def delete_in(m, [hd]) do
    Map.delete(m, hd)
  end
  def delete_in(m, [hd | tl]) do
    if Map.has_key?(m, hd) do
      submap = Map.get(m, hd, %{})
               |> delete_in(tl)
      Map.put(m, hd, submap)
    else
      m
    end
  end
  # }}}

  
  # {{{ deep_merge/1
  @doc ~S"""

  Like Map.merge, but better handling of depth.

  ## Examples
      iex> deep_merge(%{a: %{b: 5}}, %{a: %{c: 9}})
      %{a: %{b: 5, c: 9}}

  """
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

 
  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end
  

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end
  # }}}





end
