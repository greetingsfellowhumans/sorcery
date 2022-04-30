defmodule Dog do
  require Sorcery.SpecDb

  @spec_table %{
    # Misc
    name: %{t: :string, g: :misc, default: "pup1", min: 3, max: 45},
    age:  %{t: :integer, g: :misc, default: 0, min: 0, max: 32000},
    walk_id: %{t: :id, g: :misc},
  }

  Sorcery.SpecDb.build_schema_module("dog")
end
defmodule Kennel do
  require Sorcery.SpecDb

  @spec_table %{
    # Misc
    name: %{t: :string, g: :misc, default: "My Kennel", min: 3, max: 45},
  }

  Sorcery.SpecDb.build_schema_module("kennel")
end
defmodule Walk do
  require Sorcery.SpecDb

  @spec_table %{
    # Misc
    name: %{t: :string, g: :misc, default: "Walk", min: 3, max: 45},
    kennel_id:  %{t: :id, g: :misc},
  }

  Sorcery.SpecDb.build_schema_module("walk")
end


defmodule Interceptor do
  alias Sorcery.Src
  #require Sorcery.SpecDb.SrcHelpers
  use Norm

  @moduledoc """
  This interceptor simply moves a dog to a new kennel. Simple, right?

  But when I test it, I want to be able to call Interceptor.gen() and get a Src that works.

  I also want to put in a contract that is simple and automatic.
  """

  @src_table %{
    args: %{
      dog_id: %{t: :id, placeholder: "$sorcery:dog:1"},
      kennel_id: %{t: :id, placeholder: "$sorcery:kennel:1"},
      sex: %{t: :string, one_of: ["male", "female"]}
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

  use Sorcery.SpecDb.SrcHelpers
  #Sorcery.SpecDb.SrcHelpers.build_interceptor()


  def intercept(src) do
    Src.put_in(src, [:dog, src.args.dog_id, :kennel_id], src.args.kennel_id)
  end

end


defmodule Sorcery.SpecDb.SrcHelperTest do
  use ExUnit.Case, async: true 
  use ExUnitProperties
  use Norm

  @valid_arg %Sorcery.Src{
    args: %{dog_id: 25, kennel_id: 1002, sex: "male"},
    original_db: %{
      dog: %{
        25 => %{id: 25, name: "asdf", age: 100, walk_id: 1002}, # This is the target
        1 => %{id: 1, name: "asdf", age: 100, walk_id: 92835},
        2 => %{id: 2, name: "asdf", age: 100, walk_id: 92835},
        3 => %{id: 3, name: "asdf", age: 100, walk_id: 92835},
        4 => %{id: 4, name: "asdf", age: 100, walk_id: 92835},
        15 => %{id: 15, name: "asdf", age: 100, walk_id: 92835},
      },
      walk: %{
        1002 => %{id: 1002, name: "asdf", kennel_id: 1002}, # This is the target
        1 => %{id: 1, name: "asdf",   kennel_id: 92835},
        2 => %{id: 2, name: "asdf",   kennel_id: 92835},
        3 => %{id: 3, name: "asdf",   kennel_id: 92835},
        4 => %{id: 4, name: "asdf",   kennel_id: 92835},
        15 => %{id: 15, name: "asdf", kennel_id: 92835},
      },
      kennel: %{
        25 => %{id: 25, name: "asdf"},
        1 => %{id: 1, name: "asdf"},
        2 => %{id: 2, name: "asdf"},
        3 => %{id: 3, name: "asdf"},
        4 => %{id: 4, name: "asdf"},
        15 => %{id: 15, name: "asdf"},
      },
    }
  }
  @invalid_arg %Sorcery.Src{
    args: %{dog_id: 25, kennel_id: 1002, sex: :male},
    original_db: %{}
  }

  test "Validates a schema" do
    assert valid?(@valid_arg, Interceptor.t())
    assert !valid?(@invalid_arg, Interceptor.t())
  end

  test "Get placeholders" do
    tab = Interceptor.src_table()
    placeholders = Sorcery.SpecDb.SrcHelpers.get_placeholder_data(tab)
    expected = %{
      "$sorcery:dog:1" => %{arg_paths: [:dog_id], db_paths: [ [:dog] ]},
      "$sorcery:kennel:1" => %{
        arg_paths: [:kennel_id], 
        db_paths: [ [:kennel], [:dog, "$sorcery:dog:1", :kennel_id] ]},
    }
    assert expected == placeholders

    placeholders = Sorcery.SpecDb.SrcHelpers.realize_placeholders(placeholders)
    dog1id = placeholders["$sorcery:dog:1"].real
    assert is_integer(dog1id)
  end

  test "Generate a Src" do
    [src] = Interceptor.gen() |> Enum.take(1)
    assert is_struct(src, Sorcery.Src)

    dog = src.original_db.dog[src.args.dog_id]
    assert Norm.valid?(dog, Dog.t())

    kennel = src.original_db.kennel[src.args.kennel_id]
    assert Norm.valid?(kennel, Kennel.t())

    assert dog.kennel_id == kennel.id

    assert Norm.valid?(src, Interceptor.t())
  end


end
