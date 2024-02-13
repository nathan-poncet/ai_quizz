defmodule AiQuizzWeb.GameLive do
  use AiQuizzWeb, :live_view

  require Logger

  alias AiQuizz.Games

  #  alias AiQuizz.Games

  def render(assigns) do
    ~H"""
    <h1>Hi from game <%= @code %> with status: <%= @game.status %></h1>
    <h2>Users</h2>
    <pre><%= inspect(@socket.id) %></pre>
    <ul id="users" phx-update="stream">
      <li :for={{dom_id, %{id: id, metas: metas}} <- @streams.presences} id={dom_id}>
        <%= id %> (<%= length(metas) %>)
      </li>
    </ul>

    <button phx-click="start">Start</button>
    """
  end

  on_mount {AiQuizzWeb.UserAuth, :ensure_authenticated}

  def mount(%{"id" => game_code}, _session, socket) do
    socket = stream(socket, :presences, [])

    socket =
      if connected?(socket) do
        socket_id = socket.id
        user_id = socket.assigns.current_user.id
        user_email = socket.assigns.current_user.email

        socket =
          case Games.join_game(game_code, user_id, socket_id, user_email) do
            {:ok, player} ->
              socket |> assign(:player, player)

            {:error, reason} ->
              Logger.error("Failed to join game: #{inspect(reason)}")

              socket
              |> put_flash(:error, "Failed to join game: #{inspect(reason)}")
              |> redirect(to: ~p"/")
          end

        stream(socket, :presences, Games.list_presence(game_code))
      else
        socket
      end

    {:ok, game} = Games.get_game(game_code)

    {:ok, socket |> assign(code: game_code, game: game)}
  end

  def handle_event("start", _params, socket) do
    case Games.start_game(socket.assigns.code, socket.assigns.player.id) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Failed to start game: #{inspect(reason)}")

        {:noreply, socket |> put_flash(:error, "Failed to start game: #{inspect(reason)}")}
    end
  end

  def handle_info({AiQuizzWeb.Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({AiQuizzWeb.Presence, {:leave, presence}}, socket) do
    if presence.metas == [] do
      {:noreply, stream_delete(socket, :presences, presence)}
    else
      {:noreply, stream_insert(socket, :presences, presence)}
    end
  end

  def handle_info({:game_update, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info(event, socket) do
    Logger.warning(["Game socket received unknown event: ", inspect(event)])
    {:noreply, socket}
  end
end
