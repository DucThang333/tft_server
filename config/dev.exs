import Config

# Optional: load project-root .env for local `mix phx.server` (Docker Compose also reads .env).
if File.exists?(".env") do
  for line <- File.stream!(".env") do
    line = String.trim(line)

    if line != "" and not String.starts_with?(line, "#") do
      case String.split(line, "=", parts: 2) do
        [k, v] -> System.put_env(String.trim(k), String.trim(v))
        _ -> :ok
      end
    end
  end
end

maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

neon_url =
  case System.get_env("DATABASE_URL") do
    url when is_binary(url) ->
      case String.trim(url) do
        "" -> nil
        trimmed -> trimmed
      end

    _ ->
      nil
  end

if neon_url do
  config :tft_server, TftServer.Repo,
    url: neon_url,
    ssl: true,
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6
else
  config :tft_server, TftServer.Repo,
    username: "postgres",
    password: "postgres",
    hostname: System.get_env("DATABASE_HOST") || "localhost",
    database: "tft",
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10,
    socket_options: maybe_ipv6
end

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
