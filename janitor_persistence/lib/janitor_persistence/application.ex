defmodule JanitorPersistence.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Confex.resolve_env!(:janitor_persistence)

    children = [
      {JanitorPersistence, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JanitorPersistence.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
