defmodule AiQuizz.Games.ServerTest do
  alias AiQuizz.Games.GamePlayer
  alias AiQuizz.Games.GameQuestions
  alias AiQuizz.Games.Game
  alias AiQuizz.Games.GameQuestion
  alias AiQuizz.Games.Server

  use ExUnit.Case, async: true
  import Mock

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

  test "are permanent workers" do
    assert Supervisor.child_spec(Server, []).restart == :temporary
  end

  test "start_link" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    assert is_pid(pid)
  end

  test "where is" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    game = Server.game(pid)

    assert pid == Server.whereis(game.code)
  end

  test "start" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    assert {:ok, game} = Server.start(pid)
    assert game.status == :in_play
  end

  test "join" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    assert {:ok, game} = Server.join(pid, "player_id", self())
    assert game.players == [%GamePlayer{id: "player_id", answers: [], status: :playing}]
  end

  test "join when game has already started" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    {:ok, _game} = Server.start(pid)

    assert {:ok, _game} = Server.join(pid, "player_id", self())
  end

  test "game" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    game = Server.game(pid)

    expected_game = %Game{
      code: game.code,
      current_question: 0,
      difficulty: :easy,
      nb_questions: 2,
      players: [],
      questions: [
        %GameQuestion{},
        %GameQuestion{}
      ],
      status: :lobby,
      topic: "Maths"
    }

    assert expected_game == Server.game(pid)
  end

  test "answer" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    {:ok, _game} = Server.join(pid, "player_id", self())
    {:ok, _game} = Server.start(pid)
    {:ok, game} = Server.answer(pid, "player_id", "answer")

    assert [%GamePlayer{id: "player_id", answers: ["answer"], status: :playing}] == game.players
  end

  test "answer when player is not in the game" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    {:ok, _game} = Server.join(pid, "player_id", self())
    {:ok, _game} = Server.start(pid)

    assert {:error, :player_is_not_in_the_game} == Server.answer(pid, "player_id_2", "answer")
  end

  test "answer when game is not in play" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    assert {:error, :game_is_not_in_play} == Server.answer(pid, "player_id", "answer")
  end
end
