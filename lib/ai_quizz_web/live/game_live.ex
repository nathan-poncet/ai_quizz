defmodule AiQuizzWeb.GameLive do
  use AiQuizzWeb, :live_view

  require Logger

  alias AiQuizz.Games

  #  alias AiQuizz.Games

  def render(assigns) do
    ~H"""
    <h1>Hi from game <%= @code %></h1>
    <h2>Users</h2>
    <ul id="users" phx-update="stream">
      <li :for={{dom_id, %{id: id, metas: metas}} <- @streams.presences} id={dom_id}>
        <%= id %> (<%= length(metas) %>)
      </li>
    </ul>
    """
  end

  on_mount {AiQuizzWeb.UserAuth, :ensure_authenticated}

  def mount(%{"id" => game_code}, _session, socket) do
    socket = stream(socket, :presences, [])

    # TODO: join

    socket =
      if connected?(socket) do
        email = socket.assigns.current_user.email
        Games.subscribe(game_code, email)

        stream(
          socket,
          :presences,
          Games.list_presence(game_code) |> Enum.map(fn {_id, presence} -> presence end)
        )
      else
        socket
      end

    {:ok, game} = Games.get_game(game_code)

    {:ok, socket |> assign(code: game_code, game: game)}
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

  def handle_info(event, socket) do
    Logger.warning(["Game socket received unknown event: ", inspect(event)])
    {:noreply, socket}
  end
end
