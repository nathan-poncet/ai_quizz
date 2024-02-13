defmodule AiQuizz.Repo do
  use Ecto.Repo,
    otp_app: :ai_quizz,
    adapter: Ecto.Adapters.Postgres
end
