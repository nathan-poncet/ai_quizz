defmodule AiQuizz.GamesTest do
  use ExUnit.Case

  alias AiQuizz.Games
  alias AiQuizz.Games.Game

  test "create_game" do
    assert {:ok, %Game{}} =
             Games.create_game(%{
               topic: "Maths",
               difficulty: :easy,
               nb_questions: 2
             })
  end
end
