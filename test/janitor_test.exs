defmodule JanitorTest do
  use ExUnit.Case
  doctest Janitor

  test "greets the world" do
    assert Janitor.hello() == :world
  end
end
