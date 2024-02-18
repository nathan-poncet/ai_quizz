defmodule AiQuizzWeb.JoinGameLive do
  use AiQuizzWeb, :live_view

  require Logger

  alias AiQuizz.Games

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-full">
      <.form
        for={@form}
        id="join_game_form"
        phx-submit="save"
        phx-trigger-action={@trigger_submit}
        action={~p"/games/create_or_join"}
        method="post"
        class="space-y-4"
      >
        <.input field={@form[:code]} type="text" label="Code" required />
        <.input field={@form[:password]} type="password" label="Password" />

        <.button phx-disable-with="Joining game..." class="w-full">
          Join game
        </.button>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{"id" => ""}, as: :game)

    {:ok, assign(socket, form: form, trigger_submit: false), temporary_assigns: [form: form]}
  end

  def handle_event("save", %{"game" => %{"code" => code}}, socket) do
    case Games.get_game(code) do
      {:ok, game} ->
        Logger.debug("Joining game #{game.code}", game_code: game.code)
        {:noreply, socket |> assign(trigger_submit: true)}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Game with id: '#{code}' doesn't exist")}
    end
  end
end
