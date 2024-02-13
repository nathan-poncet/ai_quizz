defmodule AiQuizz.Games.GameQuestionsTest do
  alias AiQuizz.Games.GameQuestion
  alias AiQuizz.Games.GameQuestions
  use ExUnit.Case

  test "generate/1 generates a list of topics" do
    gen_questions =
      GameQuestions.generate(%{topic: "Maths", difficulty: :hard, nb_questions: 2})

    assert [%GameQuestion{}, %GameQuestion{}] = gen_questions
  end
end
