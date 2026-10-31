defmodule HttpLogAnalyser do
  @moduledoc """
  parses HTTP log files or individual lines of logs to which it extracts request(s) metadata.

  ie, parse_line() parses an individual log to extract the requests method, endpoint, number of bytes, and status.
  parse_file() parses an existing log file you have to which extracts each request logs status, endpoint, etc.

  if an malformed log structure/log file is passed in, either function will return an tuple containing: {:error, :invalid_log_structure}
  """

  @doc """
  parse_line() takes in a singular line from your log file and returns a tuple containing a map with its relevant meta data, if the log structure is invalid then it will return :invalid_log_structure

  ## Examples
  iex>HttpLogAnalyser.parse_line(~s(127.0.0.1 - - [27/Oct/2026:10:00:00 +0000] "GET /api/tasks HTTP/1.1" 200 512))
  { :ok, 
    %{
      method: "GET",
      endpoint: "/api/tasks",
      status: 200,
      bytes: 512
    }
  }
  """

  def parse_line(line) do
    case String.split(line, "\"") do
      [_prefix, request, suffix] ->
        case {String.split(request), String.split(suffix)} do
          {[method, endpoint, _version], [status, bytes]} ->
            case Integer.parse(status) do
              {status, ""} ->
                case Integer.parse(bytes) do
                  {bytes, ""} ->
                    {:ok,
                     %{
                       method: method,
                       endpoint: endpoint,
                       status: status,
                       bytes: bytes
                     }}

                  _ ->
                    {:error, :invalid_log_structure}
                end

              _ ->
                {:error, :invalid_log_structure}
            end

          _ ->
            {:error, :invalid_log_structure}
        end

      _ ->
        {:error, :invalid_log_structure}
    end
  end

  @doc """
  parse_file() takes in a file path for a log file to which returns a tuple containing relevant logs metadata, if the log file structure is wrong, it will return an :invalid_log_structure

  ## Examples
  iex>HttpLogAnalyser.parse_file("test/testLogs.log")
  [
   {:ok, %{method: "GET", endpoint: "/api/tasks", status: 200, bytes: 512}},
   {:ok, %{method: "POST", endpoint: "/api/tasks", status: 201, bytes: 128}},
   {:ok, %{method: "GET", endpoint: "/api/users", status: 404, bytes: 64}},
   {:ok, %{method: "GET", endpoint: "/api/tasks", status: 500, bytes: 32}},
   {:ok, %{method: "DELETE", endpoint: "/api/tasks/1", status: 204, bytes: 0}}
  ]

  """

  def parse_file(filePath) do
    try do
      File.stream!(filePath)
      |> Enum.map(fn line ->
        parse_line(line)
      end)
    rescue
      e in File.Error ->
        {:error, e.reason}
    end
  end

  @doc """
  aggregate_log() takes in a list of log entries, and returns an aggregated summary of the logs in the format:
  %{
    total_requests: <total number of requests logged>,
    total_bytes: <sum of the bytes each request consumed>,
    failed_requests: <number of failed requests/invalid log formats>,
    endpoint_stats: %{
      requests: <number of requests to a specific endpoint>,
      errors: <number of failed requests>,
      bytes: <sum of the bytes consumed by requests>
    }
  }

    aggregate_log() returns an err upon the first occurence of an invalid log format of an individual log given in a list of logs, similar to:
   %{
    total_requests: 0,
    total_bytes: 0,
    failed_requests: 0,
    invalid_formats: 1,
    endpoint_stats: %{}
   }

  ## Examples
  iex>HttpLogAnalyser.aggregate_log(HttpLogAnalyser.parse_file("test/testLogs.log"))
  %{
  total_requests: 5,
  total_bytes: 736,
  failed_requests: 2,
  invalid_formats: 0,
  endpoint_stats: %{
    "/api/tasks" => %{
      requests: 3,
      errors: 1,
      bytes: 672
    },
    "/api/users" => %{
      requests: 1,
      errors: 1,
      bytes: 64
    },
    "/api/tasks/1" => %{
      requests: 1,
      errors: 0,
      bytes: 0
    }
   }
  }

  """

  def aggregate_log(entries) do
    Enum.reduce(
      entries,
      %{
        total_requests: 0,
        total_bytes: 0,
        failed_requests: 0,
        invalid_formats: 0,
        endpoint_stats: %{}
      },
      fn
        {:ok, %{endpoint: endpoint, status: status, bytes: bytes}}, acc ->
          failed = if status >= 400, do: 1, else: 0

          endpoint_statistics =
            Map.update(
              acc.endpoint_stats,
              endpoint,
              %{requests: 1, errors: failed, bytes: bytes},
              fn stats ->
                %{
                  requests: stats.requests + 1,
                  errors: stats.errors + failed,
                  bytes: stats.bytes + bytes
                }
              end
            )

          %{
            acc
            | total_requests: acc.total_requests + 1,
              total_bytes: acc.total_bytes + bytes,
              failed_requests: acc.failed_requests + failed,
              endpoint_stats: endpoint_statistics
          }

        {:error, _reason}, acc ->
          %{acc | invalid_formats: acc.failed_requests + 1}
      end
    )
  end

  def process_chunk(logs) do
    logs
    |> Enum.map(&parse_line/1)
    |> aggregate_log()
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
      total_requests: r.total_requests + l.total_requests,
      total_bytes: r.total_bytes + l.total_bytes,
      failed_requests: r.failed_requests + l.failed_requests,
      invalid_formats: r.invalid_formats + l.invalid_formats,
      endpoint_stats: endpoint_stats
    }
  end

  # def aggregate_file(path, opts \\ []) do
  #   max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
  #   chunk_size = Keyword.get(opts, :chunk_size, 1_000)
  # end
end
