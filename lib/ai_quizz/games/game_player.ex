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
    field :status, Ecto.Enum, values: [:waiting, :playing], default: :waiting
  end

  @spec add_answer(GamePlayer.t(), String.t()) :: {:ok, GamePlayer.t()} | {:error, atom()}
  def add_answer(%GamePlayer{status: :playing} = player, answer),
    do: {:ok, %GamePlayer{player | answers: player.answers ++ [answer]}}

  def add_answer(%GamePlayer{}, _answer),
    do: {:error, :player_is_not_playing}

  @spec new(String.t(), String.t(), String.t()) :: GamePlayer.t()
  def new(user_id, socket_id, username) do
    %GamePlayer{id: uuid(), user_id: user_id, socket_id: socket_id, username: username}
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
