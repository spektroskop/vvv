import * as Gleam from "./gleam.mjs"

export const document_url = () => (new URL(document.URL)).toString()

export const connect = (
  url,
  on_open,
  on_error,
  on_message,
  on_close,
) => {
  const socket = new WebSocket(url)

  socket.addEventListener("open", (event) => {
    on_open(socket)
  })

  socket.addEventListener("message", (event) => {
    on_message(event.data)
  })

  socket.addEventListener("close", (event) => {
    on_close(event.code)
  })

  socket.addEventListener("error", (event) => {
    on_error(event)
  })
}

export const close = (socket) => {
  socket.close()
}
