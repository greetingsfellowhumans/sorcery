defmodule Sorcery.Storage.GenserverAdapter.QueryTest do
  use ExUnit.Case
  alias Sorcery.Storage.GenserverAdapter.{Query, QueryMeta}

  @db1 %{
    user: %{
      1 => %{id: 1, name: "Aaron", likes: 5},
      2 => %{id: 2, name: "Not Aaron", likes: 500},
    },
    post: %{
      10 => %{id: 10, name: "Aaron", likes: 5, author_id: 1},
      20 => %{id: 20, name: "Not Aaron", likes: 500, author_id: 2},
    },
    comment: %{
      100 => %{id: 100, name: "Aaron", likes: 5, post_id: 20, author_id: 1},
      200 => %{id: 200, name: "Not Aaron", likes: 500, post_id: 10, author_id: 1},
      300 => %{id: 300, name: "Aaron", likes: 5, post_id: 20, author_id: 2},
      400 => %{id: 400, name: "Not Aaron", likes: 500, post_id: 10, author_id: 2},
    },
    location: %{
      1 => %{id: 1, location_number: 108492, name: "My Place"},
      2 => %{id: 2, location_number: 105105, name: "Next Place"},
      3 => %{id: 3, location_number: 103321, name: "My House"},
    },
    unit: %{
      10 => %{id: 10, location_number: 108492, unit_number: "101"},
      20 => %{id: 20, location_number: 108492, unit_number: "102"},
      30 => %{id: 30, location_number: 105105, unit_number: "1A"},
    },
    report: %{
      100 => %{id: 100, unit_id: 10, msg: "Some msg 1", user_id: 2},
      200 => %{id: 200, unit_id: 20, msg: "Some msg 2", user_id: 2},
      300 => %{id: 300, unit_id: 30, msg: "Some msg 3", user_id: 2},
      400 => %{id: 400, unit_id: 10, msg: "Some msg 4", user_id: 1},
    }
  }

  @portals [
    %{
      guards: [{:==, :id, 1}],
      id: "location:0.704432162.3150446594.192136",
      indices: %{id: MapSet.new([1]), location_number: MapSet.new([108492])},
      key: :location,
      phx_ref: "FtiWnFqZv5F99wEG",
      pid: 06990,
      resolved_guards: [{:==, :id, 1}],
      tk: :location
    },
    %{
      guards: [
        {:in, :location_number,
         {"location:0.704432162.3150446594.192136", :location_number}}
      ],
      id: "unit:0.704432162.3150446594.192141",
      indices: %{id: MapSet.new([1])},
      key: :unit,
      phx_ref: "FtiWnFqbROF99wFG",
      pid: 06990,
      resolved_guards: [{:in, :location_number, MapSet.new([108492])}],
      tk: :unit
    },
    %{
      guards: [
        {:==, :id, 1}
      ],
      id: "post:0.12948017.12049871.410927",
      indices: %{id: MapSet.new([1])},
      key: :post,
      pid: 12490,
      resolved_guards: [{:==, :id, 1}],
      tk: :post
    }
  ]

  @src %Sorcery.Src{
    args: %{unit_id: 10},
    changes_db: %{
      unit: %{
        10 => %{unit_number: "201"}
      }
    },
    deletes: [],
    interceptors: [],
    msg: %Sorcery.Msg{body: %{}, cb: &Sorcery.Msg.noop/0, flash: "", status: :ok},
    original_db: %{},
  }
  @state %{db: @db1}


  test "Build the QueryMeta" do
    qm = QueryMeta.new(@src, @state)
    assert qm.old_db.unit[10].unit_number == "101"
    assert qm.old_db.unit[10].id == 10
    assert qm.new_db.unit[10].unit_number == "201"
    assert qm.new_db.unit[10].id == 10
    assert qm.all_table_keys == MapSet.new([:unit])
    assert qm.all_entities == MapSet.new([{:unit, 10}])
  end

  test "Check Guard" do
    com100 = @db1.comment[100]
    assert !Query.entity_matches_clause?(com100, {:==, :id, 42})
    assert  Query.entity_matches_clause?(com100, {:==, :id, 100})
    assert  Query.entity_matches_clause?(com100, {:<, :likes, 100})
    assert  Query.entity_matches_clause?(com100, {:in, :likes, MapSet.new([1, 2, 3, 5])})
    assert !Query.entity_matches_clause?(com100, {:in, :likes, MapSet.new([1, 2, 3])})

    assert Query.portal_watching_entity?(%{resolved_guards: [
      {:==, :id, 100},
      {:<, :likes, 10}
    ]}, com100)

    assert !Query.portal_watching_entity?(%{resolved_guards: [
      {:==, :id, 100},
      {:>, :likes, 10}
    ]}, com100)

    assert Query.portal_watching_entity?(%{resolved_guards: [
      {:or, [
        {:==, :id, 100},
        {:>, :likes, 10}
      ]}
    ]}, com100)

    assert Query.portal_watching_entity?(%{resolved_guards: [
      {:or, [
        {:and, [
          {:==, :id, 100},
          {:==, :likes, 50},
        ]},
        {:and, [
          {:==, :id, 100},
          {:<, :likes, 50},
        ]},
      ]}
    ]}, com100)

  end


  test "Solve Portal" do
    qm = QueryMeta.new(@src, @state)
    [loc_portal, unit_portal, post_portal] = @portals
    assert %{} == Query.solve_portal(loc_portal, qm)

    unit_table = %{unit: %{10 => %{id: 10, location_number: 108492, unit_number: "201"}}}

    assert unit_table == Query.solve_portal(unit_portal, qm)
    assert %{} == Query.solve_portal(post_portal, qm)
    assert unit_table == Query.solve_portals(@portals, qm)


    assert false == Query.affects_portal?(post_portal, qm)
    assert true == Query.affects_portal?(unit_portal, qm)

    pids = Query.affected_pids(@portals, qm)
    assert [6990] == pids
  end


  test "resolve portals" do
    portals = Query.resolve_portal(@portals, @state)
    [_loc_portal, unit_portal, _post_portal] = portals
    assert unit_portal.guards == [
      {:in, :location_number, {"location:0.704432162.3150446594.192136", :location_number}}
    ]
    assert unit_portal.resolved_guards == [{:in, :location_number, MapSet.new([108492])}]
  end



end
