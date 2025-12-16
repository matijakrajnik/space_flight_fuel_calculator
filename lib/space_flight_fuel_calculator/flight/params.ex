defmodule SpaceFlightFuelCalculator.Flight.Params do
  @moduledoc """
  Embedded schema for validating flight calculator form inputs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SpaceFlightFuelCalculator.Flight.Calculator

  @primary_key false
  embedded_schema do
    field(:mass, :integer, default: 10_000)

    embeds_many :flight_path, Step, on_replace: :delete do
      field(:action, Ecto.Enum, values: Calculator.actions())
      field(:waypoint, Ecto.Enum, values: Calculator.waypoints())
    end
  end

  @doc """
  Creates a changeset for flight parameters.
  """
  def changeset(params \\ %__MODULE__{}, attrs) do
    params
    |> cast(attrs, [:mass])
    |> validate_required([:mass])
    |> validate_number(:mass, greater_than: 0)
    |> cast_embed(:flight_path, with: &step_changeset/2)
  end

  defp step_changeset(step, attrs) do
    step
    |> cast(attrs, [:action, :waypoint])
    |> validate_required([:action, :waypoint])
  end
end
