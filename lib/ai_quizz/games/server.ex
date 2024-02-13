defmodule AiQuizz.Games.Server do
  use GenServer, restart: :temporary
  require Logger
  alias AiQuizz.Games.GamePlayers
  alias AiQuizz.Games.GamePlayer
  alias AiQuizz.Games.Game

  def start_link(args) do
    Logger.debug("Starting game server.")

    game = Keyword.get(args, :params) |> Game.register()

    GenServer.start_link(__MODULE__, game, name: via_tuple(game.code))
  end

  def whereis(game_code) do
    case Registry.lookup(:game_server_registry, game_code) do
      [] ->
        :undefined

      [{pid, _}] ->
        pid
    end
  end

  # Client

  @spec answer(GenServer.server(), String.t(), Integer.t()) :: {:ok, Game.t()} | {:error, atom()}
  def answer(game_server, player_id, answer),
    do: GenServer.call(game_server, {:answer, player_id, answer})

  @spec game(GenServer.server()) :: Game.t()
  def game(game_server), do: GenServer.call(game_server, :game)

  @spec join(GenServer.server(), String.t(), String.t(), String.t()) ::
          {:ok, GamePlayer.t()} | {:error, atom()}
  def join(game_server, user_id, socket_id, name),
    do: GenServer.call(game_server, {:join, user_id, socket_id, name})

  @spec start(GenServer.server(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def start(game_server, player_id),
    do: GenServer.call(game_server, {:start, player_id})

  # Server

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:answer, player_id, answer}, _from, game) do
    case Game.answer(game, player_id, answer) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  def handle_call(:game, _from, game), do: {:reply, game, game}

  def handle_call({:join, user_id, socket_id, name}, _from, game) do
    new_player =
      GamePlayer.new(%GamePlayer{user_id: user_id, socket_id: socket_id, username: name})

    case GamePlayers.add_player(game.players, new_player) do
      {:ok, new_players, new_player} ->
        {:reply, {:ok, new_player}, %Game{game | players: new_players}}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  def handle_call({:next_question, player_id}, _from, game) do
    case Game.next_question(game, player_id) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  def handle_call({:start, player_id}, _from, game) do
    case Game.start(game, player_id) do
      {:ok, game} ->
        broadcast(game.code, :start, game)
        :timer.send_after(1_000, self(), :tick)
        {:reply, {:ok, game}, game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  # Timer
  def handle_info(:tick, %Game{} = game) do
    broadcast(game.code, :tick, game)
    {:noreply, on_tick(game)}
  end

  def handle_info(:reveal_responses, game) do
    {:noreply, game}
  end

  def handle_info(:timeout, game) do
    {:noreply, game}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _info} = message, %Game{} = game) do
    Logger.info("Handling disconnected ref in Game #{game.code}")
    Logger.info("#{inspect(message)}")

    # {:stop, :normal, game}
    {:noreply, game}
  end

  # Private functions
  @spec broadcast(String.t(), atom(), any()) :: :ok
  defp broadcast(join_code, event_type, event) do
    Phoenix.PubSub.broadcast(AiQuizz.PubSub, "proxy:game:" <> join_code, {event_type, event})
  end

  @spec via_tuple(String.t()) :: {:via, Registry, {:game_server_registry, String.t()}}
  defp via_tuple(id) when is_binary(id), do: {:via, Registry, {:game_server_registry, id}}

  @spec on_tick(Game.t()) :: Game.t()
  defp on_tick(%Game{timer: timer} = game) when timer > 0 do
    :timer.send_after(1_000, self(), :tick)
    %Game{game | timer: game.timer - 1}
  end

  defp on_tick(%Game{timer: 0} = game) do
    Game.next_status(game)
  end
end
