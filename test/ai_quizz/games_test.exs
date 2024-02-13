defmodule AiQuizz.GamesTest do
  use ExUnit.Case
  import Mock

  alias AiQuizz.Games.GameQuestion
  alias AiQuizz.Games
  alias AiQuizz.Games.Game
  alias AiQuizz.Games.GameQuestions

  setup_with_mocks([
    {GameQuestions, [],
     [
       generate: fn %{topic: _, difficulty: _, nb_questions: nb_question} ->
         List.duplicate(%GameQuestion{}, nb_question)
       end
     ]}
  ]) do
    :ok
  end

  test "create_game" do
    assert {:ok, %Game{}} =
             Games.create_game(%{
               topic: "Maths",
               difficulty: :easy,
               nb_questions: 2
             })
  end
end
