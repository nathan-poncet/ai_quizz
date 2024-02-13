defmodule AiQuizz.Games.GamePlayerTest do
  use ExUnit.Case, async: true

  alias AiQuizz.Games.GamePlayer

  test "add_answer/2 adds an answer to the player" do
    player = %GamePlayer{answers: [nil]}

    assert %GamePlayer{answers: [1]} = GamePlayer.add_answer(player, 0, 1)
  end
end
