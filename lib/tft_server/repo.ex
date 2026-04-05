defmodule TftServer.Repo do
  use Ecto.Repo,
    otp_app: :tft_server,
    adapter: Ecto.Adapters.Postgres
end
