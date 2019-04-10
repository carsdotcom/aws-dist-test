defmodule Services.Registry.Tracker do
  # This module provies synchronization of the registry across nodes
  @moduledoc false
  @behaviour Phoenix.Tracker

  @spec add(type :: term, pid) :: {:ok, String.t()}
  def add(type, pid) do
    IO.puts("in add")
    Phoenix.Tracker.track(__MODULE__, pid, type, node(), %{})
  end

  @spec remove(type :: term, pid) :: {:ok, String.t()}
  def remove(type, pid) do
    IO.puts("in remove")
    Phoenix.Tracker.untrack(__MODULE__, pid, type, node())
  end

  @spec list(type :: term) :: [{node, map}]
  def list(type) do
    Phoenix.Tracker.list(__MODULE__, type)
  end

  @spec find(type :: term) :: {:ok, node} | {:error, :service_unavailable}
  def find(type) do
    with [{_, service_nodes}] <- :ets.lookup(__MODULE__.Types, type) do
      {:ok, Enum.random(service_nodes)}
    else
      _ ->
        {:error, :service_unavailable}
    end
  end

  def child_spec(args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, args}, type: :worker}
  end

  @doc false
  def start_link(opts \\ []) when is_list(opts) do
    full_opts = Keyword.merge(opts, name: __MODULE__, pubsub_server: Services.Registry.PubSub)
    Phoenix.Tracker.start_link(__MODULE__, full_opts, full_opts)
  end

  @doc false
  def init(opts) when is_list(opts) do
    :ets.new(__MODULE__.Types, [:public, :set, :named_table])
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server}}
  end

  @doc false
  def handle_diff(diff, state) do
    IO.puts("Handle Diff")
    IO.puts("IM A DIFF => #{inspect(diff)}")
    IO.puts("IM A STATE => #{inspect(state)}")

    for {topic, {joins, leaves}} <- diff do
      for {node, meta} <- joins do
        IO.puts("presence join: node \"#{node}\" with meta #{inspect(meta)}")

        IO.puts("%%%%%%%%%%% #{inspect(:ets.lookup(__MODULE__.Types, Services.Todos))}")

        case :ets.lookup(__MODULE__.Types, Services.Todos) do
          [{_, []}] ->
            IO.puts("I DONT KNOW WHY IM HERE")
            IO.puts("I AM THOR")
            :ets.insert(__MODULE__.Types, {Services.Todos, [node]})
            msg = {:join, node, meta}
            :ok = Phoenix.PubSub.broadcast!(state.pubsub_server, topic, msg)

          [{_, current_nodes}] ->
            IO.puts("SHOULD ONLY BE HERE WHEN 1+ NODES")
            IO.puts("node => #{inspect(node)}")
            IO.puts("current nodes => #{inspect(current_nodes)}")
            :ets.insert(__MODULE__.Types, {Services.Todos, Enum.uniq(current_nodes ++ [node])})
            IO.puts("updated nodes => #{inspect(:ets.lookup(__MODULE__.Types, Services.Todos))}")
            msg = {:join, node, meta}
            :ok = Phoenix.PubSub.broadcast!(state.pubsub_server, topic, msg)

          [] ->
            IO.puts("SHOULD ONLY BE HERE WHEN THERE ARE NO NODES")
            IO.puts("I AM GROOT")
            :ets.insert(__MODULE__.Types, {Services.Todos, [node]})
            msg = {:join, node, meta}
            :ok = Phoenix.PubSub.broadcast!(state.pubsub_server, topic, msg)

          x ->
            IO.puts("I AM THANOS => #{inspect(x)}")
        end
      end

      for {key, meta} <- leaves do
        IO.puts("presence leave: key \"#{key}\" with meta #{inspect(meta)}")

        IO.puts("old_node_list => #{inspect(:ets.lookup(__MODULE__.Types, Services.Todos))}")

        new_node_list =
          :ets.lookup(__MODULE__.Types, Services.Todos)
          |> hd
          |> elem(1)
          |> Enum.filter(fn val -> val != key end)

        IO.puts("new_node_list => #{inspect(new_node_list)}")

        # insert will overwrite since the key exists
        :ets.insert(__MODULE__.Types, {Services.Todos, new_node_list})
        msg = {:leave, key, meta}
        :ok = Phoenix.PubSub.broadcast!(state.pubsub_server, topic, msg)
      end
    end

    {:ok, state}
  end
end
