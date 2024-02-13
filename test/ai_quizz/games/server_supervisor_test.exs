defmodule AiQuizz.Games.ServerSupervisorTest do
  use ExUnit.Case
  import Mock

  alias AiQuizz.Games.{GameQuestion, GameQuestions}

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

  test "start_child/1 starts a new game server" do
    children = DynamicSupervisor.which_children(AiQuizz.Games.ServerSupervisor)
    assert length(children) == 0

    {:ok, child_pid} =
      AiQuizz.Games.ServerSupervisor.start_child(%{
        topic: "Maths",
        difficulty: :hard,
        nb_questions: 2
      })

    children = DynamicSupervisor.which_children(AiQuizz.Games.ServerSupervisor)
    assert length(children) == 1

    Process.exit(child_pid, :kill)

    :timer.sleep(100)

    children = DynamicSupervisor.which_children(AiQuizz.Games.ServerSupervisor)
    assert length(children) == 0
  end
end
