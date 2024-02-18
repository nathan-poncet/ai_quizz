defmodule AiQuizzWeb.GameSessionController do
  require Logger
  use AiQuizzWeb, :controller

  def create_or_join(conn, %{"game" => game_params}) do
    code = game_params["code"]
    password = game_params["password"]

    conn
    |> put_session(:game_password, password)
    |> redirect(to: ~p"/games/#{code}")
  end
end
