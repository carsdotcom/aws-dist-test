defmodule Engine.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Services.Database, [[]]}
      # {Services.Todos, [[]]},
    ]

    IO.puts("###! about to register")
    Services.Registry.add(Services.Todos, self())
    IO.puts("###! registered")

    opts = [strategy: :one_for_one, name: Engine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
