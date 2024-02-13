defmodule AiQuizz.Games.SupervisorTest do
  use ExUnit.Case, async: true

  test "children process is restarted on failure" do
    # Get the PID of the child process
    [child_pid | _tail] =
      children =
      Supervisor.which_children(AiQuizz.Games.Supervisor) |> Enum.map(&elem(&1, 1))

    # Kill the child process to simulate a failure
    Process.exit(child_pid, :kill)

    # Allow some time for the supervisor to restart the child
    :timer.sleep(100)

    # Check that the child process has been restarted
    [new_child_pid | _tail] =
      new_children =
      Supervisor.which_children(AiQuizz.Games.Supervisor) |> Enum.map(&elem(&1, 1))

    # The PID should be different if the process was restarted
    assert new_child_pid != child_pid
    assert length(children) == length(new_children)
  end
end
