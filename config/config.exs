import Config

config :tft_server,
  ecto_repos: [TftServer.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :tft_server, TftServerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [json: TftServerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TftServer.PubSub

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
