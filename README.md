# vvv

This is my bikeshed laboratory for web app experiments

## [bundler](https://github.com/spektroskop/bundler)

```sh
git submodule update --init
```

## backend

### [gleam](backend)

> requires [gleam](https://gleam.run), [watchexec](https://github.com/watchexec/watchexec)

```sh
STATIC_BASE=path/to/assets make -C backend watch
```

## frontends

### [static](frontends/static)

```sh
STATIC_BASE=$PWD/frontends/static make -C backend watch
```

### [elm](frontends/elm)

> requires [elm](https://elm-lang.org), [go](https://go.dev), [tailwind cli](https://tailwindcss.com), [watchexec](https://github.com/watchexec/watchexec)

```sh
STATIC_BASE=$PWD/frontends/elm/build make -C backend watch
```

```sh
make -C frontends/elm watch
```

### [gren](frontends/gren)

> requires [gren](https://gren-lang.org), [go](https://go.dev), [tailwind cli](https://tailwindcss.com), [watchexec](https://github.com/watchexec/watchexec)

```sh
STATIC_BASE=$PWD/frontends/gren/build make -C backend watch
```

```sh
make -C frontends/gren watch
```

### [lustre](frontends/lustre)

> requires [gleam](https://gleam.run), [node](https://nodejs.org), [go](https://go.dev), [tailwind cli](https://tailwindcss.com), [watchexec](https://github.com/watchexec/watchexec)

```sh
STATIC_BASE=$PWD/frontends/lustre/build/bundle make -C backend watch
```

```sh
make -C frontends/lustre watch
```
