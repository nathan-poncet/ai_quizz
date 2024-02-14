defmodule AiQuizz.Games.GamePlayer do
  alias AiQuizz.Games.GamePlayer
  use Ecto.Schema
  import Ecto.Changeset

  @id_length 16

  @type t :: %__MODULE__{}

  embedded_schema do
    field :socket_id, :string, default: ""
    field :user_id, :string, default: ""
    field :username, :string, default: ""
    field :answers, {:array, :string}, default: []
  end

  @spec add_answer(GamePlayer.t(), Integer.t(), String.t()) :: GamePlayer.t()
  def add_answer(%GamePlayer{} = player, current_question, answer),
    do: %GamePlayer{player | answers: List.replace_at(player.answers, current_question, answer)}

  @spec new(GamePlayer.t()) :: GamePlayer.t()
  def new(%GamePlayer{} = player) do
    %GamePlayer{player | id: uuid()}
  end

  @spec registration_changeset(GamePlayer.t(), map) :: Ecto.Changeset.t()
  def registration_changeset(%GamePlayer{} = player, attrs) do
    player
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end

  defp uuid do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @id_length)
  end
end
