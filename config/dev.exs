import Config

config :tft_server, TftServer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  database: "tft",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :tft_server, TftServerWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  server: true,
  secret_key_base: "dev_secret_key_base_change_in_prod_min_64_chars________________________________"

config :logger, level: :debug

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :tft_server, :riot,
  platform: System.get_env("RIOT_PLATFORM") || "na1",
  region: System.get_env("RIOT_REGION") || "americas"
