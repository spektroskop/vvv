# vvv

This is a template repository for things I usually need when writing web applications. [Gleam](https://gleam.run) is used for the backend, [Elm](https://elm-lang.org) for the frontend.

Backend configuration is provided either through a config file or the environment. See `vvv.example.toml` for all the configuration options, their defaults, and corresponding environment variable names.

# running

If you want to use an environment prefix it must be passed as an argument to the backend application. 

The `CONFIG` variable sets the path to the config file to use. 

`SERVER_PORT` and `STATIC_BASE` must be defined, either in the environment or in the config file.

## general syntax

    [$PREFIX]_SERVER_PORT=$PORT \
    [$PREFIX]_STATIC_BASE=$PATH \
    [$PREFIX]_CONFIG=$PATH \
    gleam run [$PREFIX]

## start the server

    SERVER_PORT=3210 \
    STATIC_PATH=some/path \
    gleam run

## activate reloader

    SERVER_PORT=3210 \
    STATIC_BASE=some/path \
    STATIC_RELOADER_METHOD=PATCH \
    STATIC_RELOADER_PATH=static \
    gleam run

## reload assets

    curl --request PATCH localhost:3210/static

## get current asset hashes

    curl localhost:3210/api/assets

# development

    STATIC_BASE=example/elm/build make watch-reloader

    make watch-elm
