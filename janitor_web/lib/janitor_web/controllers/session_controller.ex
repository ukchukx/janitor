defmodule JanitorWeb.SessionController do
  use JanitorWeb, :controller
  require Logger

  def signin(%{assigns: %{authenticated: true}} = conn, _params) do
    redirect(conn, to: Routes.page_path(conn, :index))
  end

  def signin(conn, _params) do
    post_path = Routes.session_path(conn, :create_session)
    render(conn, "signin.html", post_path: post_path, page_title: "Sign in")
  end

  def create_session(conn, %{"password" => supplied_password}) do
    configured_password = JanitorWeb.configured_password()
    Logger.info("Supplied password is #{supplied_password}")
    password_matches? =  String.trim(supplied_password) == configured_password
    Logger.info("Is supplied password same as configured password? #{password_matches?}")

    case password_matches? do
      true ->
        conn
        |> assign(:authenticated, true)
        |> put_session(:authenticated, true)
        |> configure_session(renew: true)
        |> redirect(to: Routes.page_path(conn, :index))
      false ->
        redirect(conn, to: Routes.session_path(conn, :signin))
    end
  end

  def signout(conn, _params) do
    conn
    |> clear_session
    |> redirect(to: Routes.session_path(conn, :signin))
  end
end
