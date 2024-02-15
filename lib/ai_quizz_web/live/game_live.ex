defmodule AiQuizzWeb.GameLive do
  alias AiQuizz.Accounts
  alias AiQuizz.Accounts.User
  alias AiQuizz.Games.GamePlayer
  use AiQuizzWeb, :live_view

  require Logger

  alias AiQuizz.Games
  alias AiQuizzWeb.GameComponents

  #  alias AiQuizz.Games

  def render(assigns) do
    assigns =
      assign(
        assigns,
        current_question: current_question(assigns),
        response: response(assigns)
      )

    ~H"""
    <h1>Hi from game <%= @code %> with status: <%= @game.status %></h1>
    <!-- Player Display -->
    <h2>Users</h2>
    <div class="grid grid-cols-5 gap-2 mx-4 mt-2 mb-8" id="users">
      <div :for={player <- @game.players} id={player.id} class="col-span-2 flex flex-row items-center">
        <.status_indicator online={player.id in (@presences |> Enum.map(& &1.id))} class="mr-2" />

        <div class="flex-1 text-lg decoration-2 truncate">
          <%= if player.id == @player_id, do: "You", else: player.username %>
        </div>
      </div>
    </div>

    <%!-- Timer --%>
    <GameComponents.timer timer={@game.timer} />

    <%!-- Spacer --%>
    <div class="h-8"></div>

    <%!-- Question --%>
    <GameComponents.question game={@game} current_question={@current_question} response={@response} />

    <%!-- Spacer --%>
    <div class="h-8"></div>

    <%!-- Response --%>
    <GameComponents.response game={@game} player_id={@player_id} />

    <%!-- Score --%>
    <GameComponents.score game={@game} />

    <%!-- Spacer --%>
    <div class="h-8"></div>

    <GameComponents.bottom_app_bar game={@game} />
    """
  end

  def mount(%{"id" => game_code}, session, socket) do
    socket =
      socket
      |> assign(player_id: nil, presences: [])
      |> assign_new(:current_user, fn -> find_current_user(session) end)

    socket =
      if connected?(socket) do
        socket =
          case Games.join_game(game_code, create_player_params(socket)) do
            {:ok, player_id} ->
              :ok = Games.subscribe(game_code, player_id)
              assign(socket, :player_id, player_id)

            {:error, reason} ->
              socket
              |> put_flash(:error, "Failed to join game: #{inspect(reason)}")
              |> redirect(to: ~p"/")
          end

        assign(socket, :presences, Games.list_presence(game_code))
      else
        socket
      end

    {:ok, socket |> get_game(game_code)}
  end

  def handle_event(
        "answer",
        %{"answer" => answer},
        %{assigns: %{code: code, player_id: player_id}} = socket
      ) do
    case Games.answer(code, player_id, answer) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to answer question: #{inspect(reason)}")}
    end
  end

  def handle_event(
        "finish",
        _params,
        %{assigns: %{code: code, player_id: player_id}} = socket
      ) do
    case Games.finish_game(code, player_id) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to finish game: #{inspect(reason)}")}
    end
  end

  def handle_event(
        "next_question",
        _params,
        %{assigns: %{code: code, player_id: player_id}} = socket
      ) do
    case Games.next_question(code, player_id) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed: #{inspect(reason)}")}
    end
  end

  def handle_event("start", _params, %{assigns: %{code: code, player_id: player_id}} = socket) do
    case Games.start_game(code, player_id) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to start game: #{inspect(reason)}")}
    end
  end

  def handle_info({AiQuizzWeb.Presence, {:join, _presence}}, socket) do
    {:noreply, assign(socket, :presences, Games.list_presence(socket.assigns.code))}
  end

  def handle_info({AiQuizzWeb.Presence, {:leave, _presence}}, socket) do
    {:noreply, assign(socket, :presences, Games.list_presence(socket.assigns.code))}
  end

  def handle_info({:tick, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info({:game_update, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info(event, socket) do
    Logger.warning(["Game socket received unknown event: ", inspect(event)])
    {:noreply, socket}
  end

  @doc """
  An indicator showing whether a user is currently online or not.
  """
  attr :class, :string, default: ""
  attr :online, :boolean, required: true
  attr :size, :atom, default: :medium

  @spec status_indicator(map) :: Phoenix.LiveView.Rendered.t()
  def status_indicator(assigns) do
    if assigns[:online] do
      ~H"""
      <div class={[indicator_size(@size), "text-green-400 cursor-default", @class]} title="online">
        ●
      </div>
      """
    else
      ~H"""
      <div class={[indicator_size(@size), "text-slate-400 cursor-default", @class]} title="offline">
        ○
      </div>
      """
    end
  end

  @spec indicator_size(:medium | :small) :: String.t()
  defp indicator_size(:small), do: "text-lg"
  defp indicator_size(:medium), do: "text-xl"
  defp indicator_size(:xlarge), do: "text-3xl"

  @spec create_player_params(Phoenix.LiveView.Socket.t()) :: GamePlayer.t()
  defp create_player_params(socket) when socket.assigns.current_user != nil do
    %GamePlayer{
      socket_id: socket.id,
      user_id: socket.assigns.current_user.id,
      username: socket.assigns.current_user.email
    }
  end

  defp create_player_params(socket) do
    %GamePlayer{socket_id: socket.id, username: "Random:#{socket.id}"}
  end

  @spec current_question(map) :: GameQuestion.t()
  defp current_question(assigns) do
    Enum.at(assigns.game.questions, assigns.game.current_question) || %Games.GameQuestion{}
  end

  @spec find_current_user(map) :: User.t()
  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
  end

  @spec get_game(Phoenix.LiveView.Socket.t(), String.t()) :: Phoenix.LiveView.Socket.t()
  defp get_game(socket, game_code) do
    case Games.get_game(game_code) do
      {:ok, game} ->
        socket |> assign(code: game_code, game: game)

      {:error, reason} ->
        socket
        |> put_flash(:error, "Failed to get game: #{inspect(reason)}")
        |> redirect(to: ~p"/")
    end
  end

  @spec response(map) :: String.t() | nil
  defp response(assigns) do
    case Enum.find(assigns.game.players, &(&1.id == assigns.player_id)) do
      player when is_map(player) ->
        Enum.at(player.answers, assigns.game.current_question).value

      _ ->
        nil
    end
  end
end
