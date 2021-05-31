defmodule JanitorPersistence.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias JanitorPersistence.SetupDatabase

  @impl true
  def start(_type, _args) do
    Confex.resolve_env!(:janitor_persistence)

    if Application.get_env(:janitor_persistence, :env) != :test do
      SetupDatabase.create_database()
    end

    children = [
      JanitorPersistence.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JanitorPersistence.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = res ->
        if Application.get_env(:janitor_persistence, :env) != :test do
          SetupDatabase.run_migrations()
        end

        res

      x ->
        x
    end
  end
end
