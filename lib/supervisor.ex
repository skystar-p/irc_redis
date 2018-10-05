defmodule IRCSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    config = Application.get_env(:irc_redis, :general)
    host = Keyword.fetch!(config, :host)
    port = Keyword.fetch!(config, :port)
    children = [
      { Redix, host: host, port: port, name: :redix },
      IRCWorker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
