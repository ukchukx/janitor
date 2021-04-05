defmodule JanitorWeb.SessionController do
  use JanitorWeb, :controller

  def signin(%{assigns: %{authenticated: true}} = conn, _params) do
    redirect(conn, to: Routes.page_path(conn, :index))
  end

  def signin(conn, _params) do
    post_path = Routes.session_path(conn, :create_session)
    render(conn, "signin.html", post_path: post_path, page_title: "Sign in")
  end

  def create_session(conn, %{"password" => password}) do
    configured_password = Application.get_env(:janitor, :superuser_password)

    with true <- password == configured_password do
      conn
      |> assign(:authenticated, true)
      |> put_session(:authenticated, true)
      |> configure_session(renew: true)
      |> redirect(to: Routes.page_path(conn, :index))
    else
      false -> redirect(conn, to: Routes.session_path(conn, :signin))
    end
  end

  def signout(conn, _params) do
    conn
    |> clear_session
    |> redirect(to: Routes.session_path(conn, :signin))
  end
end
