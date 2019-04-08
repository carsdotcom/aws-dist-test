defmodule Service.TestClient do
  @moduledoc """
  Test Client simply holds a couple of functions that test out cross-node communication.
  """

  @doc """
  First example we discussed with Jose performs a `Node.spawn_link/5`, sending the current
   PID and mfargs to the receiver (Engine on another node), and provides a callback
  mechanism that works as a send-receive block.
  """
  def test(node_name) do
    Node.spawn_link(node_name, ServiceLayer, :callback, [self(), Engine.Todo, :all, []])

    receive do
      {:ok, reply} ->
        IO.puts("got a reply")
        reply
    end
  end

  @doc """
  Second example we discuss with Jose leverages a Task.Supervisor which apparently handles all
  of the callback boilerplate from the first example (TestClient.test/1).

  We will need to look at how to refactor this - at least - I want to understand how the TaskSupervisor
  is coded to understand where we are getting the callback code for free.
  """
  def test_task(node_name) do
    task = Task.Supervisor.async({Services.TaskSupervisor, node_name}, Engine.Todo, :all, [])

    Task.await(task, 1_000_000)
  end
end
