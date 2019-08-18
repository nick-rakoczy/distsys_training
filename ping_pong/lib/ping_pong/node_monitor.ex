defmodule PingPong.NodeMonitor do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def alive_nodes(server) do
    GenServer.call(server, :get_alive_nodes)
  end

  def init(_args) do
    # TODO - Set up node monitoring here
    :net_kernel.monitor_nodes(true)
    {:ok, %{nodes: []}, {:continue, :send_hiya}}
  end

  def handle_continue(:send_hiya, data) do
    GenServer.abcast(__MODULE__, {:hiya, Node.self()})
    {:noreply, data}
  end

  def handle_cast({:hiya, node}, data) do
    {:noreply, %{data | nodes: [node | data.nodes]}}
  end

  def handle_call(:get_alive_nodes, _from, data) do
    {:reply, data.nodes, data}
  end

  def handle_info(msg, data) do
    # Update handle_info to listen for node up and down events.
    case msg do
      {:nodeup, name} ->
        GenServer.cast({__MODULE__, name}, {:hiya, Node.self()})
        {:noreply, %{data | nodes: [name | data.nodes]}}

      {:nodedown, name} ->
        {:noreply, %{data | nodes: data.nodes -- [name]}}

      _ ->
        {:noreply, data}
    end
    # {:noreply, data}
  end
end
