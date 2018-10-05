use Mix.Config

config :irc_redis, :general,
  host: "localhost",
  port: 6379,
  queue_key: "irc_redis:q",
  max_retry: 100
