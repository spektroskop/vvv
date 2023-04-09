export const connect = (path, {on_open, on_close, on_message}) => {
  const url = new URL(document.URL)
  const protocol = url.protocol === "https:" ? "wss" : "ws"
  const ws_url = `${protocol}://${url.host}${path}`
  const conn = new WebSocket(ws_url)

  conn.onclose = (event) => {
    on_close(event.code)
  }

  conn.onopen = (event) => {
    on_open(conn)
    setInterval(() =>  conn.send("Hello"), 1000)
  }

  conn.onmessage = (event) => {
    on_message(event.data)
  }
}
