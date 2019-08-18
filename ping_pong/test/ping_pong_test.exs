defmodule PingPongTest do
  use ExUnit.Case

  alias PingPong.{
    NodeMonitor,
    Consumer,
    Producer,
  }

  setup_all do
    Application.ensure_all_started(:ping_pong)

    :ok
  end

  setup do
    nodes = LocalCluster.start_nodes("ping-pong", 2)
    GenServer.multi_call(Consumer, :flush)

    {:ok, nodes: nodes}
  end

  test "producer sends pings to each connected nodes consumer", %{nodes: nodes} do
    assert :ok == Producer.send_ping()
    assert :ok == Producer.send_ping()
    assert :ok == Producer.send_ping()

    for n <- nodes do
      assert Consumer.ping_count({Consumer, n}) == 3
    end
  end

  test "producer can check the state of each connected consumer", %{nodes: nodes} do
    [n1, n2] = nodes

    assert :ok = Producer.send_ping()
    assert :ok = Producer.send_ping()

    eventually(fn ->
      assert Producer.get_counts() == %{
        n1 => 2,
        n2 => 2,
        Node.self() => 2,
      }
    end)
  end

  @tag :focus
  test "producer can catch up failed consumer's", %{nodes: nodes} do
    # Process.flag(:trap_exit, true)
    [n1, n2] = nodes

    assert :ok = Producer.send_ping()
    assert :ok = Producer.send_ping()

    for n <- nodes do
      eventually(fn ->
        assert Consumer.ping_count({Consumer, n}) == 2
      end)
    end

    # Crash the consumer in a process so we don't need to catch exceptions
    spawn(fn ->
      GenServer.call({Consumer, n1}, :crash)
    end)

    # Send a final ping
    assert :ok = Producer.send_ping()

    for n <- nodes do
      eventually(fn ->
        assert Consumer.ping_count({Consumer, n}) == 3
      end)
    end
  end

  @tag :skip
  test "producing is idempotent" do
    flunk "Not implemented yet"
  end

  @tag :skip
  test "producer can catch up nodes after a netsplit" do
    flunk "Not implemented yet"
  end

  describe "node monitoring" do
    test "monitors node connections and disconnections" do
      [n1, n2, n3] = nodes = LocalCluster.start_nodes("ping-pong", 3)
      # nodes = LocalCluster.start_nodes("ping-pong", 3)

      for node <- nodes do
        eventually(fn ->
          assert alive_nodes = NodeMonitor.alive_nodes({NodeMonitor, node})
          for n <- nodes, do: assert n in alive_nodes
        end)
      end
    end
  end

  # test "consumers can subscribe to a producer" do
  #   producer = self()
  #   consumer = Consumer.start(producer)

  #   assert_receive {:hello, ^consumer}

  #   send(consumer, {:ping, 0})
  #   send(consumer, {:check, 0, self()})
  #   assert_receive :expected

  #   send(consumer, {:ping, 1})
  #   send(consumer, {:check, 1, self()})
  #   assert_receive :expected

  #   send(consumer, {:ping, 2})
  #   send(consumer, {:check, 2, self()})
  #   assert_receive :expected

  #   send(consumer, {:ping, 4})
  #   send(consumer, {:check, 4, self()})
  #   assert_receive {:unexpected, 3}

  #   send(consumer, {:ping, 3})
  #   send(consumer, {:check, 3, self()})
  #   assert_receive :expected
  # end

  # test "works when the producer fails" do
  #   producer = Producer.start(self())
  #   consumer = Consumer.start(producer)

  #   Producer.producer(producer)
  #   send(consumer, {:check, 0, self()})
  #   assert_receive :expected

  #   Producer.producer(producer)
  #   send(consumer, {:check, 1, self()})
  #   assert_receive :expected

  #   Producer.crash(producer)
  #   :timer.sleep(100)
  #   send(consumer, {:check, 0, self()})
  #   assert_receive :expected
  # end

  # test "Works across a cluster" do
  #   nodes = LocalCluster.start_nodes("ping-pong-cluster", 2)
  #   [n1, n2] = nodes

  #   producer = :rpc.call(n1, Producer, :start, [self()])
  #   consumer = :rpc.call(n2, Consumer, :start, [producer])

  #   assert_receive {:starting, ^producer}

  #   send(consumer, {:check, 0, self()})
  #   assert_receive :expected

  #   :ok = Producer.produce(producer)
  #   send(consumer, {:check, 1, self()})
  #   assert_receive :expected

  #   :ok = Producer.produce(producer)
  #   send(consumer, {:check, 2, self()})
  #   assert_receive :expected

  #   # Split the consumer from the producer
  #   Schism.partition([n2])
  #   Schism.partition([n1])

  #   # Producing won't work now
  #   :ok = Producer.produce(producer)
  #   :ok = Producer.produce(producer)
  #   :ok = Producer.produce(producer)
  #   :ok = Producer.produce(producer)
  #   send(consumer, {:check, 2, self()})
  #   assert_receive :expected

  #   # Heal partition so that the consumer now sees the producer
  #   Schism.heal([n1, n2])

  #   # See if producing works now
  #   :ok = Producer.produce(producer)
  #   send(consumer, {:check, 7, self()})
  #   assert_receive :expected
  # end

  def eventually(f, retries \\ 0) do
    f.()
  rescue
    err ->
      if retries >= 10 do
        reraise err, __STACKTRACE__
      else
        :timer.sleep(500)
        eventually(f, retries + 1)
      end
  catch
    exit, term ->
      :timer.sleep(500)
      eventually(f, retries + 1)
  end
end

