defmodule JanitorWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Confex.resolve_env!(:janitor_web)

    children = [
      # Start the Telemetry supervisor
      JanitorWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: JanitorWeb.PubSub},
      # Start the Endpoint (http/https)
      JanitorWeb.Endpoint
      # Start a worker by calling: JanitorWeb.Worker.start_link(arg)
      # {JanitorWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JanitorWeb.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = res ->
        configured_password = Application.get_env(:janitor, :superuser_password)
        Logger.info("Configured super-user password: '#{configured_password}'")

        res
      res ->
        res
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    JanitorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
