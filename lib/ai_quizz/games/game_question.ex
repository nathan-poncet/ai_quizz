defmodule AiQuizz.Games.GameQuestion do
  use Ecto.Schema

  @type t :: %__MODULE__{}

  embedded_schema do
    field :advice, :string
    field :answer, :string
    field :explanation, :string
    field :options, {:array, :string}
    field :question, :string
    field :time_limit, :integer
  end
end
