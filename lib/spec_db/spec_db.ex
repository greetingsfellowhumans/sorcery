defmodule Sorcery.SpecDb do
  @moduledoc """
  ## Introduction
  In Sorcery, we keep data sync'd across nodes. So it naturally follows that we should keep the metadata sync'd across codes.

  ## Schema module
  In a typical phoenix app, you might have a Player schema for a game.
  You can replace part, or all of that module with Sorcery. Observe:

  ```elixir
  defmodule MyApp.Player do
    require Sorcery.SpecDb

    @spec_table %{
      user_id: %{t: :id, require_update: false},
      name: %{t: :string, default: "Player", min: 3, max: 45},
      age: %{t: :integer, min: 0, max: 200, bump: true}
    }

    Sorcery.SpecDb.build_schema_module("player")

    # Alternately:
    #
    #  def spec_table, do: @spec_table
    #  Sorcery.SpecDb.build_ecto_schema(name)
    #  Sorcery.SpecDb.build_norm_schema()
    #  Sorcery.SpecDb.build_streamdata_generator()
    #  Sorcery.SpecDb.build_changesets()


  end
  ```

  ## Exploring the results
  What does this achieve? Well, I think the test module actually speaks for itself.
  Read the comments carefully

  ```elixir
  defmodule MyApp.PlayerTest do
    use ExUnit.Case
    use ExUnitProperties
    use Norm
    alias MyApp.Player


    test "build_schema macro" do
      # Builds the struct via Ecto.Schema
      assert Map.get(%Player{}, :name) == "Player"

      # Builds the Norm schema
      assert !valid?(%{name: "hello"}, Player.t())
      assert valid?(%Player{user_id: 1, age: 23, name: "hello"}, Player.t())
      assert valid?(%{user_id: 1, age: 23, name: "hello"}, Player.t())
    end


    property "Generates Players" do
      # First, we generate a player with random data that matches the spec_table
      # The map you pass into gen/1 will override any random values.
      check all player <- Player.gen(%{user_id: 24}) do
        assert valid?(player, Player.t())

        # We get a valid changeset
        cs = Player.sorcery_update(%Player{id: player.id}, player)
        assert cs.valid?


        # If we use numbers outside the min/max, using `bump: true` will set it the same min/max value.
        # Remember our spec_table included:
        # age: %{t: :integer, min: 0, max: 200, bump: true}

        player = Map.put(player, :age, 9999999)
        cs = Player.sorcery_update(%Player{id: player.id}, player)
        assert cs.changes.age == 200
        assert cs.valid?

        # Instead of causing an invalid changeset, it just 'bumped' it to the :max value.
      end
    end


  end
  ```

  ## The table_spec
  To see more about the options to pass into each field, see the types section.
  """

  @typedoc "Required. The type of this field"
  @type t :: :integer | :float | :boolean | :string | :trinary

  @typedoc "Default: true. Whether Norm should treat this as a required field. Does nothing if :default field is set."
  @type required :: boolean

  @typedoc "The default value if nothing else set."
  @type default :: any

  @typedoc "The lowest possible number, or string length"
  @type min :: integer | float

  @typedoc "The highest possible number, or string length"
  @type max :: integer | float

  @typedoc "Whether the value should be coerced to its min/max if beyond that range."
  @type bump :: boolean

  @typedoc "Whether this field should be cast inside sorcery_update/2"
  @type cast_update :: boolean
  
  @typedoc "Whether this field should be in validate_required inside sorcery_update/2"
  @type require_update :: boolean
  
  @typedoc "Whether this field should be cast inside sorcery_insert/2"
  @type cast_insert :: boolean
  
  @typedoc "Whether this field should be in validate_required inside sorcery_insert/2"
  @type require_insert :: boolean
  
  @typedoc "A list of possible options"
  @type one_of :: [any]

  @typedoc "If t: :list, then every item must be of this type"
  @type coll_of :: atom

  @typedoc "Sets the length of a list type."
  @type length :: integer


  @doc """
  ```
  # Injects this
  use Ecto.Schema

  schema "name" do
    field :fieldname, :type
  end
  
  # While passing in all the data from @spec_table
  ```
  """
  defmacro build_ecto_schema(name, opts \\ []) do
    quote do
      require Sorcery.SpecDb.EctoHelpers
      Sorcery.SpecDb.EctoHelpers.build_ecto_schema(unquote(name), @spec_table, unquote(opts))
    end
  end

  @doc """
  Adds the __MODULE__.t() function, for usage with Norm.
  """
  defmacro build_norm_schema() do
    quote do

      def t() do
        Sorcery.SpecDb.NormHelpers.build_schema(@spec_table)
      end

    end
  end
  defmacro build_norm_schema(name) do
    quote do

      def unquote(:"#{name}_t")() do
        Sorcery.SpecDb.NormHelpers.build_schema(@spec_table[unquote(name)].assigns)
      end

    end
  end

  @doc """
  Adds the __MODULE__.gen() function, for generating data in property based testing with StreamData
  """
  defmacro build_streamdata_generator() do
    quote do

      def gen(attrs \\ %{}) do
        Sorcery.SpecDb.SdHelpers.gen(@spec_table, attrs)
      end

    end
  end
  defmacro build_streamdata_generator(name) do
    quote do

      def unquote(:"#{name}_gen")(attrs \\ %{}) do
        Sorcery.SpecDb.SdHelpers.gen(@spec_table[unquote(name)].assigns, attrs)
      end

    end
  end


  @doc """
  Adds `sorcery_insert/2` and `sorcery_update/2`, based on the @spec_table
  """
  defmacro build_changesets() do
    quote do
      import Ecto.Changeset
      import Sorcery.SpecDb.CsHelpers

      def sorcery_insert(strct, attrs \\ %{}) do
        attrs = bump(@spec_table, attrs)
        strct
        |> cast(attrs, get_cast_insert(@spec_table))
        |> validate_required(get_require_insert(@spec_table))
        |> validate_min_max(@spec_table)
      end

      def sorcery_update(strct, attrs \\ %{}) do
        attrs = bump(@spec_table, attrs)
        cs =
          strct
          |> cast(attrs, get_cast_update(@spec_table))
          |> validate_required(get_require_update(@spec_table))
          |> validate_min_max(@spec_table)
      end


      defp validate_min_max(cs, table) do
        Enum.reduce(table, cs, fn {k, v}, acc ->
          t = case v.t do
            t when t in [:string, :binary, :list] -> :string
            t when t in [:integer, :int, :float] -> :number
            _ -> :ignore
          end

          acc
          |> validate_min(k, t, v)
          |> validate_max(k, t, v)
        end)
      end

      defp validate_min(cs, k, :number, %{min: min}), do: validate_number(cs, k, greater_than_or_equal_to: min)
      defp validate_min(cs, k, :string, %{min: min}), do: validate_length(cs, k, min: min)
      defp validate_min(cs, _, _, _), do: cs 
      defp validate_max(cs, k, :number, %{max: max}), do: validate_number(cs, k, less_than_or_equal_to: max)
      defp validate_max(cs, k, :string, %{max: max}), do: validate_length(cs, k, max: max)
      defp validate_max(cs, _, _, _), do: cs 


    end
  end


  @doc """
  ```elixir
  # Macro which automatically adds to your module:
  def spec_table, do: @spec_table
  Sorcery.SpecDb.build_ecto_schema(name)
  Sorcery.SpecDb.build_norm_schema()
  Sorcery.SpecDb.build_streamdata_generator()
  Sorcery.SpecDb.build_changesets()
  ```
  """
  defmacro build_schema_module(name, opts \\ []) do
    quote do
      def spec_table, do: @spec_table
      Sorcery.SpecDb.build_ecto_schema(unquote(name), unquote(opts))
      Sorcery.SpecDb.build_norm_schema()
      Sorcery.SpecDb.build_streamdata_generator()
      Sorcery.SpecDb.build_changesets()
    end
  end


  @doc """
  In any live_view, component, or live_component module, call:
  ```elixir
  # Start with @spec_table
  @spec_table %{

    # Each key is the name of a function that renders heex
    render: %{ ... },


    different_render: %{
      # Must include an assigns map. This is needed for generating and validating
      assigns: %{
        # And now it works like any other @spec_table. For example if the component only takes a user_id:
        user_id: %{t: :id, ...},
      }
    }
  }
  require Sorcery.SpecDb
  Sorcery.SpecDb.build_live_specs(:render)
  Sorcery.SpecDb.build_live_specs(:different_render)
  ```


  This will generate some useful functions in the module.

  ```elixir
    __MODULE__.gen(:render) 
  ```
  Will return a StreamData struct for generating a map of assigns.


  ```elixir
    __MODULE__.t(:render) 
  ```
  Will return a norm spec for validating the assigns
  """
  defmacro build_live_specs(name) do
    quote do
      def spec_table, do: @spec_table
      Sorcery.SpecDb.build_norm_schema(unquote(name))
      Sorcery.SpecDb.build_streamdata_generator(unquote(name))

    end
  end

end
