import { Elm } from "../src/Main.elm"

let app = Elm.Main.init({})

app.ports && app.ports.outgoing.subscribe(({ name, value }) => {
  switch(name) {
    case "Log": 
      console.log("App updated", value)
      break
  }
})

// FIXME: Only works if /docs is lodaded first

let map = new Map()

function callback(entries) {
  entries.forEach(entry => {
    let target = entry.target
    let id = target.children[0].children[0].id

    if (entry.isIntersecting) {
      map.set(id, target)
    } else {
      map.delete(id)
    }
  })

  let active = null
  for (let [id, el] of map) {
    let bound = el.getBoundingClientRect()
    if (!active || bound.top < active.top) {
      active = { id: id, top: bound.top }
    }
  }

  if (active) {
    app.ports.incoming.send({ name: "Anchor", value: active.id })
  }
}

let observer = new IntersectionObserver(callback, { rootMargin: '-200px', threshold: 0 })
document.querySelectorAll('section.doc-section').forEach((el) => {
  observer.observe(el)
})
