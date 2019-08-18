defmodule PingPong.NodeMonitor do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    # TODO - Set up node monitoring here
    {:ok, %{}}
  end

  def handle_info(_msg, data) do
    # Update handle_info to listen for node up and down events.
    {:noreply, data}
  end
end
