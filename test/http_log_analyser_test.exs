defmodule HttpLogAnalyserTest do
  use ExUnit.Case
  doctest HttpLogAnalyser

  test "parse_line() returns an err when the log structure is invalid" do
    assert HttpLogAnalyser.parse_line(
             ~s(127.0.0.1 - - [27/Oct/2026:10:00:00 +0000]"GET /api/tasks HTTP/1.1" 200512
)
           ) == {:error, :invalid_log_structure}
  end

  test "parse_line() test" do
    assert HttpLogAnalyser.parse_line(
             ~s(127.0.0.1 - - [27/Oct/2026:10:00:00 +0000] "GET /api/tasks HTTP/1.1" 200 512
)
           ) ==
             {:ok,
              %{
                method: "GET",
                endpoint: "/api/tasks",
                status: 200,
                bytes: 512
              }}
  end

  test "parse_file() returns an err when file does not exist" do
    assert HttpLogAnalyser.parse_file("nonExistent.logs") == {:error, :enoent}
  end

  test "parse_file() test" do
    assert HttpLogAnalyser.parse_file("test/testLogs.log") ==
             [
               {:ok, %{method: "GET", endpoint: "/api/tasks", status: 200, bytes: 512}},
               {:ok, %{method: "POST", endpoint: "/api/tasks", status: 201, bytes: 128}},
               {:ok, %{method: "GET", endpoint: "/api/users", status: 404, bytes: 64}},
               {:ok, %{method: "GET", endpoint: "/api/tasks", status: 500, bytes: 32}},
               {:ok, %{method: "DELETE", endpoint: "/api/tasks/1", status: 204, bytes: 0}}
             ]
  end

  test "aggregate_log() returns an err on invalid log formats" do
    assert HttpLogAnalyser.aggregate_log(HttpLogAnalyser.parse_file("test/invalidLogs.log")) ==
             %{
               total_requests: 0,
               total_bytes: 0,
               failed_requests: 0,
               invalid_formats: 1,
               endpoint_stats: %{}
             }
  end

  test "aggregate_log() test" do
    assert HttpLogAnalyser.aggregate_log(HttpLogAnalyser.parse_file("test/testLogs.log")) == %{
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
  end
end
