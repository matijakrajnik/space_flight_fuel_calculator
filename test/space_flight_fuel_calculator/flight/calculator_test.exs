defmodule SpaceFlightFuelCalculator.Flight.CalculatorTest do
  use ExUnit.Case, async: true

  alias SpaceFlightFuelCalculator.Flight.Calculator

  describe "waypoints/0" do
    test "returns list of supported celestial bodies" do
      waypoints = Calculator.waypoints()

      assert is_list(waypoints)
      assert :earth in waypoints
      assert :moon in waypoints
      assert :mars in waypoints
    end
  end

  describe "actions/0" do
    test "returns list of supported actions" do
      assert Calculator.actions() == [:launch, :land]
    end
  end

  describe "step/3" do
    test "calculates fuel for landing on Earth" do
      assert Calculator.step(:land, 28801, :earth) == {:ok, 13447}
    end

    test "calculates fuel for launching from Earth" do
      assert Calculator.step(:launch, 28801, :earth) == {:ok, 19772}
    end

    test "calculates fuel for landing on Moon" do
      assert Calculator.step(:land, 28801, :moon) == {:ok, 1535}
    end

    test "calculates fuel for launching from Moon" do
      assert Calculator.step(:launch, 28801, :moon) == {:ok, 2024}
    end

    test "calculates fuel for landing on Mars" do
      assert Calculator.step(:land, 28801, :mars) == {:ok, 3874}
    end

    test "calculates fuel for launching from Mars" do
      assert Calculator.step(:launch, 28801, :mars) == {:ok, 5186}
    end

    test "returns error for invalid waypoint" do
      assert Calculator.step(:launch, 28801, :jupiter) == {:error, :invalid_waypoint}
    end

    test "returns zero fuel for negative mass" do
      assert Calculator.step(:launch, -100, :earth) == {:ok, 0}
    end

    test "returns zero fuel for zero mass" do
      assert Calculator.step(:launch, 0, :earth) == {:ok, 0}
    end

    test "returns error for non-numeric mass" do
      assert Calculator.step(:launch, "28801", :earth) == {:error, :invalid_mass}
    end

    test "returns error for invalid action" do
      assert Calculator.step(:fly, 28801, :earth) == {:error, :invalid_action}
    end
  end

  describe "total/2" do
    test "Apollo 11 mission" do
      path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      assert Calculator.total(28801, path) == {:ok, 51898}
    end

    test "Mars mission" do
      path = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]
      assert Calculator.total(14606, path) == {:ok, 33388}
    end

    test "Passenger ship mission" do
      path = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      assert Calculator.total(75432, path) == {:ok, 212_161}
    end

    test "empty flight path returns zero fuel" do
      assert Calculator.total(28801, []) == {:ok, 0}
    end

    test "single step path" do
      path = [{:launch, :earth}]
      assert Calculator.total(28801, path) == {:ok, 19772}
    end

    test "returns error for invalid mass" do
      path = [{:launch, :earth}]
      assert Calculator.total(-100, path) == {:error, :invalid_mass}
      assert Calculator.total(0, path) == {:error, :invalid_mass}
      assert Calculator.total("28801", path) == {:error, :invalid_mass}
    end

    test "returns error if any step has invalid waypoint" do
      path = [{:launch, :earth}, {:land, :jupiter}]
      assert Calculator.total(28801, path) == {:error, :invalid_waypoint}
    end

    test "returns error if any step has invalid action" do
      path = [{:launch, :earth}, {:fly, :moon}]
      assert Calculator.total(28801, path) == {:error, :invalid_action}
    end
  end
end
