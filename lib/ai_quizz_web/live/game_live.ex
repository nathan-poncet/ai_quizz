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
        current_question: Enum.at(assigns.game.questions, assigns.game.current_question),
        response:
          case Enum.find(assigns.game.players, &(&1.id == assigns.player.id)) do
            nil ->
              ""

            player ->
              player.answers |> Enum.at(assigns.game.current_question)
          end
      )

    ~H"""
    <h1>Hi from game <%= @code %> with status: <%= @game.status %></h1>

    <pre> <%= inspect(@game.players) %> </pre>
    <!-- Player Display -->
    <h2>Users</h2>
    <div class="grid grid-cols-5 gap-2 mx-4 mt-2 mb-8" id="users">
      <div :for={player <- @game.players} id={player.id} class="col-span-2 flex flex-row items-center">
        <.status_indicator online={player.id in (@presences |> Enum.map(& &1.user.id))} class="mr-2" />

        <div class="flex-1 text-lg decoration-2 truncate">
          <%= if player.id == @player.id, do: "You", else: player.username %>
        </div>
      </div>
    </div>

    <%!-- Timer --%>
    <div class="flex flex-row items-center justify-center">
      <div class="text-4xl font-bold">
        <%= @game.timer %>
      </div>
    </div>

    <%!-- Question --%>
    <div
      :if={@game.status in [:in_play_question, :in_play_response, :in_result]}
      class="flex flex-row items-center justify-center"
    >
      <div class="text-4xl font-bold">
        <%= @current_question.question %>
      </div>
    </div>

    <%!-- Spacer --%>
    <div class="h-8"></div>

    <%!-- Options --%>
    <div :if={@game.status in [:in_play_response, :in_result]} class="grid grid-cols-2 gap-2">
      <button
        :for={option <- @current_question.options}
        phx-click="answer"
        phx-value-answer={option}
        class={[
          "text-4xl font-bold p-4 border border-black	rounded",
          @response == option && "bg-black text-white",
          @game.status == :in_result && "cursor-default",
          @game.status == :in_result && @current_question.answer == option && "bg-green-400",
          @game.status == :in_result && @response == option && @current_question.answer != option &&
            "bg-red-400"
        ]}
      >
        <%= option %>
      </button>
    </div>

    <%!-- Spacer --%>
    <div class="h-8"></div>

    <%!-- Response --%>
    <div :if={@game.status in [:in_result]}>
      <h2>Responses</h2>
      <div :for={player <- @game.players} class="flex flex-row items-center justify-center">
        <div class="flex-1 text-lg decoration-2 truncate">
          <%= if player.id == @player.id, do: "You", else: player.username %>
        </div>

        <div class="flex-1 text-lg decoration-2 truncate">
          <%= player.answers |> Enum.at(@game.current_question) %>
        </div>
      </div>
    </div>

    <%!-- Spacer --%>
    <div class="h-8"></div>

    <GameComponents.bottom_app_bar game={@game} />
    """
  end

  def mount(%{"id" => game_code}, session, socket) do
    socket =
      socket
      |> assign(player: %GamePlayer{}, presences: [])
      |> assign_new(:current_user, fn -> find_current_user(session) end)

    socket =
      if connected?(socket) do
        socket_id = socket.id

        player_params =
          if socket.assigns.current_user != nil do
            %GamePlayer{
              socket_id: socket_id,
              user_id: socket.assigns.current_user.id,
              username: socket.assigns.current_user.email
            }
          else
            %GamePlayer{socket_id: socket_id, username: "Random:#{socket_id}"}
          end

        socket =
          case Games.join_game(game_code, player_params) do
            {:ok, player} ->
              Games.subscribe(game_code, player)
              assign(socket, :player, player)

            {:error, reason} ->
              Logger.error("Failed to join game: #{inspect(reason)}")

              socket
              |> put_flash(:error, "Failed to join game: #{inspect(reason)}")
              |> redirect(to: ~p"/")
          end

        assign(socket, :presences, Games.list_presence(game_code))
      else
        socket
      end

    socket =
      case Games.get_game(game_code) do
        {:ok, game} ->
          socket |> assign(code: game_code, game: game)

        {:error, reason} ->
          socket
          |> put_flash(:error, "Failed to get game: #{inspect(reason)}")
          |> redirect(to: ~p"/")
      end

    {:ok, socket}
  end

  def handle_event(
        "answer",
        %{"answer" => answer},
        %{assigns: %{code: code, player: player}} = socket
      ) do
    case Games.answer(code, player.id, answer) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to answer question: #{inspect(reason)}")}
    end
  end

  def handle_event(
        "next_question",
        _params,
        %{assigns: %{code: code, player: %{id: player_id}}} = socket
      ) do
    case Games.next_question(code, player_id) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed: #{inspect(reason)}")}
    end
  end

  def handle_event("start", _params, socket) do
    case Games.start_game(socket.assigns.code, socket.assigns.player.id) do
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
    {:noreply, socket |> assign(:game, game)}
  end

  def handle_info({:game_update, game}, socket) do
    {:noreply,
     socket
     |> assign(:game, game)
     |> put_flash(:info, "Game updated")}
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

  @spec find_current_user(map) :: User.t()
  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
  end
end
