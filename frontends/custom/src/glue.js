import * as Gleam from "./gleam.mjs"

export const document_url = () => (new URL(document.URL)).toString()

export const connect = (url, events, handle) => {
  const socket = new WebSocket(url)

  socket.addEventListener("open", (event) => {
    handle(events.open(socket))
  })

  socket.addEventListener("message", (event) => {
    handle(events.message(event.data))
  })

  socket.addEventListener("close", (event) => {
    handle(events.close(event.code))
  })

  socket.addEventListener("error", (event) => {
    handle(events.error(event))
  })

  return socket
}

export const close = (socket) => {
  socket.close()
}
