defmodule Sorcery.SpecDb do
  @moduledoc """
  ## SpecDb
  In Sorcery, we keep data sync'd across nodes. So it naturally follows that we should keep the metadata sync'd across codes.

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

  What does this achieve? Well, I think the test module actually speaks for itself.
  Read the comments carefully

  ```elixir
  defmodule MyApp.PlayerTest do
    use ExUnit.Case
    use ExUnitProperties
    use Norm
    alias MyApp.Player


    test "build_schema macro" do
      # Builds the struct via Ecto
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
        # Remember our spec_table said age was min: 0, max: 200

        player = Map.put(player, :age, 9999999)
        cs = Player.sorcery_update(%Player{id: player.id}, player)
        assert cs.changes.age == 200
        assert cs.valid?

        # Instead of causing an invalid changeset, it just 'bumped' it to the :max value.
      end
    end


  end
  ```
  """

  @typedoc "Required. The type of this field"
  @type t :: :integer | :float | :boolean | :string

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
  


  @doc """
  Will inject the following:
  ```
  use Ecto.Schema

  schema "name" do
    field :fieldname, :type
  end
  ```
  passing in all the data from @spec_table
  """
  defmacro build_ecto_schema(name) do
    quote do
      require Sorcery.SpecDb.EctoHelpers
      Sorcery.SpecDb.EctoHelpers.build_ecto_schema(unquote(name), @spec_table)
    end
  end

  defmacro build_norm_schema() do
    quote do

      def t() do
        Sorcery.SpecDb.NormHelpers.build_schema(@spec_table)
      end

    end
  end

  defmacro build_streamdata_generator() do
    quote do

      def gen(attrs \\ %{}) do
        Sorcery.SpecDb.SdHelpers.gen(@spec_table, attrs)
      end

    end
  end


  defmacro build_changesets() do
    quote do
      import Ecto.Changeset
      import Sorcery.SpecDb.CsHelpers

      def sorcery_insert(strct, attrs \\ %{}) do
        attrs = bump(@spec_table, attrs)
        strct
        |> cast(attrs, get_cast_insert(@spec_table))
        |> validate_required(get_require_insert(@spec_table))
      end

      def sorcery_update(strct, attrs \\ %{}) do
        attrs = bump(@spec_table, attrs)
        strct
        |> cast(attrs, get_cast_update(@spec_table))
        |> validate_required(get_require_update(@spec_table))
      end

    end
  end


  defmacro build_schema_module(name) do
    quote do
      def spec_table, do: @spec_table
      Sorcery.SpecDb.build_ecto_schema(unquote(name))
      Sorcery.SpecDb.build_norm_schema()
      Sorcery.SpecDb.build_streamdata_generator()
      Sorcery.SpecDb.build_changesets()
    end
  end

 # @doc """
 # When used, dispatch to the appropriate controller/view/etc.
 # """
 # defmacro __using__(which) when is_atom(which) do
 #   apply(__MODULE__, which, [])
 # end

end
