defmodule SpaceFlightFuelCalculator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SpaceFlightFuelCalculatorWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:space_flight_fuel_calculator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SpaceFlightFuelCalculator.PubSub},
      # Start a worker by calling: SpaceFlightFuelCalculator.Worker.start_link(arg)
      # {SpaceFlightFuelCalculator.Worker, arg},
      # Start to serve requests, typically the last entry
      SpaceFlightFuelCalculatorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpaceFlightFuelCalculator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SpaceFlightFuelCalculatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
