defmodule Sorcery.Schema do
  @moduledoc """ 
  In sorcery, you must define your entity types as 'Schemas'


  ```elixir
  defmodule MyApp.Player do
    use Sorcery.Schema, fields: %{
      name: %{t: :string, min: 0, max: 45, default: "Nameless"},
      age: %{t: :integer, min: 0, max: 99, optional?: false},
    }
  end
  ```

  See the guide for a comprehensive table of all possible attributes for each :t.

  After you do the above setup, The MyApp.Player module will have some neat superpowers. Go take a look in iex.

  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @skip_sorcery false
      @fields Keyword.get(opts, :fields, %{})
      @meta Map.merge(
        Sorcery.Schema.meta_defaults(__MODULE__),
        Keyword.get(opts, :meta, %{})
      )
      @full_fields Enum.reduce(@fields, %{}, fn {k, f}, acc ->
        full = Sorcery.Schema.FieldType.new(f, @meta)
        Map.put(acc, k, full)
      end)

      @doc ~s"""
      Return the fields map, but with each one converted to a full struct.
      """
      def fields(), do: @full_fields

      @doc ~s"""
      Returns the metadata, exactly as you wrote it
      """
      def meta(), do: @meta


      @doc ~s"""
      A generator that returns a lazy stream of entities matching the schema.
      """
      def gen(body) when is_map(body), do: Sorcery.Schema.Generation.gen(@full_fields, body)
      def gen(n) when is_integer(n), do: Sorcery.Schema.Generation.gen(@full_fields, %{}) |> Enum.take(n)
      def gen(), do: Sorcery.Schema.Generation.gen(@full_fields, %{})
      def gen(body, n) when is_map(body) and is_integer(n), do: Sorcery.Schema.Generation.gen(@full_fields, body) |> Enum.take(n)


      @doc ~s"""
      A generator that returns a single entity matching the schema.
      """
      def gen_one(body \\ %{}), do: gen(body) |> Enum.take(1) |> List.first()


      def gen_cs(body \\ %{}) do
        gen_one(body)
        |> __MODULE__.sorcery_insert_cs()
      end

      @doc ~s"""
      Generate a ReturnedEntities with n entities. If they have foreign keys, it will generate dummy data for those as well.
      """
      def gen_re(count), do: Sorcery.Schema.Generation.gen_re(@full_fields, count)


      use Sorcery.Schema.EctoSchema, opts

    end
  end

  def meta_defaults(module), do: %{
    optional?: true,
    tk: Sorcery.Helpers.Names.mod_to_tk(module)
    #tk: Macro.underscore(module) |> String.split("/") |> List.last() |> String.to_atom()
  }
end
