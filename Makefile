export PORT ?= 3210

.PHONY: build
build:
	gleam export erlang-shipment

.PHONY: example
example:
	STATIC_BASE=example \
	watchexec gleam run --restart \
	--watch gleam.toml \
	--watch example \
	--watch src

.PHONY: watch
watch:
	watchexec gleam run --restart \
	--watch gleam.toml \
	--watch vvv.toml \
	--watch src

.PHONY: docs
docs:
	gleam docs build

.PHONY: serve-docs
serve-docs: docs
	STATIC_BASE=build/dev/docs/vvv gleam run

.PHONY: watch-docs
watch-docs:
	watchexec make serve-docs --restart \
	--watch gleam.toml \
	--watch README.md \
	--watch src
