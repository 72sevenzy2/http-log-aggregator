defmodule HttpLogAnalyser do
  @moduledoc """
    todo: add proper logs.
  """
  @doc """
  parse_line() takes in a singular line from your log file and returns a map containing its relevant meta data.

  ## Examples
  iex>HttpLogAnalyser.parse_line(~s(127.0.0.1 - - [27/Oct/2026:10:00:00 +0000] "GET /api/tasks HTTP/1.1" 200 512))
  %{
    method: "GET",
    endpoint: "/api/tasks",
    status: 200,
    bytes: 512
  }
  """

  def parse_line(line) do
    case String.split(line, "\"") do
      [_prefix, request, suffix] ->
        [method, endpoint, _version] = String.split(request)
        [status, bytes] = String.split(suffix)

        %{
          method: method,
          endpoint: endpoint,
          status: String.to_integer(status),
          bytes: String.to_integer(bytes)
        }

      _ ->
        IO.puts("include a proper log line to be parsed.")
    end
  end
end
