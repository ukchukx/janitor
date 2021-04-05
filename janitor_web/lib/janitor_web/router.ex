defmodule JanitorWeb.Router do
  use JanitorWeb, :router

  forward "/health/live", Healthchex.Probes.Liveness
  forward "/health/ready", Healthchex.Probes.Readiness

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug JanitorWeb.Plug.AuthenticateUser
  end

  scope "/", JanitorWeb do
    pipe_through :browser

    get "/signin", SessionController, :signin
    post "/signin", SessionController, :create_session

    scope "/" do
      pipe_through :auth

      get "/", PageController, :index
      get "/signout", SessionController, :signout
    end
  end

  scope "/api/schedules", JanitorWeb do
    pipe_through [:browser, :auth]

    post "/databases", PageController, :available_databases
    get "/", PageController, :all_backup_schedules
    post "/", PageController, :create_backup_schedule
    put "/:id", PageController, :update_backup_schedule
    delete "/:id", PageController, :delete_backup_schedule
    post "/:id/backups/create", PageController, :run_backup
    delete "/:id/backups/:name/delete", PageController, :delete_backup
  end

  # Other scopes may use custom stacks.
  # scope "/api", JanitorWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: JanitorWeb.Telemetry
    end
  end
end
