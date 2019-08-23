defmodule PingPong.Producer do
  @moduledoc """
  Sends pings to consumer processes
  """
  use GenServer

  @initial %{current: 0}

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
    :net_kernel.monitor_nodes(true)
    {:ok, @initial}
  end

  def handle_call(:send_ping, _from, data) do
    # TODO - Send a ping to all consumer processes
    ping = {:ping, data.current+1, Node.self()}
    GenServer.abcast(PingPong.Consumer, ping)

    {:reply, :ok, %{data | current: data.current+1}}
  end

  def handle_call(:get_counts, _from, data) do
    # TODO - Get the count from each consumer
    # map = %{}
    {replies, _bad_nodes} = GenServer.multi_call(PingPong.Consumer, :get_pings)
    map = Enum.into(replies, %{})

    {:reply, map, data}
  end

  def handle_call(:flush, _, _) do
    {:reply, :ok, @initial}
  end

  def handle_cast({:hiya, pid}, data) do
    IO.inspect(data, label: "Hiya")
    GenServer.cast(pid, {:ping, data.current, Node.self()})

    {:noreply, data}
  end

  def handle_info({:nodeup, n}, data) do
    GenServer.cast({PingPong.Consumer, n}, {:ping, n, Node.self()})
    {:noreply, data}
  end

  def handle_info(msg, data) do
    {:noreply, data}
  end
end

