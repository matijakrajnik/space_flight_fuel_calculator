defmodule SpaceFlightFuelCalculator.FlightTest do
  use ExUnit.Case, async: true

  alias SpaceFlightFuelCalculator.Flight
  alias SpaceFlightFuelCalculator.Flight.Params

  describe "calculate_fuel/1" do
    test "calculates fuel for Apollo 11 mission using Params struct" do
      params = %Params{
        mass: 28801,
        flight_path: [
          %Params.Step{action: :launch, waypoint: :earth},
          %Params.Step{action: :land, waypoint: :moon},
          %Params.Step{action: :launch, waypoint: :moon},
          %Params.Step{action: :land, waypoint: :earth}
        ]
      }

      assert Flight.calculate_fuel(params) == {:ok, 51898}
    end

    test "returns zero fuel for empty flight path" do
      params = %Params{mass: 28801, flight_path: []}

      assert Flight.calculate_fuel(params) == {:ok, 0}
    end

    test "returns error for invalid params" do
      assert Flight.calculate_fuel("not a params struct") == {:error, :invalid_params}
    end
  end

  describe "add_step/3" do
    test "adds step to empty flight path" do
      params = %Params{}
      result = Flight.add_step(params, :launch, :earth)

      assert %Params{flight_path: [%Params.Step{action: :launch, waypoint: :earth}]} == result
    end

    test "appends step to existing flight path" do
      params = %Params{flight_path: [%Params.Step{action: :launch, waypoint: :earth}]}
      result = Flight.add_step(params, :land, :moon)

      assert %Params{
               flight_path: [
                 %Params.Step{action: :launch, waypoint: :earth},
                 %Params.Step{action: :land, waypoint: :moon}
               ]
             } == result
    end

    test "preserves order when adding multiple steps" do
      result =
        %Params{}
        |> Flight.add_step(:launch, :earth)
        |> Flight.add_step(:land, :moon)
        |> Flight.add_step(:launch, :moon)
        |> Flight.add_step(:land, :earth)

      assert %Params{
               flight_path: [
                 %Params.Step{action: :launch, waypoint: :earth},
                 %Params.Step{action: :land, waypoint: :moon},
                 %Params.Step{action: :launch, waypoint: :moon},
                 %Params.Step{action: :land, waypoint: :earth}
               ]
             } == result
    end
  end

  describe "remove_step/2" do
    test "removes step at given index" do
      params = %Params{
        flight_path: [
          %Params.Step{action: :launch, waypoint: :earth},
          %Params.Step{action: :land, waypoint: :moon}
        ]
      }

      result = Flight.remove_step(params, 0)

      assert %Params{flight_path: [%Params.Step{action: :land, waypoint: :moon}]} == result
    end

    test "removes last step" do
      params = %Params{
        flight_path: [
          %Params.Step{action: :launch, waypoint: :earth},
          %Params.Step{action: :land, waypoint: :moon}
        ]
      }

      result = Flight.remove_step(params, 1)

      assert %Params{flight_path: [%Params.Step{action: :launch, waypoint: :earth}]} == result
    end

    test "returns unchanged params for out of bounds index" do
      params = %Params{flight_path: [%Params.Step{action: :launch, waypoint: :earth}]}
      result = Flight.remove_step(params, 5)

      assert %Params{flight_path: [%Params.Step{action: :launch, waypoint: :earth}]} == result
    end

    test "returns error for non-integer index" do
      params = %Params{}
      assert Flight.remove_step(params, "0") == {:error, :invalid_index}
      assert Flight.remove_step(params, nil) == {:error, :invalid_index}
    end
  end

  describe "clear_flight_path/1" do
    test "clears existing flight path" do
      params = %Params{
        mass: 28801,
        flight_path: [
          %Params.Step{action: :launch, waypoint: :earth},
          %Params.Step{action: :land, waypoint: :moon}
        ]
      }

      result = Flight.clear_flight_path(params)

      assert result.flight_path == []
      assert result.mass == 28801
    end
  end

  describe "to_waypoints/1" do
    test "extracts waypoints from full round trip" do
      params = %Params{
        flight_path: [
          %Params.Step{action: :launch, waypoint: :earth},
          %Params.Step{action: :land, waypoint: :moon},
          %Params.Step{action: :launch, waypoint: :moon},
          %Params.Step{action: :land, waypoint: :earth}
        ]
      }

      assert Flight.to_waypoints(params) == [:earth, :moon, :earth]
    end

    test "extracts waypoints from simple one-way trip" do
      params = %Params{
        flight_path: [
          %Params.Step{action: :launch, waypoint: :earth},
          %Params.Step{action: :land, waypoint: :mars}
        ]
      }

      assert Flight.to_waypoints(params) == [:earth, :mars]
    end

    test "extracts waypoints from multi-stop journey" do
      params = %Params{
        flight_path: [
          %Params.Step{action: :launch, waypoint: :earth},
          %Params.Step{action: :land, waypoint: :moon},
          %Params.Step{action: :launch, waypoint: :moon},
          %Params.Step{action: :land, waypoint: :mars},
          %Params.Step{action: :launch, waypoint: :mars},
          %Params.Step{action: :land, waypoint: :earth}
        ]
      }

      assert Flight.to_waypoints(params) == [:earth, :moon, :mars, :earth]
    end

    test "returns empty list for empty flight path" do
      params = %Params{flight_path: []}

      assert Flight.to_waypoints(params) == []
    end
  end

  describe "from_waypoints/2" do
    test "builds flight path from waypoints list" do
      params = %Params{mass: 28801}

      result = Flight.from_waypoints(params, [:earth, :moon, :earth])

      assert result.mass == 28801

      assert result.flight_path == [
               %Params.Step{action: :launch, waypoint: :earth},
               %Params.Step{action: :land, waypoint: :moon},
               %Params.Step{action: :launch, waypoint: :moon},
               %Params.Step{action: :land, waypoint: :earth}
             ]
    end

    test "builds simple one-way trip" do
      params = %Params{}

      result = Flight.from_waypoints(params, [:earth, :mars])

      assert result.flight_path == [
               %Params.Step{action: :launch, waypoint: :earth},
               %Params.Step{action: :land, waypoint: :mars}
             ]
    end

    test "builds multi-stop journey" do
      params = %Params{}

      result = Flight.from_waypoints(params, [:earth, :moon, :mars, :earth])

      assert result.flight_path == [
               %Params.Step{action: :launch, waypoint: :earth},
               %Params.Step{action: :land, waypoint: :moon},
               %Params.Step{action: :launch, waypoint: :moon},
               %Params.Step{action: :land, waypoint: :mars},
               %Params.Step{action: :launch, waypoint: :mars},
               %Params.Step{action: :land, waypoint: :earth}
             ]
    end

    test "clears existing flight path before building new one" do
      params = %Params{
        flight_path: [
          %Params.Step{action: :launch, waypoint: :mars},
          %Params.Step{action: :land, waypoint: :earth}
        ]
      }

      result = Flight.from_waypoints(params, [:earth, :moon])

      assert result.flight_path == [
               %Params.Step{action: :launch, waypoint: :earth},
               %Params.Step{action: :land, waypoint: :moon}
             ]
    end

    test "returns cleared params for empty waypoints list" do
      params = %Params{
        flight_path: [%Params.Step{action: :launch, waypoint: :earth}]
      }

      result = Flight.from_waypoints(params, [])

      assert result.flight_path == []
    end

    test "handles single waypoint" do
      params = %Params{}

      result = Flight.from_waypoints(params, [:earth])

      assert result.flight_path == [
               %Params.Step{action: :launch, waypoint: :earth}
             ]
    end

    test "to_waypoints and from_waypoints are inverse operations" do
      original_waypoints = [:earth, :moon, :mars, :earth]
      params = %Params{}

      result =
        params
        |> Flight.from_waypoints(original_waypoints)
        |> Flight.to_waypoints()

      assert result == original_waypoints
    end
  end
end
