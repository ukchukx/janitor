defmodule Janitor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @app :janitor

  @impl true
  def start(_type, _args) do
    Confex.resolve_env!(@app)
    registry = Application.get_env(@app, :schedule_registry)
    supervisor = Application.get_env(@app, :schedule_supervisor)

    children = [
      {Registry, [name: registry, keys: :unique]},
      {DynamicSupervisor, [name: supervisor, strategy: :one_for_one]},
      {Finch, name: @app, pools: %{:default => [size: 20, count: 8]}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Janitor.Supervisor]

    {:ok, _} = start_result = Supervisor.start_link(children, opts)

    if Application.get_env(@app, :env) != :test do
      Logger.info("Loading existing schedules...")
      Janitor.start()
    end

    start_result
  end
end
