defmodule JanitorWeb.Plug.AuthenticateUser do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts), do: opts

  def call(%{assigns: %{authenticated: true}} = conn, _opts), do: conn

  def call(conn, _opts) do
    with true <- get_session(conn, "authenticated") do
      assign(conn, :authenticated, true)
    else
      _ ->
        conn
        |> redirect(to: JanitorWeb.Router.Helpers.session_path(conn, :signin))
        |> halt
    end
  end
end
