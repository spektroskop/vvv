export const connect = (path, onOpen, onError, onMessage, onClose) => {
  const url = new URL(document.URL)
  const protocol = url.protocol === "https:" ? "wss" : "ws"
  const ws_url = `${protocol}://${url.host}${path}`
  const socket = new WebSocket(ws_url)

  socket.addEventListener("open", (event) => {
    onOpen(socket)
  })

  socket.addEventListener("message", (event) => {
    onMessage(event.data)
  })

  socket.addEventListener("close", (event) => {
    onClose(event.code)
  })

  socket.addEventListener("error", (event) => {
    onError(event)
  })
}

export const close = (socket) => {
  socket.close()
}
