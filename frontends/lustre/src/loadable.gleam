import gleam/option.{None, Option, Some}

pub type Status {
  Resolved
  Reloading
}

pub type Loadable(e, a) {
  Initial
  Loading
  LoadingSlowly
  Loaded(Status, a)
  Failed(Status, e, Option(a))
}

pub fn succeed(a: a) -> Loadable(_, a) {
  Loaded(Resolved, a)
}

pub fn fail(l: Loadable(e, a), e: e) -> Loadable(e, a) {
  Failed(Resolved, e, value(l))
}

pub fn value(l: Loadable(_, a)) -> Option(a) {
  case l {
    Loaded(_status, a) -> Some(a)
    Failed(_status, _error, a) -> a
    _else -> None
  }
}

pub fn reload(l: Loadable(_, _)) -> Loadable(_, _) {
  case l {
    LoadingSlowly -> LoadingSlowly
    Loaded(_, a) -> Loaded(Reloading, a)
    Failed(_, e, a) -> Failed(Reloading, e, a)
    _else -> Loading
  }
}

pub fn loading_slowly(l: Loadable(_, _)) -> Loadable(_, _) {
  case l {
    Loading -> LoadingSlowly
    _else -> l
  }
}
