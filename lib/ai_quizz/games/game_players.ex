defmodule AiQuizz.Games.GamePlayers do
  alias AiQuizz.Games.GamePlayer

  @doc """
  update the answer of a player.
  """
  @spec add_answer([GamePlayer.t()], String.t(), Integer.t(), Integer.t()) :: [GamePlayer.t()]
  def add_answer(players, player_id, current_question, answer) do
    Enum.map(players, fn player ->
      if player.id == player_id do
        GamePlayer.add_answer(player, current_question, answer)
      else
        player
      end
    end)
  end

  @doc """
  Add a player to the game.
  """
  @spec add_player([GamePlayer.t()], GamePlayer.t()) :: {:ok, [GamePlayer.t()]} | {:error, atom()}
  def add_player(players, %GamePlayer{socket_id: socket_id, username: username} = player)
      when socket_id != "" and username != "" do
    case {
      socket_exists?(players, player),
      user_exists?(players, player),
      username_exists?(players, player)
    } do
      {false, false, false} ->
        players = players ++ [player]
        {:ok, players}

      {true, _, _} ->
        {:error, :socket_is_already_in_the_game}

      {_, true, _} ->
        {:error, :user_is_already_in_the_game}

      {_, _, true} ->
        {:error, :username_is_already_in_the_game}
    end
  end

  def add_player(_players, %GamePlayer{socket_id: ""}),
    do: {:error, :socket_id_not_provided}

  def add_player(_players, %GamePlayer{username: ""}),
    do: {:error, :username_not_provided}

  # Private functions

  @spec socket_exists?([GamePlayer.t()], GamePlayer.t()) :: boolean()
  defp socket_exists?(players, %GamePlayer{socket_id: socket_id}),
    do: Enum.any?(players, &(&1.socket_id == socket_id))

  @spec user_exists?([GamePlayer.t()], GamePlayer.t()) :: boolean()
  defp user_exists?(_players, %GamePlayer{user_id: ""}), do: false

  defp user_exists?(players, %GamePlayer{user_id: user_id}),
    do: Enum.any?(players, &(&1.user_id == user_id))

  @spec username_exists?([GamePlayer.t()], GamePlayer.t()) :: boolean()
  defp username_exists?(players, %GamePlayer{username: username}),
    do: Enum.any?(players, &(&1.username == username))
end
