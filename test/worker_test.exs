defmodule WorkerTest do
  use ExUnit.Case
  doctest Worker

  test "process_chunk() returns an aggregated log summary." do
    assert Worker.process_chunk([
             ~s(127.0.0.1 - - [27/Oct/2026:10:00:00 +0000] "GET /api/tasks HTTP/1.1" 200 512),
             ~s(192.168.1.5 - - [27/Oct/2026:10:00:02 +0000] "GET /api/users HTTP/1.1" 404 64)
           ]) == %{
             total_requests: 2,
             total_bytes: 576,
             failed_requests: 1,
             invalid_formats: 0,
             endpoint_stats: %{
               "/api/tasks" => %{
                 requests: 1,
                 errors: 0,
                 bytes: 512
               },
               "/api/users" => %{
                 requests: 1,
                 errors: 1,
                 bytes: 64
               }
             }
           }
  end

  test "merge_stats() returns 2 aggregated summaries combined" do
    assert Worker.merge_stats(
             %{
               total_requests: 5,
               total_bytes: 160,
               failed_requests: 2,
               invalid_formats: 0,
               endpoint_stats: %{
                 "/api/tasks" => %{requests: 3, errors: 1, bytes: 10}
               }
             },
             %{
               total_requests: 5,
               total_bytes: 19,
               failed_requests: 2,
               invalid_formats: 0,
               endpoint_stats: %{
                 "/api/tasks" => %{requests: 3, errors: 1, bytes: 10}
               }
             }
           ) == %{
             total_requests: 10,
             total_bytes: 179,
             failed_requests: 4,
             invalid_formats: 0,
             endpoint_stats: %{
               "/api/tasks" => %{
                 requests: 6,
                 errors: 2,
                 bytes: 20
               }
             }
           }
  end

  test "aggregate_file() returns an aggregated result of a given log file" do
    assert Worker.aggregate_file("test/testLogs.log") ==
             {:ok,
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
              }}
  end
end
