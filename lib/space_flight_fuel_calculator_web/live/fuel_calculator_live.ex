defmodule SpaceFlightFuelCalculatorWeb.FuelCalculatorLive do
  use SpaceFlightFuelCalculatorWeb, :live_view

  alias SpaceFlightFuelCalculator.Flight
  alias SpaceFlightFuelCalculator.Flight.Params

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:params, %Params{})
      |> assign(:total_fuel, 0)
      |> assign_clear_form()
      |> assign(:waypoints, options(Flight.waypoints()))
      |> assign(:selected_waypoints, [])
    }
  end

  @impl Phoenix.LiveView
  def handle_event(
        "validate",
        %{"params" => params_attrs},
        %{assigns: %{params: params}} = socket
      ) do
    changeset = Flight.change_params(params, params_attrs)
    params = Ecto.Changeset.apply_changes(changeset)

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> assign_form(changeset, :validate)
      |> calculate_fuel()
    }
  end

  def handle_event(
        "add_waypoint",
        %{"waypoint" => waypoint},
        %{assigns: %{params: params, selected_waypoints: selected_waypoints}} = socket
      ) do
    selected_waypoints = Enum.concat(selected_waypoints, [String.to_existing_atom(waypoint)])
    params = Flight.from_waypoints(params, selected_waypoints)

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> assign(:selected_waypoints, selected_waypoints)
      |> calculate_fuel()
    }
  end

  def handle_event(
        "remove_waypoint",
        %{"index" => index},
        %{assigns: %{params: params, selected_waypoints: selected_waypoints}} = socket
      ) do
    {index, ""} = Integer.parse(index)
    selected_waypoints = List.delete_at(selected_waypoints, index)
    params = Flight.from_waypoints(params, selected_waypoints)

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> assign(:selected_waypoints, selected_waypoints)
      |> calculate_fuel()
    }
  end

  defp assign_clear_form(socket) do
    changeset = Flight.change_params(%{})
    assign_form(socket, changeset)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset, action) do
    assign(socket, :form, to_form(changeset, action: action))
  end

  defp calculate_fuel(%{assigns: %{params: params}} = socket) do
    case Flight.calculate_fuel(params) do
      {:ok, fuel} ->
        assign(socket, :total_fuel, fuel)

      {:error, error} ->
        socket
        |> put_flash(:error, "Error calculating fuel: #{error}")
        |> assign(:total_fuel, "N/A")
    end
  end

  defp options(list) do
    Enum.map(list, fn item ->
      {item |> Atom.to_string() |> String.capitalize(), item}
    end)
  end

  defp capitalize(value) when is_atom(value), do: value |> Atom.to_string() |> capitalize()
  defp capitalize(value) when is_binary(value), do: String.capitalize(value)
end
