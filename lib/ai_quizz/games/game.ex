defmodule AiQuizz.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  require Logger
  alias AiQuizz.Games.GamePlayer.Answer
  alias AiQuizz.Games.GamePlayers
  alias AiQuizz.Games.{Game, GamePlayer, GameQuestion, GameQuestions}

  @id_length 16
  @point_per_answer 1000

  @type t :: %__MODULE__{}

  embedded_schema do
    field :code, :string
    field :current_question, :integer, default: 0
    field :difficulty, Ecto.Enum, values: [:easy, :medium, :hard, :genius, :godlike]
    field :nb_questions, :integer
    field :password, :string, default: nil

    field :status, Ecto.Enum,
      values: [:lobby, :in_play_question, :in_play_response, :in_result, :finished],
      default: :lobby

    field :timer, :integer, default: 0
    field :timestamp, :integer, default: 0
    field :time_display_question, :integer, default: 5
    field :topic, :string

    embeds_many :players, GamePlayer
    embeds_many :questions, GameQuestion
  end

  @doc """
  Add an answer for a player to the game.
  """
  @spec answer(Game.t(), String.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def answer(%Game{players: players, status: :in_play_response} = game, player_id, answer) do
    case Enum.find(players, fn player -> player.id == player_id end) do
      nil ->
        {:error, :player_is_not_in_the_game}

      _player ->
        {:ok, add_answer(game, player_id, answer)}
    end
  end

  def answer(%Game{status: :in_result} = _game, _player_id, _answer),
    do: {:error, :timeout}

  def answer(_game, _player_id, _answer),
    do: {:error, :wrong_status}

  @doc """
  Finish the game.
  """
  @spec finish(Game.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def finish(
        %Game{
          current_question: current_question,
          players: [game_owner | _tail],
          questions: questions,
          status: :in_result
        } = game,
        player_id
      )
      when game_owner.id == player_id and current_question >= length(questions) - 1,
      do: {:ok, %Game{game | status: :finished}}

  def finish(%Game{players: [game_owner | _tail]}, player_id)
      when game_owner.id != player_id,
      do: {:error, :only_game_owner_is_allow_to_end_game}

  def finish(%Game{}, _player_id),
    do: {:error, :not_allowed_to_end_game}

  @doc """
  Join the game.
  """
  @spec join(Game.t(), String.t(), GamePlayer.t()) ::
          {:ok, Game.t(), String.t()} | {:error, atom()}
  def join(%Game{password: game_password} = game, password, %GamePlayer{} = player_params)
      when game_password == password or game_password == nil do
    %Game{players: players} = game
    player = GamePlayer.new(game, player_params)

    case GamePlayers.add_player(players, player) do
      {:ok, new_players, new_player} ->
        {:ok, %Game{game | players: new_players}, new_player.id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def join(_game, _player_params, _password),
    do: {:error, :wrong_password}

  @doc """
  Next question.
  """
  @spec next_question(Game.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def next_question(
        %Game{
          current_question: current_question,
          players: [owner_player | _],
          questions: questions,
          status: :in_result
        } = game,
        player_id
      )
      when current_question < length(questions) - 1 and owner_player.id == player_id do
    %Game{time_display_question: timer} = game
    current_question = current_question + 1

    {:ok,
     %Game{game | current_question: current_question, status: :in_play_question, timer: timer}}
  end

  def next_question(
        %Game{players: [owner_player | _], status: :in_result},
        player_id
      )
      when owner_player.id != player_id,
      do: {:error, :you_are_not_the_owner_of_the_game}

  def next_question(
        %Game{
          current_question: current_question,
          questions: questions,
          status: :in_result
        },
        _player_id
      )
      when current_question >= length(questions) - 1,
      do: {:error, :no_more_questions}

  def next_question(%Game{} = _game, _player_id), do: {:error, :game_is_not_in_play}

  @doc """
  Next Status
  """
  @spec next_status(Game.t()) :: Game.t()
  def next_status(%Game{timer: 0, status: :in_play_question} = game) do
    timestamp = :os.system_time(:millisecond)
    %Game{current_question: current_question, questions: questions} = game
    %GameQuestion{time_limit: timer} = Enum.at(questions, current_question)

    %Game{game | status: :in_play_response, timer: timer, timestamp: timestamp}
  end

  def next_status(%Game{timer: 0, status: :in_play_response} = game) do
    %Game{game | status: :in_result}
  end

  @doc """
  Create a new game.
  """
  @spec register(map()) :: Game.t()
  def register(
        %{topic: topic, difficulty: difficulty, nb_questions: nb_questions} =
          params
      ) do
    password =
      if Map.has_key?(params, :password),
        do: params.password,
        else: nil

    %Game{
      code: uuid(),
      topic: topic,
      difficulty: difficulty,
      nb_questions: nb_questions,
      password: password,
      questions: GameQuestions.generate(params)
    }
  end

  @doc """
  Start the game.
  """
  @spec start(Game.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def start(%Game{players: [game_owner | _tail], status: :lobby} = game, player_id)
      when game_owner.id == player_id do
    %Game{time_display_question: timer} = game

    {:ok, %Game{game | status: :in_play_question, timer: timer}}
  end

  def start(%Game{players: [game_owner | _tail]}, player_id)
      when game_owner.id != player_id,
      do: {:error, :only_game_owner_is_allow_to_start_game}

  def start(%Game{status: status}, _player_id) when status != :lobby,
    do: {:error, :game_is_not_in_lobby}

  @doc """
  Update the registration game.
  """
  def registration_changeset(game, attrs) do
    game
    |> cast(attrs, [
      :difficulty,
      :nb_questions,
      :topic,
      :password
    ])
    |> validate_required([
      :difficulty,
      :nb_questions,
      :topic
    ])
    |> validate_number(:nb_questions, greater_than_or_equal_to: 1)
    |> validate_length(:topic, max: 160)
    |> validate_length(:password, max: 160)
  end

  # Private functions

  @spec add_answer(Game.t(), String.t(), String.t()) :: Game.t()
  defp add_answer(%Game{} = game, player_id, answer) do
    %Game{
      current_question: current_question,
      players: players,
      questions: questions,
      timestamp: timestamp
    } = game

    now = :os.system_time(:millisecond)
    time = now - timestamp
    is_correct = answer == Enum.at(questions, current_question).answer
    status = if is_correct, do: :correct, else: :wrong

    player = Enum.find(players, fn player -> player.id == player_id end)
    winning_streak = GamePlayer.winning_streak(player)
    %GameQuestion{time_limit: time_limit} = Enum.at(questions, current_question)

    score =
      calculate_score(%{
        status: status,
        time: time,
        time_limit: time_limit,
        winning_streak: winning_streak
      })

    answer = %Answer{score: score, status: status, time: time, value: answer}

    new_players = GamePlayers.add_answer(players, player_id, current_question, answer)

    if is_last_player_answered?(new_players, current_question) do
      %Game{game | players: new_players, timer: 0}
    else
      %Game{game | players: new_players}
    end
  end

  # calculate the score for a player
  @spec calculate_score(map()) :: Integer.t()
  defp calculate_score(%{
         status: :correct,
         time: time,
         time_limit: time_limit,
         winning_streak: winning_streak
       }) do
    @point_per_answer * (1 - time * 0.5 / (time_limit * 1000)) *
      (1 + winning_streak ** 1.3 * 0.1)
  end

  defp calculate_score(_params) do
    0
  end

  defp is_last_player_answered?(players, current_question) do
    Enum.all?(players, fn player -> Enum.at(player.answers, current_question).value != nil end)
  end

  @spec uuid() :: String.t()
  defp uuid() do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @id_length)
  end
end
