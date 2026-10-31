defmodule Worker do
  def process_chunk(logs) do
    logs
    |> Enum.map(&HttpLogAnalyser.parse_line/1)
    |> HttpLogAnalyser.aggregate_log()
  end

  def merge_stats(l, r) do
    endpoint_stats =
      Map.merge(l.endpoint_stats, r.endpoint_stats, fn _endpoint, l, r ->
        %{
          requests: l.requests + r.requests,
          errors: l.errors + r.errors,
          bytes: l.bytes + r.bytes
        }
      end)

    %{
      l
      | total_requests: r.total_requests + l.total_requests,
        total_bytes: r.total_bytes + l.total_bytes,
        failed_requests: r.failed_requests + l.failed_requests,
        invalid_formats: r.invalid_formats + l.invalid_formats,
        endpoint_stats: endpoint_stats
    }
  end

  def aggregate_file(path, opts \\ []) do
    max_concurrency = Keyword.get(opts, :max_concurrency, Sysem.schedulers_online())
    chunk_size = Keyword.get(opts, :chunk_size, 1_000)

    try do
      path
      |> File.stream!()
      |> Stream.chunk_every(chunk_size)
      |> Task.async_stream(
        &process_chunk/1,
        max_concurrency: max_concurrency,
        ordered: false,
        timeout: 30_000,
        on_timeout: :kill_task
      )
      |> Enum.reduce_while(
        {:ok, HttpLogAnalyser.aggregate_log([])},
        fn
          {:ok, chunk_stats}, {:ok, acc} ->
            {:cont, {:ok, merge_stats(acc, chunk_stats)}}

          {:exit, reason}, _acc ->
            {:halt, {:error, {:worker_failed, reason}}}
        end
      )
    rescue
      e in File.Error ->
        {:error, e.reason}
    end
  end
end
