import {main} from "../src/vvv.gleam"

main()

function wsURL() {
  let {protocol, host} = window.location
  return protocol === "https:" ? `wss://${host}/ws` : `ws://${host}/ws`
}

let {protocol, host} = window.location
let ws = new WebSocket(wsURL())

ws.onmessage = (event) => {
  console.log(event)
  console.log(event.data)
}

ws.onopen = (event) => {
  ws.send("Hello")
}
