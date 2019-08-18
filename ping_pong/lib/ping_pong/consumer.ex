defmodule PingPong.Consumer do
  @moduledoc """
  Consumes pings sent from a producer process
  """
  use GenServer

  @initial %{count: 0}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def ping_count(server) do
    GenServer.call(server, :get_pings)
  end

  def init(_args) do
    {:ok, @initial}
  end

  def handle_call(:get_pings, _from, data) do
    {:reply, data.count, data}
  end

  # We need these for testing. Ignore the warning and do not remove :)
  def handle_call(:flush, _, _) do
    {:reply, :ok, @initial}
  end
  def handle_call(:crash, _from, data) do
    count = 42/0
    {:reply, :ok, %{data | count: count}}
  end

  def handle_cast(:ping, data) do
    {:noreply, %{data | count: data.count + 1}}
  end
end
