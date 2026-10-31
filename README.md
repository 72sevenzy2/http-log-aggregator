# HTTP log analyser

<h1>parses given HTTP log files/singular logs, and extracts the request(s) relevant metadata.</h1>

## Usage:

<h2>parsing an individual HTTP access log line:</h2>

```
HttpLogAnalyser.parse_line(~s(127.0.0.1 - - [27/Oct/2026:10:00:00 +0000] "GET /api/tasks HTTP/1.1" 200 512)
```

<h3>expected output:</h3>

```
{:ok, %{method: "GET", endpoint: "/api/tasks", status: 200, bytes: 512}}
```

<h2>parsing an log file:</h2>

```
HttpLogAnalyser.parse_file("access.log")
```

<h3>expected out will be similar to:</h3>

```
  [
   {:ok, %{method: "GET", endpoint: "/api/tasks", status: 200, bytes: 512}},
   {:ok, %{method: "POST", endpoint: "/api/tasks", status: 201, bytes: 128}},
   {:ok, %{method: "GET", endpoint: "/api/users", status: 404, bytes: 64}},
   {:ok, %{method: "GET", endpoint: "/api/tasks", status: 500, bytes: 32}},
   {:ok, %{method: "DELETE", endpoint: "/api/tasks/1", status: 204, bytes: 0}}
  ]
```

<h2>generating aggregated summaries of log entries:</h2>

```
HttpLogAnalyser.aggregate_log(HttpLogAnalyser.parse_file("access.log"))
```

<h3>output should be similar to:</h3>

```
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
```
<h3>^ may be more than one 'endpoint_stats' map returned depending on the number of log lines the log file includes.</h3>
<br>

# concurrent use
<h2>the aggregate_file() function allows you to spawn workers to independently generate aggregated log summaries to which it will be combined and returned afterwards.</h2>
<h3>it accepts the following parameters:</h3>

<h2>path > the log file path.</h2>

<h2>opts > optional configurations such as:</h2>
<h3>:chunk_size - the number of log lines to parse. Defaults to 1000.</h3>
<h3>:max_concurrency - maximum number of concurrent tasks allowed. Defaults to the System.schedulers_online().</h3>
<br>

```
Worker.aggregate_file("access.log")
```

<h2>~expected output:</h2>

```
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
```
