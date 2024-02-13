defmodule AiQuizz.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AiQuizzWeb.Telemetry,
      AiQuizz.Repo,
      {DNSCluster, query: Application.get_env(:ai_quizz, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AiQuizz.PubSub},
      AiQuizzWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: AiQuizz.Finch},
      # Start a worker by calling: AiQuizz.Worker.start_link(arg)
      # {AiQuizz.Worker, arg},
      AiQuizz.Games.Supervisor,
      # Start to serve requests, typically the last entry
      AiQuizzWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AiQuizz.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AiQuizzWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
