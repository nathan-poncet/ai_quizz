defmodule AiQuizz.Games.ServerSupervisor do
  alias AiQuizz.Games.Server
  use DynamicSupervisor

  require Logger

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(params) do
    Logger.debug("Starting game dynamic server supervisor for game")

    DynamicSupervisor.start_child(__MODULE__, {Server, params: params})
  end

  def terminate_child(game_server_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, game_server_pid)
  end
end
