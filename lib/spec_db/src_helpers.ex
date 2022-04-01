defmodule Sorcery.SpecDb.SrcHelpers do
  @moduledoc """
  Generates and types a %Src{} that matches the given @src_table. Makes working with interceptors much easier.

  ```elixir
  defmodule MyInterceptor do

    @src_table %{
      args: %{
        dog_id: %{t: :id, placeholder: "$sorcery:dog:1"},
        kennel_id: %{t: :id, placeholder: "$sorcery:kennel:1"},
      },
      db: %{
        dog: %{
          "$sorcery:dog:1" => {Dog, %{kennel_id: "$sorcery:kennel:1"}}
        },
        kennel: %{
          "$sorcery:kennel:1" => {Kennel, %{name: "Test Kennel"}}
        },
      }
    }

    require Sorcery.SpecDb.SrcHelpers
    Sorcery.SpecDb.SrcHelpers.build_interceptor()

  end

  # This assumes the Dog and Kennel modules both, also, implement t/0 and gen/1
  # Now we can call:
  iex> [src] = MyInterceptor.gen() |> Enum.take(1)
  iex> Norm.valid?(src, MyInterceptor.t())
  true
  ```

  """

  use Norm
  alias Sorcery.SpecDb.{NormHelpers}

  def any?(), do: spec(fn _ -> true end)

  @doc """
  Extracts placeholder ids from @src_table, and finds all the paths that reference each placeholder
  """
  def get_placeholder_data(src_table) do
    acc = %{}
    acc = Enum.reduce(src_table.args, acc, fn 
      {k, %{t: :id, placeholder: "$sorcery:" <> _ = id}}, acc -> 
        Map.update(acc, id, %{arg_paths: [k], db_paths: []}, fn %{arg_paths: arg_paths} = old -> 
          Map.put(old, :arg_paths, [k | arg_paths])
        end)
      {_k, _v}, acc -> acc
    end)
    acc = Enum.reduce(src_table.db, acc, fn {tk, table}, acc ->
      Enum.reduce(table, acc, fn {id, {_mod, entity}}, acc ->

        # Get any placeholder ids directly at db.tk.id level
        acc = case id do
          "$sorcery:" <> _ -> 
            Map.update(acc, id, %{arg_paths: [], db_paths: [[tk]]}, fn %{db_paths: db_paths} = old -> 
              Map.put(old, :db_paths, [[tk] | db_paths]) 
            end)
          _ -> acc
        end

        # Now get placeholders in arbitrary fields
        acc = Enum.reduce(entity, acc, fn
          {k, "$sorcery:" <> _ = phid}, acc ->
            Map.update(acc, phid, %{arg_paths: [], db_paths: [[tk, id, k]]}, fn %{db_paths: db_paths} = old ->
              Map.put(old, :db_paths, [[tk, id, k] | db_paths])
            end)
          _, acc -> acc
        end)
        acc
      end)
    end)
    acc
  end


  @doc """
  For each placeholder, generate a unique integer for it
  """
  def realize_placeholders(placeholder_data) do
    n = placeholder_data |> Map.keys() |> Enum.count()
    ids = Enum.take(StreamData.uniq_list_of(StreamData.integer(0..99999), length: 1), n)
    Enum.with_index(placeholder_data)
    |> Enum.reduce(placeholder_data, fn {{phid, _data}, idx}, acc ->
      [id] = Enum.at(ids, idx)
      put_in(acc, [phid, :real], id)
    end)
  end

  defmacro build_interceptor() do
    quote do

      def src_table, do: @src_table

      def gen() do
        placeholders = Sorcery.SpecDb.SrcHelpers.get_placeholder_data(@src_table)
                       |> Sorcery.SpecDb.SrcHelpers.realize_placeholders()
        args_map = Sorcery.SpecDb.SrcHelpers.gen_args(@src_table, placeholders) |> StreamData.fixed_map()
        db_map = Sorcery.SpecDb.SrcHelpers.gen_db(@src_table, placeholders) |> StreamData.fixed_map()
        StreamData.fixed_map(%{args: args_map, original_db: db_map})
        |> StreamData.map(fn m -> struct(Sorcery.Src, m) end)
      end

      def t() do
        # Dear Future, I am so sorry.
        arg_schema = NormHelpers.build_schema(Map.get(@src_table, :args, %{}))
        db_schema = Map.get(@src_table, :db, %{})
                    |> Enum.reduce(%{}, fn {tk, table}, acc ->
                      table_schema = spec(is_map() and fn entities ->
                        Enum.all?(table, fn {_id, {mod, _args}} ->
                          Enum.any?(entities, fn {_, entity} ->
                            Norm.valid?(entity, mod.t())
                          end)
                        end)
                      end)

                      Map.put(acc, tk, table_schema)
                    end)
                    |> Norm.schema()
                    |> selection(Map.keys(Map.get(@src_table, :db, %{})))

        schema(%{
          args: arg_schema,
          original_db: db_schema
        })
      end
    end
  end



  def gen_args(src_table, placeholders) do
    arg_spec = Map.get(src_table, :args, %{})
    Enum.reduce(arg_spec, %{}, fn 
      {k, %{t: :id, placeholder: "$sorcery:" <> _ = phid}}, acc ->
        id = Map.get(placeholders, phid).real
        Map.put(acc, k, StreamData.constant(id))

      {k, v}, acc ->
        Map.put(acc, k, StreamData.constant(v))
    end)
  end

  def gen_db(src_table, placeholders) do
    db_spec = Map.get(src_table, :db, %{})
    Enum.reduce(db_spec, %{}, fn {tk, table}, acc -> 
      new_table = gen_table(table, placeholders)
      Map.put(acc, tk, new_table)
    end)
  end

  def gen_table(table, placeholders) do
    Enum.reduce(table, %{}, fn 
      {"$sorcery:" <> _ = phid, {mod, args}}, acc ->
        id = Map.get(placeholders, phid).real
        args = Map.put(args, :id, id)
               |> realize_args(placeholders)
        entity = mod.gen(args)
        Map.put(acc, id, entity)
      {id, {mod, args}}, acc ->
        args = realize_args(args, placeholders)
        entity = mod.gen(args)
        Map.put(acc, id, entity)
    end)
    |> StreamData.fixed_map()
  end

  def realize_args(args, placeholders) do
    Enum.reduce(args, %{}, fn
      {k, "$sorcery:" <> _ = phid}, acc ->
        id = Map.get(placeholders, phid).real
        Map.put(acc, k, id)
      {k, v}, acc -> Map.put(acc, k, v)
    end)
  end

end

