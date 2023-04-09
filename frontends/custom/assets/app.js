import {main} from "../src/vvv.gleam"

main()

let wsURL = () => {
  let {protocol, host} = window.location
  return protocol === "https:" ? `wss://${host}/ws` : `ws://${host}/ws`
}

let ws = new WebSocket(wsURL())

ws.onmessage = (event) => {
  console.log(event)
  console.log(event.data)
}

ws.onopen = (event) => {
  ws.send("Hello")
}
