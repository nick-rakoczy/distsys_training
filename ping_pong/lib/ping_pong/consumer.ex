defmodule PingPong.Consumer do
  @moduledoc """
  Consumes pings sent from a producer process
  """
  use GenServer

  alias PingPong.Producer

  @initial %{count: 0}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def ping_count(server \\ __MODULE__) do
    GenServer.call(server, :get_pings)
  end

  def init(_args) do
    Process.send_after(self(), :checkin, 200)
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

  def handle_info(:checkin, data) do
    GenServer.multi_call(Producer, :hiya)

    {:noreply, data}
  end

  def handle_info(msg, data) do
    case msg do
      {:nodeup, node} ->
        Process.send_after(self(), {:checkin, node}, 200)
        {:noreply, data}

      _ ->
        {:noreply, data}
    end
  end
end
