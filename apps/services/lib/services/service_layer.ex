defmodule ServiceLayer do
  @moduledoc """
  ServiceLayer provides a callback to the caller of the cross-node call.  This simply uses process
  communication (send-receive) to issue the results back to the calling node (the parent).

  This needs support for handling various types of responses.  We will need to identify
  if we want to create a layer between the function results and the callback.  Right now
  this takes whatever is returned from the function and tucks it into an :ok tuple such as
  {:ok, results}.

  Furthermore, not even sure we need this if we use a TaskSupervisor.
  """

  @doc """
  Accepts the parent PID (the caller of the function) and the desired mfargs.  Right now, this function
  is fairly dumb in that it just takes the results of the mfargs execution and tucks it into an :ok tuple
  such as {:ok, results}.

  We will want to make this more robust and determine if we want to create a different response type to
  account for error handling.
  """
  def callback(parent, module, function, args) do
    IO.puts("executing callback from #{inspect(self())} to #{inspect(parent)}")
    send(parent, {:ok, apply(module, function, args)})
  end
end
