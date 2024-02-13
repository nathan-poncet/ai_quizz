defmodule AiQuizz.Games.GamePlayersTest do
  use ExUnit.Case, async: true

  alias AiQuizz.Games.GamePlayer
  alias AiQuizz.Games.GamePlayers

  test "add_answer/4 adds an answer to the player" do
    players = [%GamePlayer{id: "player_id", answers: [nil]}]

    assert [%GamePlayer{id: "player_id", answers: [1]}] =
             GamePlayers.add_answer(players, "player_id", 0, 1)
  end

  test "add_answer/4 returns an nothing if the player is not playing" do
    players = [%GamePlayer{id: "player_id"}]

    assert [%GamePlayer{id: "player_id"}] =
             GamePlayers.add_answer(players, "wrong_player_id", 0, 1)
  end
end
