defmodule AiQuizz.Games.GameTopicsTest do
  alias AiQuizz.Games.GameTopics
  use ExUnit.Case

  test "generate/1 generates a list of topics" do
    gen_topics = GameTopics.generate(["maths", "history"])

    gen_topics = gen_topics |> Enum.map(fn topic -> topic["title"] end)

    assert gen_topics not in ["maths", "history"]
  end
end
