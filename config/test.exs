import Config

config :tft_server, TftServer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "tft_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :tft_server, TftServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_change_in_prod_min_64_chars______________________________",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
