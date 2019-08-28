defmodule Shortener.GCounter do
  @moduledoc """
  This module defines a grow-only counter, CRDT.
  """

  @doc """
  Returns a new counter
  """
  def new(), do: %{}

  @doc """
  Increments the counter for this node by the given delta. If this is the first
  increment operation for this node then the count defaults to the delta.
  """
  def increment(counter, node \\ Node.self(), delta \\ 1) when delta >= 0 do
    Map.update(counter, node, 1, &(&1 + 1))
  end

  @doc """
  Merges 2 counters together taking the highest value seen for each node.
  """
  def merge(c1, c2) do
    # Merge's 2 counter's together by taking the highest value seen
    # for each node.

    Map.merge(c1, c2, fn k, v1, v2 -> 
      Enum.max([v1, v2])
    end)
  end

  @doc """
  Convert a counter to an integer.
  """
  def to_i(counter) do
    counter
    |> Map.values()
    |> Enum.sum()
  end
end

