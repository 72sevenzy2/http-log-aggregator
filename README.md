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
