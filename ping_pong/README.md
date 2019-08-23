# PingPong

## Goal

The goal of this exercise is to connect Nodes together, send some messages
across them, and see what happens when those messages fail.

Each node starts a producer and a consumer. The Producer's job is to send pings to Consumer's. It will do this by broadcasting them to all consumer's on all connected nodes. Producers keep track of the number of pings that they've sent.
Consumer's keep a count of pings they've seen from a each producer on each node.

## Helpful functions

In order to solve each of these problems it'll help to know about a few important OTP functions.

* `Node.list/0` - Lists all currently connected nodes.
* `GenServer.abcast/2` - Casts a message to a genserver with the name on all connected nodes.
* `GenServer.multi_call/2` - Calls a genserver with a given name on all connected nodes. 
* `net_kernel.monitor_nodes/1` - Allows any process to monitor node up and node down events. Node events can be handled in the `handle_info` callback.


## Problem 1

In this problem you need to cast pings to all consumers.

## Problem 2

Now that we can broadcast pings to all consumers we need to check each consumer to see what their current ping counts are.

## Problem 3

If our consumer crashes our states will get out of sync. In this exercise your job is to recover gracefully from a crash. In this case we're going to do this by having the consumer request the current ping count from each producer when the consumer starts.

We could have chosen to solve this problem with monitors. But monitors have an inherent race condition where the producer could cast to a consumer that isn't currently started yet. Using this demand driven approach helps us to eliminate that race condition and is generally more reliable.

## Additional exercises

* Try spawning a few thousand consumers all monitoring a single producer. What
happens when you disconnect the node now?
* What would happen if the producer crashes while the network was partitioned?
Are there ways to make our algorithm more robust?
