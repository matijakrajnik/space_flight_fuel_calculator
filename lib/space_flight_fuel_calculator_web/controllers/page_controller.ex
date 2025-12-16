defmodule SpaceFlightFuelCalculatorWeb.PageController do
  use SpaceFlightFuelCalculatorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
