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
            More over, you will provide an advice to the player and an explanation of the answer.
            The last thing, you will provide a time limit in seconds for each question, it should be between 10 and 60 seconds depending of the question's difficulty.
            respond with a json object like this exemple:
            questions: [{
              advice: 'You should know that!',
              answer: 'Paris',
              explanation: 'Paris is the capital of France',
              options: ['Paris', 'London', 'Berlin', 'Madrid'],
              question: 'What is the capital of France?',
              time_limit: 20
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
        advice: question["advice"],
        answer: question["answer"],
        explanation: question["explanation"],
        options: question["options"],
        question: question["question"],
        time_limit: question["time_limit"]
      }
    end)
  end
end
