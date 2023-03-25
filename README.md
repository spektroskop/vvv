# vvv

This is a template application for serving web assets with [Gleam](https://gleam.run).

Configuration is provided either through a config file or the environment. See `vvv.example.toml` for
all the configuration options, their defaults, and corresponding environment variable names.

# quick start

If you want to use an environment prefix and a config file they must be passed as arguments.
Server listen port and static path are the only required configuration and must be defined 
either in the supplied config file or in the environment:

    # [$PREFIX]_SERVER_PORT=.. [$PREFIX]_STATIC_PATH=.. gleam run [$PREFIX] [$CONFIG]
    VVV_SERVER_PORT=3210 VVV_STATIC_PATH=some/path gleam run VVV

## activate reloader

    VVV_SERVER_PORT=3210 VVV_STATIC_PATH=some/path \
    VVV_STATIC_RELOADER_METHOD=PATCH VVV_STATIC_RELOADER_PATH=static \
    gleam run VVV

## reload assets

    curl --request PATCH localhost:3210/static

## get current asset hashes

    curl localhost:3210/api/assets

## browse package documentation

    PORT=3210 make watch-docs

## example assets

    PORT=3210 make example
