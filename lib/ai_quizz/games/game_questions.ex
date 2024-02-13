defmodule AiQuizz.Games.GameQuestions do
  alias AiQuizz.Games.GameQuestion

  def generate(params) do
    %{topic: topic, difficulty: difficulty, nb_questions: nb_questions} = params

    {:ok, res} =
      OpenAI.chat_completion(
        model: "gpt-3.5-turbo-1106",
        response_format: %{type: "json_object"},
        messages: [
          %{
            role: "system",
            content: "
            You are a quizz expert capable of generating quiz questions based on specified topics and difficulty levels.
            Here all difficulty levels: easy, medium, hard, very hard, impossible.
            For each question, you will provide 4 possible answers including the correct one.
            respond with a json object like this exemple:
            questions: [{
              question: 'What is the capital of France?',
              options: ['Paris', 'London', 'Berlin', 'Madrid'],
              answer: 'Paris'
            }]
            "
          },
          %{
            role: "user",
            content: "
            topic: #{topic}
            difficulty: #{difficulty}
            nb_questions: #{nb_questions}
            "
          }
        ]
      )

    [choice | _] = res.choices

    #  Parse the response
    {:ok, decoded_obj} = Jason.decode(choice["message"]["content"])

    questions = decoded_obj["questions"]

    Enum.map(questions, fn question ->
      %GameQuestion{
        question: question["question"],
        options: question["options"],
        answer: question["answer"]
      }
    end)
  end
end
