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

      @fields Keyword.get(opts, :fields, %{})
      @meta Map.merge(
        Sorcery.Schema.meta_defaults(__MODULE__),
        Keyword.get(opts, :meta, %{})
      )
      @full_fields Enum.reduce(@fields, %{}, fn {k, f}, acc ->
        full = Sorcery.Schema.FieldType.new(f)
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
      The Norm spec for this schema
      """
      def t() do
        if Code.ensure_loaded?(Norm) do
          Sorcery.Schema.Norm.build_spec(@full_fields)
        else
          raise "In order to use #{__MODULE__}.t/0, you must install the :norm library."
        end
      end


      @doc ~s"""
      A generator that returns a lazy stream of entities matching the schema.
      """
      def gen(), do: Sorcery.Schema.Generation.gen(@full_fields)


      @doc ~s"""
      A generator that returns a single entity matching the schema.
      """
      def gen_one(), do: gen() |> Enum.take(1) |> List.first()

      @doc ~s"""
      Generate a ReturnedEntities with n entities. If they have foreign keys, it will generate dummy data for those as well.
      """
      def gen_re(count), do: Sorcery.Schema.Generation.gen_re(@full_fields, count)


      ## And now for Ecto
      #if Code.ensure_loaded(Ecto.Schema) do
      #  use Ecto.Schema
      #  schema "foops" do
      #    field :name, :string
      #    field :age, :integer, default: 0
      #  end
      #end
      use Sorcery.Schema.EctoSchema, opts


    end
  end

  def meta_defaults(module), do: %{
    tk: Macro.underscore(module) |> String.split("/") |> List.last() |> String.to_atom()
  }
end
