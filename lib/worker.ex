defmodule IRCWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_state) do
    result = Redix.command(:redix, ["PING"])
    config = Application.get_env(:irc_redis, :general)
    state = %{
      queue_key: config |> Keyword.fetch!(:queue_key),
      max_retry: config |> Keyword.fetch!(:max_retry),
      retried: 0
    }

    case result do
      {:error, _} ->
        Redix.stop(:redix)
        IO.puts("Error when connecting redis")
        exit(:shutdown)

      _ ->
        :ok
    end

    result = Redix.command(:redix, ["EXISTS", state.queue_key])

    case result do
      {:ok, 1} ->
        try do
          {:ok, "list"} = Redix.command(:redix, ["TYPE", state.queue_key])
        rescue
          _ -> Redix.command(:redix, ["DEL", state.queue_key])
        end

      {:error, _} ->
        exit(:shutdown)

      _ ->
        :ok
    end

    routine()
    {:ok, state}
  end

  def handle_info(:pop_msg, state) do
    result = Redix.command(:redix, ["BRPOP", state.queue_key, 0], timeout: :infinity)

    case result do
      {:ok, [_, msg]} ->
        # test
        IO.puts(msg)

      {:ok, _} ->
        # just ignore
        :ok

      {:error, _} ->
        raise "error when fetching msg"
    end

    state = %{state | retried: if state.retried > 1 do state.retried - 1 else 0 end}
    routine()
    {:noreply, state}
  rescue
    _ ->
      cond do
        state.retried == state.max_retry ->
          exit(:shutdown)
        true ->
          :ok
      end
      state = %{state | retried: state.retried + 1}
      # binary exponential backoff
      Process.send_after(self(), :pop_msg, :math.pow(1.15, state.retried) |> trunc)
      {:noreply, state}
  end

  defp routine() do
    Process.send(self(), :pop_msg, [])
  end
end
