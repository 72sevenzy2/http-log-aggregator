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
        case String.split(line, "\"") do
          [_prefix, request, suffix] ->
            [method, endpoint, _version] = String.split(request)
            [status, bytes] = String.split(suffix)

            {
              :ok,
              %{
                method: method,
                endpoint: endpoint,
                status: String.to_integer(status),
                bytes: String.to_integer(bytes)
              }
            }

          _ ->
            {
              :error,
              :invalid_log_structure
            }
        end
      end)
    rescue
      e in File.Error ->
        {:error, e.reason}
    end
  end
end
