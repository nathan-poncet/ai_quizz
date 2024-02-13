defmodule AiQuizz.Games.ServerTest do
  alias AiQuizz.Games.{Game, GamePlayer, GameQuestions, GameQuestion, Server}

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

    assert {:ok, player} = Server.join(pid, "player_user_id", "player_socket", "username")

    game = Server.game(pid)

    assert [
             %GamePlayer{
               answers: [],
               id: player.id,
               user_id: "player_user_id",
               socket_id: "player_socket",
               username: "username"
             }
           ] == game.players
  end

  test "join when game has already started" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    {:ok, _game} = Server.start(pid)

    assert {:ok, _game} = Server.join(pid, "player_user_id", "player_socket", "username")
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

  test "answer when game is not in play" do
    {:ok, pid} =
      Server.start_link(params: %{topic: "Maths", difficulty: :easy, nb_questions: 2})

    assert {:error, :wrong_status} == Server.answer(pid, "player_id", 1)
  end
end
