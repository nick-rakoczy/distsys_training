defmodule PingPong.Producer do
  @moduledoc """
  Sends pings to consumer processes
  """
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def send_ping do
    GenServer.call(__MODULE__, :send_ping)
  end

  def get_counts do
    GenServer.call(__MODULE__, :get_counts)
  end

  def init(_args) do
    {:ok, %{refs: %{}, count: 0}}
  end

  def handle_call(:send_ping, _from, data) do
    # TODO - Send a ping to all consumer processes
    GenServer.abcast(PingPong.Consumer, :ping)

    {:reply, :ok, update_in(data, [:count], & &1+1)}
  end

  def handle_call(:get_counts, _from, data) do
    # TODO - Get the count from each consumer
    # map = %{}
    {replies, _bad_nodes} = GenServer.multi_call(PingPong.Consumer, :get_pings)
    map = Enum.into(replies, %{})

    {:reply, map, data}
  end

  def handle_call(:hiya, {pid, _}, data) do
    # TODO - Monitor consumers
    ref = Process.monitor(pid)

    {:reply, {:ok, data.count}, put_in(data, [:refs, ref], pid)}
  end

  def handle_info(msg, data) do
    IO.inspect(msg, label: "Received info message")
    {:noreply, data}
  end
end

