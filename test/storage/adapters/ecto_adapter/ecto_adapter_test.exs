defmodule Sorcery.Storage.EctoAdapterTest do
  use ExUnit.Case
  alias Sorcery.Storage.Adapters.Ecto.Parsing

  @src  %Sorcery.Src{
    changes_db: %{
      service_call: %{
        "$sorcery:service_call:1" => %{
          "location_number" => 108429,
        }
      },
      unit: %{
        "$sorcery:unit:1" => %{
          location_id: "$sorcery:service_call:1",
          unit_number: "1234"
        }
      },
      foo: %{
        5 => %{id: 5, name: "FOOOOOO"}
      }
    },
  }

  test "Fill out inserts" do
    src = Parsing.mv_changes_inserts(@src)
    assert %Sorcery.Src{
      inserts: %{
        service_call: %{
          "$sorcery:service_call:1" => %{
            "location_number" => 108429,
          }
        },
        unit: %{
          "$sorcery:unit:1" => %{
            location_id: "$sorcery:service_call:1",
            unit_number: "1234"
          }
        },
      },
      changes_db: %{
        service_call: %{},
        unit: %{},
        foo: %{
          5 => %{id: 5, name: "FOOOOOO"}
        }
      },
    } == src

    ins_li = Parsing.list_inserts_deps(src)
    assert [
      {:unit, "$sorcery:unit:1", ["$sorcery:service_call:1"]},
      {:service_call, "$sorcery:service_call:1", []},
    ] == ins_li
    
    ins_li = Parsing.inserts_id_order(ins_li)
    assert ["$sorcery:service_call:1", "$sorcery:unit:1"] == ins_li

    ord = Parsing.get_ordered_inserts(src)
    assert [
      {:service_call, "$sorcery:service_call:1", %{"location_number" => 108429}},
      {:unit, "$sorcery:unit:1", %{
              location_id: "$sorcery:service_call:1",
        unit_number: "1234"}}
    ] == ord
    
  end
  
end
