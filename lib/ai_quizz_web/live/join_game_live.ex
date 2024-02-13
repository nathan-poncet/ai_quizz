defmodule AiQuizzWeb.JoinGameLive do
  use AiQuizzWeb, :live_view

  require Logger

  alias AiQuizz.Games

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-full">
      <.form for={@form} id="join_game_form" phx-submit="submit" class="space-y-4">
        <.input field={@form[:id]} type="text" label="Game ID" required />
        <.button phx-disable-with="Joining game..." class="w-full">
          Join game
        </.button>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{"id" => ""}, as: :join_game)

    {:ok, assign(socket, form: form) |> assign(:counter, 0), temporary_assigns: [form: form]}
  end

  def handle_event("submit", %{"join_game" => %{"id" => id}}, socket) do
    Logger.debug("Joining gameeeeee #{id}", game_id: id)

    case Games.get_game(id) do
      {:ok, game} ->
        Logger.debug("Joining game #{id}", game_id: id)
        {:noreply, push_navigate(socket, to: ~p"/games/#{game.code}")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Game with id: '#{id}' doesn't exist")}
    end
  end
end
