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
        <.button :if={@game.status == :lobby} phx-click="start" class="flex-1">
          Start
        </.button>

        <.button
          :if={@game.status == :in_result and @game.current_question < length(@game.questions) - 1}
          phx-click="next_question"
          class="flex-1"
        >
          Next Question
        </.button>

        <.button
          :if={@game.status == :in_result and @game.current_question >= length(@game.questions) - 1}
          phx-click="finish"
          class="flex-1"
        >
          Finish
        </.button>
      </div>
    </div>
    """
  end

  @doc """
  Renders the game question.
  """
  attr :game, Game, required: true
  attr :current_question, :map, required: true
  attr :response, :string, required: true

  @spec question(map) :: Phoenix.LiveView.Rendered.t()
  def question(assigns) do
    ~H"""
    <div
      :if={@game.status in [:in_play_question, :in_play_response, :in_result]}
      class="flex flex-row items-center justify-center"
    >
      <div class="text-4xl font-bold">
        <%= @current_question.question %>
      </div>
    </div>

    <%!-- Spacer --%>
    <div class="h-8"></div>

    <div :if={@game.status in [:in_play_response, :in_result]} class="grid grid-cols-2 gap-2">
      <button
        :for={option <- @current_question.options}
        phx-click="answer"
        phx-value-answer={option}
        class={[
          "text-4xl font-bold p-4 border border-black	rounded",
          @response == option && "bg-black text-white",
          @game.status == :in_result && "cursor-default",
          @game.status == :in_result && @current_question.answer == option && "bg-green-400",
          @game.status == :in_result && @response == option && @current_question.answer != option &&
            "bg-red-400"
        ]}
      >
        <%= option %>
      </button>
    </div>
    """
  end

  @doc """
  Renders users response.
  """
  attr :game, Game, required: true
  attr :player_id, :integer, required: true

  @spec response(map) :: Phoenix.LiveView.Rendered.t()
  def response(assigns) do
    ~H"""
    <div :if={@game.status == :in_result}>
      <div class="text-4xl font-bold">Responses</div>
      <div :for={player <- @game.players} class="flex flex-row items-center justify-center">
        <div class="flex-1 text-lg decoration-2 truncate">
          <%= if player.id == @player_id, do: "You", else: player.username %>
        </div>

        <div class="flex-1 text-lg decoration-2 truncate">
          <%= Enum.at(player.answers, @game.current_question).value %>
        </div>

        <div class="flex-1 text-lg decoration-2 truncate">
          <%= player.score %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders users scores.
  """
  attr :game, Game, required: true

  @spec score(map) :: Phoenix.LiveView.Rendered.t()
  def score(assigns) do
    ~H"""
    <div :if={@game.status == :finished}>
      <div class="text-4xl font-bold">Score</div>
      <div
        :for={player <- @game.players |> Enum.sort_by(& &1.score, &>=/2)}
        class="flex flex-row items-center justify-center"
      >
        <div class="flex-1 text-lg decoration-2 truncate">
          <%= player.username %>
        </div>

        <div class="flex-1 text-lg decoration-2 truncate">
          <%= player.score %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the game timer.
  """
  attr :timer, :integer, required: true

  @spec timer(map) :: Phoenix.LiveView.Rendered.t()
  def timer(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center">
      <div class="text-4xl font-bold">
        <%= @timer %>
      </div>
    </div>
    """
  end
end
