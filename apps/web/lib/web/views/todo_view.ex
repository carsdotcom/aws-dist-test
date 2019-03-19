defmodule ExampleWeb.TodoView do
  use ExampleWeb, :view

  def render("list.json", %{data: todos}) when is_list(todos) do
    for todo <- todos do
      render("show.json", todo)
    end
  end

  def render("show.json", todo) do
    todo
    |> IO.inspect()
    |> Map.take([:id, :title, :completed])
  end
end
