defmodule AiQuizz.Games.GamePlayer do
  alias AiQuizz.Games.Game
  alias AiQuizz.Games.GamePlayer
  use Ecto.Schema
  import Ecto.Changeset

  @id_length 16

  @type t :: %__MODULE__{}

  embedded_schema do
    field :score, :integer, default: 0
    field :socket_id, :string, default: ""
    field :user_id, :string, default: ""
    field :username, :string, default: ""
    embeds_many :answers, Answer
  end

  defmodule Answer do
    use Ecto.Schema

    @type t :: %__MODULE__{}

    embedded_schema do
      field :value, :string, default: nil
      field :time, :integer, default: 0
      field :score, :integer, default: 0
      field :status, Ecto.Enum, values: [:pending, :correct, :wrong], default: :pending
    end
    
    @spec new() :: Answer.t()
    def new() do
      %Answer{}
    end
  end

  @spec add_answer(GamePlayer.t(), Integer.t(), Answer.t()) :: GamePlayer.t()
  def add_answer(%GamePlayer{} = player, current_question, answer) do
    case(Enum.at(player.answers, current_question)) do
      %Answer{value: nil} ->
        %GamePlayer{player | answers: List.replace_at(player.answers, current_question, answer)}

      _ ->
        player
    end
  end

  @spec new(Game.t(), GamePlayer.t()) :: GamePlayer.t()
  def new(%Game{} = game, %GamePlayer{} = player) do
    answers = Enum.map(1..length(game.questions), fn _ -> %Answer{} end)
    %GamePlayer{player | id: uuid(), answers: answers}
  end

  @spec registration_changeset(GamePlayer.t(), map) :: Ecto.Changeset.t()
  def registration_changeset(%GamePlayer{} = player, attrs) do
    player
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end

  @spec winning_streak(GamePlayer.t()) :: integer
  def winning_streak(%GamePlayer{} = player) do
    {streak, _is_cut} =
      player.answers
      |> Enum.filter(&(&1 != nil))
      |> Enum.reverse()
      |> Enum.reduce({0, false}, fn answer, {streak, is_cut} ->
        case {answer.status, is_cut} do
          {:correct, false} -> {streak + 1, is_cut}
          _ -> {streak, true}
        end
      end)

    streak
  end

  defp uuid do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @id_length)
  end
end
