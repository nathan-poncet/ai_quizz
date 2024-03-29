defmodule AiQuizz.Games do
  require Logger
  alias AiQuizz.Games.GameTopics
  alias AiQuizz.Games.GamePlayer
  alias AiQuizzWeb.Presence
  alias Ecto.Changeset
  alias AiQuizz.Games.{Game, Server, ServerSupervisor}

  @doc """
  Answer to question in a game.

  ## Examples

      iex> answer(game_id, player_id, pid)
      {:ok, %Game{}}

      iex> answer(bad_value, bad_value, bad_value)
      {:error, reason}

  """
  @spec answer(String.t(), String.t(), String.t()) :: {:ok, Game.t()} | {:error, any()}
  def answer(game_id, player_id, answer) do
    case server(game_id) do
      {:ok, game_server} ->
        Server.answer(game_server, player_id, answer)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  @spec change_game_registration(Game.t(), map) :: Ecto.Changeset.t()
  def change_game_registration(%Game{} = game, attrs \\ %{}) do
    Game.registration_changeset(game, attrs)
  end

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, reason}

  """
  @spec create_game(map) :: {:ok, Game.t()} | {:error, any()}
  def create_game(attrs \\ %{}) do
    changeset = Game.registration_changeset(%Game{}, attrs)
    do_create_game(changeset)
  end

  defp do_create_game(%Changeset{valid?: true, changes: attrs}) do
    with {:ok, pid} <- ServerSupervisor.start_child(attrs),
         game <- Server.game(pid) do
      {:ok, game}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_create_game(%Changeset{valid?: false} = changeset) do
    {:error, Map.put(changeset, :action, :insert)}
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game_id)
      :ok

      iex> delete_game(game_id)
      {:error, reason}

  """
  def delete_game(game_id) do
    with {:ok, game_server} <- server(game_id),
         :ok <- ServerSupervisor.terminate_child(game_server) do
      :ok
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Finish a game.
  """
  @spec finish_game(String.t(), String.t()) :: {:ok, Game.t()} | {:error, any()}
  def finish_game(game_id, player_id) do
    case server(game_id) do
      {:ok, game_server} ->
        Server.finish(game_server, player_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets a single game.

  ## Examples

      iex> get_game(123)
      {:ok, %Game{}}

      iex> get_game(456)
      {:error, reason}

  """
  def get_game(game_id) do
    case server(game_id) do
      {:ok, game_server} ->
        {:ok, Server.game(game_server)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Join a game.

  ## Examples

      iex> join_game(game_id, player_id, pid)
      {:ok, %Game{}}

      iex> join_game(bad_value, player_id, pid)
      {:error, reason}

  """
  @spec join_game(String.t(), String.t(), GamePlayer.t()) :: {:ok, String.t()} | {:error, any()}
  def join_game(game_id, password, %GamePlayer{} = player_params) do
    with {:ok, game_server} <- server(game_id),
         {:ok, _player} = join <- Server.join(game_server, password, player_params) do
      Process.monitor(game_server)
      join
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get the list of players currently present in the specified game.
  """
  @spec list_presence(String.t()) :: Presence.t()
  def list_presence(join_code) do
    Presence.list("game:" <> join_code) |> Enum.map(fn {_id, presence} -> presence end)
  end

  @doc """
  Next question in a game.
  """
  @spec next_question(String.t(), String.t()) :: {:ok, Game.t()} | {:error, any()}
  def next_question(game_id, player_id) do
    case server(game_id) do
      {:ok, game_server} ->
        Server.next_question(game_server, player_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Start a game.

  ## Examples

      iex> start_game(game_id)
      {:ok, %Game{}}

      iex> start_game(bad_value)
      {:error, reason}

  """
  @spec start_game(String.t(), String.t()) :: {:ok, Game.t()} | {:error, any()}
  def start_game(game_code, player_id) do
    case server(game_code) do
      {:ok, game_server} ->
        Server.start(game_server, player_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Susbscribe a process to updates for the specified game.
  """
  @spec subscribe(String.t(), String.t()) :: :ok
  def subscribe(game_code, player_id) do
    topic = "game:" <> game_code

    with :ok <- Phoenix.PubSub.subscribe(AiQuizz.PubSub, "proxy:#{topic}"),
         {:ok, _} <- Presence.track(self(), topic, player_id, %{id: player_id}) do
      :ok
    end
  end

  @doc """
  UnSusbscribe a process to updates for the specified game.
  """
  @spec unsubscribe(String.t(), String.t()) :: :ok
  def unsubscribe(game_code, player_id) do
    topic = "game:" <> game_code

    with :ok <- Phoenix.PubSub.unsubscribe(Level10.PubSub, topic) do
      Presence.untrack(self(), topic, player_id)
    end
  end

  def topics_generate(topics) do
    GameTopics.generate(topics)
  end

  # Private functions
  @spec server(String.t()) :: {:ok, pid()} | {:error, atom()}
  defp server(game_id) do
    case Server.whereis(game_id) do
      :undefined ->
        {:error, :game_doesnt_exist}

      game_server ->
        {:ok, game_server}
    end
  end
end
