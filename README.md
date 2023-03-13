# vvv

    # start server
    PORT=3210 ASSET_PATH=some/path RELOADER_METHOD=PATCH RELOADER_PATH=static make

    # reload assets
    curl --request PATCH localhost:3210/static

## environment

- `PORT` - server listen port
- `ASSET_PATH` - where to look for assets (required)
- `INDEX_PATH` - fallback for static router (default: index.html)
- `RELOADER_METHOD` - path to use for asset reload
- `RELOADER_PATH` - method to use for asset reload
