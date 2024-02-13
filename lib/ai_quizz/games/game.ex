defmodule AiQuizz.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

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
      values: [:lobby, :in_play_question, :in_play_response, :in_result],
      default: :lobby

    field :timer, :integer, default: 0
    field :time_per_question, :integer, default: 10_000
    field :time_to_answer, :integer, default: 30_000
    field :topic, :string

    embeds_many :players, GamePlayer
    embeds_many :questions, GameQuestion
  end

  @doc """
  Add an answer for a player to the game.
  """
  @spec answer(Game.t(), String.t(), Integer.t()) :: {:ok, Game.t()} | {:error, atom()}
  def answer(%Game{players: players, status: :in_play_response} = game, player_id, answer) do
    case Enum.find(players, fn player -> player.id == player_id end) do
      nil ->
        {:error, :player_is_not_in_the_game}

      _player ->
        {:ok, update_answer(game, player_id, answer)}
    end
  end

  def answer(%Game{status: :in_result} = _game, _player_id, _answer),
    do: {:error, :timeout}

  def answer(_game, _player_id, _answer),
    do: {:error, :wrong_status}

  @doc """
  Finish the game.
  """
  @spec finish(Game.t()) :: {:ok, Game.t()} | {:error, atom()}
  def finish(%Game{status: :in_play} = game), do: {:ok, %Game{game | status: :finished}}

  def finish(%Game{}),
    do: {:error, :game_is_not_in_play}

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
      when current_question < length(questions) and
             owner_player.id == player_id do
    {:ok, %Game{game | current_question: current_question + 1}}
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
      when current_question >= length(questions),
      do: {:error, :no_more_questions}

  def next_question(%Game{} = _game, _player_id), do: {:error, :game_is_not_in_play}

  @doc """
  Next Status
  """
  @spec next_status(Game.t()) :: Game.t()
  def next_status(%Game{timer: 0, status: :lobby} = game) do
    %Game{game | timer: game.time_per_question, status: :in_play}
  end

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
    new_players =
      Enum.map(game.players, fn player ->
        %GamePlayer{player | answers: Enum.to_list(1..length(game.questions))}
      end)

    {:ok, %Game{game | players: new_players, status: :in_play}}
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

  @spec update_answer(Game.t(), String.t(), Integer.t()) :: Game.t()
  defp update_answer(%Game{players: players} = game, player_id, answer) do
    new_players =
      GamePlayers.add_answer(players, player_id, game.current_question, answer)

    %Game{game | players: new_players}
  end

  @spec uuid() :: String.t()
  defp uuid() do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @id_length)
  end
end
