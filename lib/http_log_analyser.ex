defmodule HttpLogAnalyser do
  @moduledoc """
    todo: add proper logs.
  """

  @doc """
  todo: add proper parse() docs.

  ## Examples
  iex> HttpLogAnalyser.hello()
  :world

  """
  def hello do
    :world
  end

  @doc """
  parse_line() takes in a singular line from your log file and returns a map containing its relevant meta data.

  ## Examples
    todo: add proper example usage
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
        nil
    end
  end
end
