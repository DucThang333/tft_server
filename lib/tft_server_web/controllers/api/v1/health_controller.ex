defmodule TftServerWeb.Api.V1.HealthController do
  use TftServerWeb, :controller

  def show(conn, _params) do
    json(conn, %{"status" => "ok"})
  end
end
