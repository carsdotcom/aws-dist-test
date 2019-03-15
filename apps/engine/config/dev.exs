use Mix.Config

# Configure your database
{username, 0} = System.cmd("whoami", [])
config :engine, Engine.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: String.trim(username),
  database: "example_web_dev",
  hostname: "localhost",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true
