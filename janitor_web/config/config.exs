use Mix.Config

# Configures the endpoint
config :janitor_web, JanitorWeb.Endpoint,
  url: [host: {:system, "JANITOR_DNS_HOST"}, scheme: "https"],
  http: [
    port: {:system, :integer, "JANITOR_PORT", 4000},
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: {:system, "JANITOR_SECRET_KEY_BASE"},
  render_errors: [view: JanitorWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: JanitorWeb.PubSub,
  live_view: [signing_salt: "+tWb8+Kq"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  utc_log: true,
  truncate: :infinity

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

import_config "../../config/config.exs"
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
