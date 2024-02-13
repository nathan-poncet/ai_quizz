defmodule AiQuizz.Games.GamePlayerTest do
  use ExUnit.Case, async: true

  alias AiQuizz.Games.GamePlayer

  test "add_answer/2 adds an answer to the player" do
    player = %GamePlayer{status: :playing}

    assert {:ok, %GamePlayer{answers: ["answer"], status: :playing}} =
             GamePlayer.add_answer(player, "answer")
  end

  test "add_answer/2 returns an error if the player is not playing" do
    player = %GamePlayer{status: :waiting}
    assert {:error, :player_is_not_playing} = GamePlayer.add_answer(player, "answer")
  end
end
