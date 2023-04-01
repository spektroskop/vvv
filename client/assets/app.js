import { Elm } from "../src/Main.elm"

let app = Elm.Main.init({})

app.ports && app.ports.outgoing.subscribe(({ name, value }) => {
  switch(name) {
    case "Log": 
      console.log("App updated", value)
      break
  }
})

