import * as Gleam from "./gleam.mjs"

export const document_url = () => (new URL(document.URL)).toString()

export const connect = (url, callbacks) => {
  const socket = new WebSocket(url)

  socket.addEventListener("open", (event) => {
    callbacks.open(socket)
  })

  socket.addEventListener("message", (event) => {
    callbacks.message(event.data)
  })

  socket.addEventListener("close", (event) => {
    callbacks.close(event.code)
  })

  socket.addEventListener("error", (event) => {
    callbacks.error(event)
  })
}

export const close = (socket) => {
  socket.close()
}
