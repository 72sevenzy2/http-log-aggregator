defmodule HttpLogAnalyserTest do
  use ExUnit.Case
  doctest HttpLogAnalyser

  test "parse_line() test" do
    assert HttpLogAnalyser.parse_line(
             ~s(127.0.0.1 - - [27/Oct/2026:10:00:00 +0000] "GET /api/tasks HTTP/1.1" 200 512
)
           ) == %{
             method: "GET",
             endpoint: "/api/tasks",
             status: 200,
             bytes: 512
           }
  end
end
