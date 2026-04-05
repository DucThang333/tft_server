defmodule TftServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :tft_server

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug CORSPlug, origin: "*", max_age: 86400
  plug TftServerWeb.Router
end
