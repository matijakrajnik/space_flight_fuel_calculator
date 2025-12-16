defmodule SpaceFlightFuelCalculator.Flight.Calculator do
  @moduledoc """
  Calculates fuel requirements for interplanetary space travel.
  """

  @typedoc "Flight actions"
  @type action :: :launch | :land

  @typedoc "Fuel calculation result"
  @type result :: {:ok, integer()} | {:error, :invalid_waypoint | :invalid_mass | :invalid_action}

  @gravity %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  @doc """
  Returns a list of all supported celestial bodies.
  """
  @spec waypoints() :: [atom()]
  def waypoints, do: Map.keys(@gravity)

  @doc """
  Returns a list of all supported actions.
  """
  @spec actions() :: [action()]
  def actions, do: [:launch, :land]

  @doc """
  Calculates the fuel required for a single flight step, including
  the additional fuel needed to carry the fuel itself.

  This recursively calculates fuel until additional fuel is 0 or negative.
  """
  @spec step(any(), any(), atom()) :: result()
  def step(action, mass, waypoint) do
    case base_fuel(action, mass, waypoint) do
      {:ok, base_fuel} -> {:ok, base_fuel + additional_fuel(action, base_fuel, waypoint)}
      error -> error
    end
  end

  @doc """
  Calculates the total fuel required for a complete flight path.

  The flight path is processed in reverse order because fuel adds weight
  that affects earlier steps in the journey.

  ## Parameters

    * `mass` - Equipment mass in kg (without fuel)
    * `flight_path` - List of `{action, waypoint}` tuples
  """
  @spec total(number(), [{action(), atom()}]) :: result()
  def total(mass, flight_path) when is_number(mass) and mass > 0 and is_list(flight_path) do
    flight_path
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, 0, mass}, fn {action, waypoint}, {:ok, total_fuel, current_mass} ->
      case step(action, current_mass, waypoint) do
        {:ok, step_fuel} ->
          {:cont, {:ok, total_fuel + step_fuel, current_mass + step_fuel}}

        {:error, _} = error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, total_fuel, _final_mass} -> {:ok, total_fuel}
      error -> error
    end
  end

  def total(_mass, _flight_path), do: {:error, :invalid_mass}

  defp base_fuel(:launch, mass, waypoint) when is_number(mass) and mass > 0 do
    case Map.fetch(@gravity, waypoint) do
      {:ok, g} -> {:ok, floor(mass * g * 0.042 - 33)}
      :error -> {:error, :invalid_waypoint}
    end
  end

  defp base_fuel(:land, mass, waypoint) when is_number(mass) and mass > 0 do
    case Map.fetch(@gravity, waypoint) do
      {:ok, g} -> {:ok, floor(mass * g * 0.033 - 42)}
      :error -> {:error, :invalid_waypoint}
    end
  end

  defp base_fuel(_action, mass, _waypoint) when is_number(mass) and mass <= 0, do: {:ok, 0}
  defp base_fuel(_action, mass, _waypoint) when not is_number(mass), do: {:error, :invalid_mass}
  defp base_fuel(_action, _mass, _waypoint), do: {:error, :invalid_action}

  defp additional_fuel(action, fuel_mass, waypoint, acc \\ 0) do
    case base_fuel(action, fuel_mass, waypoint) do
      {:ok, additional} when additional > 0 ->
        additional_fuel(action, additional, waypoint, acc + additional)

      _ ->
        acc
    end
  end
end
