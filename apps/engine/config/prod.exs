use Mix.Config

config :engine, Engine.Repo,
  adapter: Ecto.Adapters.Postgres
  pool_size: 2

config :logger,
  level: :info,
  handle_sasl_reports: true,
  handle_otp_reports: true
