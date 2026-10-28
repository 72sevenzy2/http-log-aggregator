defmodule HttpLogAnalyser do
  @moduledoc """
    todo: add proper logs.
  """
  @doc """
  parse_line() takes in a singular line from your log file and returns a tuple containing a map with its relevant meta data.

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
        [method, endpoint, _version] = String.split(request)
        [status, bytes] = String.split(suffix)

        {:ok,
         %{
           method: method,
           endpoint: endpoint,
           status: String.to_integer(status),
           bytes: String.to_integer(bytes)
         }}

      _ ->
        {:error, "include a proper log line to be parsed."}
    end
  end

  @doc """
  parse_file() takes in a file path for a log file to which returns a tuple containing relevant logs metadata.

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
              "please include a proper log file."
            }
        end
      end)
    rescue
      e in File.Error ->
        {:error, e.reason}
    end
  end
end
