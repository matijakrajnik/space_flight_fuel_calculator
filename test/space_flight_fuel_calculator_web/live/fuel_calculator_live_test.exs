defmodule SpaceFlightFuelCalculatorWeb.FuelCalculatorLiveTest do
  use SpaceFlightFuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "renders fuel calculator page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Calculate fuel requirements for interplanetary travel"
      assert html =~ "Spacecraft mass"
      assert html =~ "Total Fuel Required"
    end

    test "starts with empty flight path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "No steps added yet"
    end

    test "shows waypoint options", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Earth"
      assert html =~ "Moon"
      assert html =~ "Mars"
    end
  end

  describe "validate event" do
    test "updates mass and calculates fuel when valid", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})

      view
      |> element("#params-form")
      |> render_change(%{"params" => %{"mass" => "28801"}})

      html = render(view)
      assert html =~ "19772"
    end

    test "shows error for invalid mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#params-form")
      |> render_change(%{"params" => %{"mass" => "0"}})

      html = render(view)
      assert html =~ "must be greater than 0"
    end
  end

  describe "add_waypoint event" do
    test "adds waypoint to selected waypoints", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})

      html = render(view)
      assert html =~ "Launch from Earth"
    end

    test "adds multiple waypoints and generates flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})
      render_click(view, "add_waypoint", %{"waypoint" => "moon"})

      html = render(view)
      assert html =~ "Launch from Earth"
      assert html =~ "Land on Moon"
    end

    test "generates round trip flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})
      render_click(view, "add_waypoint", %{"waypoint" => "moon"})
      render_click(view, "add_waypoint", %{"waypoint" => "earth"})

      html = render(view)
      assert html =~ "Launch from Earth"
      assert html =~ "Land on Moon"
      assert html =~ "Launch from Moon"
      assert html =~ "Land on Earth"
    end
  end

  describe "remove_waypoint event" do
    test "removes waypoint from selected waypoints", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})
      render_click(view, "add_waypoint", %{"waypoint" => "moon"})
      render_click(view, "remove_waypoint", %{"index" => "1"})

      html = render(view)
      assert html =~ "Launch from Earth"
      refute html =~ "Land on Moon"
    end

    test "clears flight path when all waypoints removed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})
      render_click(view, "remove_waypoint", %{"index" => "0"})

      html = render(view)
      assert html =~ "No steps added yet"
    end
  end

  describe "fuel calculation" do
    test "calculates fuel for Apollo 11 mission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#params-form")
      |> render_change(%{"params" => %{"mass" => "28801"}})

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})
      render_click(view, "add_waypoint", %{"waypoint" => "moon"})
      render_click(view, "add_waypoint", %{"waypoint" => "earth"})

      html = render(view)
      assert html =~ "51898"
    end

    test "calculates fuel for Mars mission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#params-form")
      |> render_change(%{"params" => %{"mass" => "14606"}})

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})
      render_click(view, "add_waypoint", %{"waypoint" => "mars"})
      render_click(view, "add_waypoint", %{"waypoint" => "earth"})

      html = render(view)
      assert html =~ "33388"
    end

    test "calculates fuel for Passenger Ship mission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#params-form")
      |> render_change(%{"params" => %{"mass" => "75432"}})

      render_click(view, "add_waypoint", %{"waypoint" => "earth"})
      render_click(view, "add_waypoint", %{"waypoint" => "moon"})
      render_click(view, "add_waypoint", %{"waypoint" => "mars"})
      render_click(view, "add_waypoint", %{"waypoint" => "earth"})

      html = render(view)
      assert html =~ "212161"
    end
  end
end
