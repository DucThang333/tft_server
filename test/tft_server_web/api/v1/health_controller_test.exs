defmodule TftServerWeb.Api.V1.HealthControllerTest do
  use TftServerWeb.ConnCase, async: true

  test "GET /api/v1/health", %{conn: conn} do
    conn = get(conn, "/api/v1/health")
    assert json_response(conn, 200) == %{"status" => "ok"}
  end
end
