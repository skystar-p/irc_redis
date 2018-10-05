defmodule IRCRedis do
  use Application

  def start(_types, _args) do
    IRCSupervisor.start_link([])
  end

  def stop(_state) do
    :ok
  end
end
