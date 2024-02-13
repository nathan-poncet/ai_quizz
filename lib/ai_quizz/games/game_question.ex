defmodule AiQuizz.Games.GameQuestion do
  use Ecto.Schema

  @type t :: %__MODULE__{}

  embedded_schema do
    field :question, :string
    field :options, {:array, :string}
    field :answer, :string
  end
end
