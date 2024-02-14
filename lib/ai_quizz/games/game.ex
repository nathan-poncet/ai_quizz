defmodule AiQuizz.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias AiQuizz.Games.GamePlayer.Answer
  alias AiQuizz.Games.GamePlayers
  alias AiQuizz.Games.{Game, GamePlayer, GameQuestion, GameQuestions}

  @id_length 16

  @type t :: %__MODULE__{}

  embedded_schema do
    field :code, :string
    field :current_question, :integer, default: 0
    field :difficulty, Ecto.Enum, values: [:easy, :medium, :hard, :genius, :godlike]
    field :nb_questions, :integer

    field :status, Ecto.Enum,
      values: [:lobby, :in_play_question, :in_play_response, :in_result, :finished],
      default: :lobby

    field :timer, :integer, default: 0
    field :timer_start, :integer, default: 0
    field :time_per_question, :integer, default: 5
    field :time_to_answer, :integer, default: 5
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
  @spec join(Game.t(), GamePlayer.t()) :: {:ok, Game.t(), String.t()} | {:error, atom()}
  def join(%Game{players: players} = game, %GamePlayer{} = player_params) do
    player = GamePlayer.new(game, player_params)

    case GamePlayers.add_player(players, player) do
      {:ok, new_players, new_player} ->
        {:ok, %Game{game | players: new_players}, new_player.id}

      {:error, reason} ->
        {:error, reason}
    end
  end

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
      when current_question < length(questions) - 1 and
             owner_player.id == player_id do
    {:ok,
     %Game{
       game
       | current_question: current_question + 1,
         status: :in_play_question,
         timer: game.time_per_question
     }}
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
    %Game{game | timer: game.time_to_answer, status: :in_play_response}
  end

  def next_status(%Game{timer: 0, status: :in_play_response} = game) do
    %Game{game | status: :in_result}
  end

  @doc """
  Create a new game.
  """
  @spec register(map()) :: Game.t()
  def register(%{topic: topic, difficulty: difficulty, nb_questions: nb_questions} = params) do
    %Game{
      code: uuid(),
      topic: topic,
      difficulty: difficulty,
      nb_questions: nb_questions,
      questions: GameQuestions.generate(params)
    }
  end

  @doc """
  Start the game.
  """
  @spec start(Game.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def start(%Game{players: [game_owner | _tail], status: :lobby} = game, player_id)
      when game_owner.id == player_id do
    {:ok, %Game{game | status: :in_play_question, timer: game.time_per_question}}
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
      :topic
    ])
    |> validate_required([
      :difficulty,
      :nb_questions,
      :topic
    ])
    |> validate_number(:nb_questions, greater_than_or_equal_to: 1)
    |> validate_length(:topic, max: 160)
  end

  @doc """
  Update the game.
  """
  def update_changeset(game, attrs) do
    game
    |> cast(attrs, [
      :time_per_question,
      :time_to_answer
    ])
    |> validate_required([
      :time_per_question,
      :time_to_answer
    ])
    |> validate_number(:time_per_question, greater_than_or_equal_to: 0)
    |> validate_number(:time_to_answer, greater_than_or_equal_to: 0)
  end

  # Private functions

  @spec add_answer(Game.t(), String.t(), String.t()) :: Game.t()
  defp add_answer(%Game{players: players} = game, player_id, answer) do
    now = :os.system_time(:millisecond)
    time = now - game.timer_start
    is_correct = answer == Enum.at(game.questions, game.current_question).answer
    status = if is_correct, do: :correct, else: :wrong

    game_player_answer = %Answer{time: time, status: status, value: answer}

    new_players =
      GamePlayers.add_answer(players, player_id, game.current_question, game_player_answer)

    %Game{game | players: new_players}
  end

  # Private function to calculate the score for a player

  @spec uuid() :: String.t()
  defp uuid() do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @id_length)
  end
end
