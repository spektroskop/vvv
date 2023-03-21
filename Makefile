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
