.PHONY: build
build:
	gleam export erlang-shipment

.PHONY: watch
watch:
	watchexec gleam run --restart \
	--watch gleam.toml \
	--watch src

.PHONY: docs
docs:
	gleam docs build

.PHONY: serve-docs
serve-docs: docs
	ASSET_PATH=build/dev/docs/vvv gleam run

.PHONY: watch-docs
watch-docs:
	watchexec make serve-docs --restart \
	--watch gleam.toml \
	--watch README.md \
	--watch src
