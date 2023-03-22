# vvv

This is a playground, example, and a template for serving web assets with Gleam. Assets are loaded from the path specified in `ASSET_PATH`, falling back to the path specified in `INDEX_PATH` (or `index.html` by default) if the requested file is not found. 

Assets are cataloged on startup so that we don't need to check the file system for unknown paths. If the `RELOADER_METHOD` and `RELOADER_PATH` variables are defined, assets can be reloaded with an HTTP request to the server. This can be useful in development by adding a notification step to your bundler process. 

The asset system also provides a mechanism for reading the current asset hashes, via `GET /api/assets`. This can be used in a frontend app to check if the backend has been updated and might generate a notification that lets the user reload the page, or do so automatically in development.

# quick start

    # start server
    PORT=3210 ASSET_PATH=some/path RELOADER_METHOD=PATCH RELOADER_PATH=static gleam run

    # watch server
    PORT=3210 ASSET_PATH=some/path RELOADER_METHOD=PATCH RELOADER_PATH=static make watch

    # reloader is optional
    PORT=3210 ASSET_PATH=some/path gleam run
    
    # reload assets
    curl --request PATCH localhost:3210/static

    # get asset hashes
    curl localhost:3210/api/assets

    # browse package documentation
    PORT=3210 make watch-docs

    # serve example
    PORT=3210 make example

# environment

- `PORT` - server listen port (required)
- `ASSET_PATH` - where to look for assets (required)
- `INDEX_PATH` - fallback for static router (default: `index.html`)
- `RELOADER_METHOD` - method to use for asset reload
- `RELOADER_PATH` - path to use for asset reload
