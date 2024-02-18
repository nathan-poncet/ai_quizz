defmodule AiQuizzWeb.CreateGameLive do
  require Logger
  alias AiQuizz.Games.Game
  alias AiQuizz.Games
  use AiQuizzWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="create_game" class="container mx-auto space-y-8">
      <.form
        for={@form}
        id="create_game_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/games/create_or_join"}
        method="post"
        class="space-y-4 mx-auto"
      >
        <.input field={@form[:code]} type="text" label="code" />

        <.input field={@form[:topic]} type="text" label="Topic" required />
        <.input
          field={@form[:difficulty]}
          options={[
            {"Easy", :easy},
            {"Medium", :medium},
            {"Hard", :hard},
            {"Genius", :genius},
            {"Godlike", :godlike}
          ]}
          type="select"
          label="Difficulty"
          required
        />

        <.input field={@form[:nb_questions]} type="number" label="Number of questions" required />

        <.input
          label="Private"
          name="is_private"
          phx-click="toggle_private"
          type="checkbox"
          value={@is_private}
        />
        <.input :if={@is_private} field={@form[:password]} type="password" label="Password" required />

        <.button phx-disable-with="Create game..." class="w-full">
          Create Game
        </.button>
      </.form>

      <.async_result :let={topics} assign={@topics}>
        <:loading>
          <p>Loading topics...</p>
        </:loading>
        <:failed :let={_reason}>
          <p>there was an error loading the topics</p>
        </:failed>

        <div class="grid gap-4" style="grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));">
          <article :for={topic <- topics} class="group">
            <img
              alt="Lava"
              src={topic["img"]}
              class="h-56 w-full rounded-xl object-cover shadow-xl transition group-hover:grayscale-[50%]"
            />

            <div class="p-4">
              <a href="#">
                <h3 class="text-lg font-medium text-gray-900"><%= topic["title"] %></h3>
              </a>
            </div>
          </article>
        </div>
      </.async_result>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Games.change_game_registration(%Game{})

    socket =
      socket
      |> assign_async(:topics, fn -> {:ok, %{topics: Games.topics_generate([])}} end)
      |> assign(
        is_private: false,
        form: to_form(changeset),
        trigger_submit: false
      )

    {:ok, socket}
  end

  def handle_event("toggle_private", _, socket) do
    {:noreply, assign(socket, is_private: !socket.assigns.is_private)}
  end

  def handle_event("save", %{"game" => game_params}, socket) do
    case Games.create_game(game_params) do
      {:ok, game} ->
        changeset = Games.change_game_registration(game)

        send(self(), :send_form)

        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  def handle_event("validate", %{"game" => game}, socket) do
    changeset = Games.change_game_registration(%Game{}, game)
    {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :validate)))}
  end

  def handle_info(:send_form, socket) do
    {:noreply, socket |> assign(:trigger_submit, true)}
  end
end
