defmodule IrcRedisTest do
  use ExUnit.Case
  doctest IrcRedis

  test "greets the world" do
    assert IrcRedis.hello() == :world
  end
end
