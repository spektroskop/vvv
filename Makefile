.PHONY: watch
watch:
	watchexec gleam run VVV vvv.toml \
	--restart \
	--watch gleam.toml \
	--watch vvv.toml \
	--watch src
