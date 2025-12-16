defmodule SpaceFlightFuelCalculator.Flight do
  @moduledoc """
  The Flight context - handles fuel calculations for interplanetary space travel.

  This module provides the public API for calculating fuel requirements
  for spacecraft missions with multiple flight steps (launches and landings).
  """

  alias SpaceFlightFuelCalculator.Flight.{Calculator, Params}

  @doc """
  Returns a list of all supported waypoints (celestial bodies).
  """
  defdelegate waypoints, to: Calculator

  @doc """
  Returns a list of all supported actions.
  """
  defdelegate actions, to: Calculator

  @doc """
  Creates a changeset for validating flight parameters.
  """
  def change_params(attrs), do: Params.changeset(attrs)

  @doc """
  Creates a changeset from existing params struct.
  """
  def change_params(params, attrs), do: Params.changeset(params, attrs)

  @doc """
  Calculates the total fuel required for a complete flight path.

  ## Parameters

    * `params` - A `%Flight.Params{}` struct with mass and flight_path

  ## Examples

      iex> params = %SpaceFlightFuelCalculator.Flight.Params{
      ...>   mass: 28801,
      ...>   flight_path: [
      ...>     %{action: :launch, waypoint: :earth},
      ...>     %{action: :land, waypoint: :moon},
      ...>     %{action: :launch, waypoint: :moon},
      ...>     %{action: :land, waypoint: :earth}
      ...>   ]
      ...> }
      iex> SpaceFlightFuelCalculator.Flight.calculate_fuel(params)
      {:ok, 51898}
  """
  def calculate_fuel(%Params{mass: mass, flight_path: steps}) do
    flight_path = Enum.map(steps, fn step -> {step.action, step.waypoint} end)
    Calculator.total(mass, flight_path)
  end

  def calculate_fuel(_), do: {:error, :invalid_params}

  @doc """
  Adds a new flight step to the params.
  """
  def add_step(%Params{flight_path: steps} = params, action, waypoint) do
    new_step = %Params.Step{action: action, waypoint: waypoint}
    %{params | flight_path: steps ++ [new_step]}
  end

  @doc """
  Removes a flight step at the given index.
  """
  def remove_step(%Params{flight_path: steps} = params, index) when is_integer(index) do
    %{params | flight_path: List.delete_at(steps, index)}
  end

  def remove_step(_params, _index), do: {:error, :invalid_index}

  @doc """
  Clears the flight path.

  ## Examples

      iex> params = %SpaceFlightFuelCalculator.Flight.Params{mass: 28801, flight_path: [%{action: :launch, waypoint: :earth}, %{action: :land, waypoint: :moon}]}
      iex> SpaceFlightFuelCalculator.Flight.clear_flight_path(params)
      %SpaceFlightFuelCalculator.Flight.Params{mass: 28801, flight_path: []}
  """
  def clear_flight_path(%Params{} = params), do: %Params{params | flight_path: []}

  @doc """
  Extracts the list of waypoints as stops from a flight path.

  Returns the origin (from first launch) followed by each destination (from landings).

  ## Examples

      iex> params = %SpaceFlightFuelCalculator.Flight.Params{
      ...>   mass: 28801,
      ...>   flight_path: [
      ...>     %{action: :launch, waypoint: :earth},
      ...>     %{action: :land, waypoint: :moon},
      ...>     %{action: :launch, waypoint: :moon},
      ...>     %{action: :land, waypoint: :earth}
      ...>   ]
      ...> }
      iex> SpaceFlightFuelCalculator.Flight.to_waypoints(params)
      [:earth, :moon, :earth]
  """
  def to_waypoints(%Params{flight_path: []}), do: []

  def to_waypoints(%Params{flight_path: [first | rest]}) do
    [first.waypoint | for(%{action: :land, waypoint: waypoint} <- rest, do: waypoint)]
  end

  @doc """
  Updates params with a flight path generated from a list of waypoints.

  For each consecutive pair of waypoints, generates a launch from the origin
  and a landing at the destination.

  ## Examples

      iex> params = %SpaceFlightFuelCalculator.Flight.Params{mass: 28801, flight_path: []}
      iex> SpaceFlightFuelCalculator.Flight.from_waypoints(params, [:earth, :moon, :earth])
      %SpaceFlightFuelCalculator.Flight.Params{
        mass: 28801,
        flight_path: [
          %SpaceFlightFuelCalculator.Flight.Params.Step{action: :launch, waypoint: :earth},
          %SpaceFlightFuelCalculator.Flight.Params.Step{action: :land, waypoint: :moon},
          %SpaceFlightFuelCalculator.Flight.Params.Step{action: :launch, waypoint: :moon},
          %SpaceFlightFuelCalculator.Flight.Params.Step{action: :land, waypoint: :earth}
        ]
      }
  """
  def from_waypoints(%Params{} = params, []), do: clear_flight_path(params)

  def from_waypoints(%Params{} = params, [waypoint]) do
    params
    |> clear_flight_path()
    |> add_step(:launch, waypoint)
  end

  def from_waypoints(%Params{} = params, [first | rest]) do
    last = List.last(rest)
    middle = Enum.drop(rest, -1)
    Enum.take(rest, -1)

    params =
      params
      |> clear_flight_path()
      |> add_step(:launch, first)

    middle
    |> Enum.reduce(params, fn waypoint, params ->
      params
      |> add_step(:land, waypoint)
      |> add_step(:launch, waypoint)
    end)
    |> add_step(:land, last)
  end
end
