defmodule PingPong.Producer do
  @moduledoc """
  Sends pings to consumer processes
  """
  use GenServer

  alias PingPong.Consumer

  @initial %{current: 0}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def send_ping(server \\ __MODULE__) do
    GenServer.call(server, :send_ping)
  end

  def get_counts(server \\ __MODULE__) do
    GenServer.call(server, :get_counts)
  end

  def init(_args) do
    :net_kernel.monitor_nodes(true)
    {:ok, @initial}
  end

  def handle_call(:send_ping, _from, data) do
    GenServer.abcast(Consumer, {:ping, data.current + 1, Node.self()})
    {:reply, :ok, %{data | current: data.current + 1}}
  end

  def handle_call(:get_counts, _from, data) do
    {replies, _} = GenServer.multi_call(Consumer, :get_pings)
  
    map = 
      replies
      |> Enum.into([])
      |> update_in([Access.all(), Access.elem(1)], fn r -> 
        r
        |> Map.values()
        |> Enum.sum()
      end)
      |> Enum.into(%{})

    {:reply, map, data}
  end

  # Don't remove me :)
  def handle_call(:flush, _, _) do
    {:reply, :ok, @initial}
  end

  def handle_info(msg, data) do
    case msg do
      {:nodeup, node} ->
        GenServer.abcast([node], Consumer, {:ping, data.current, Node.self()})

      _ ->
        # Do Nothing
        nil
    end

    {:noreply, data}
  end
end

