defmodule AiQuizzWeb.GameComponents do
  @moduledoc """
  Provides UI components for the game screen.
  """

  use AiQuizzWeb, :html
  alias AiQuizz.Games.Game

  @doc """
  Renders the game bottom app bar.
  """
  attr :game, Game, required: true

  @spec bottom_app_bar(map) :: Phoenix.LiveView.Rendered.t()
  def bottom_app_bar(assigns) do
    ~H"""
    <div class="fixed left-0 right-0 bottom-0 w-full bg-white shadow-lg">
      <div class="flex flex-row items-center justify-between px-4 py-2">
        <.button phx-click="start">
          Start
        </.button>

        <.button phx-click="next_question">
          Next Question
        </.button>
      </div>
    </div>
    """
  end
end
