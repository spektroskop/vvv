ifneq (, $(shell which jq))
	format_json := jq
else
	format_json := cat && echo
endif

.PHONY: clean build watch
.DEFAULT_GOAL := build

bundler := ../../bundler
static_reloader := PATCH http://localhost:3210/static

clean:
	make -C $(bundler) clean
	rm -rf build

build:
	make -C $(bundler) build/bundler
	mkdir -p build
	cp assets/index.html build/index.html
	cp assets/heart.svg build/heart.svg
	$(bundler)/build/bundler --tailwind --output build assets/app.js assets/app.css
	@-curl --silent --request $(static_reloader) | $(format_json)

watch:
	watchexec \
	--watch elm.json \
	--watch tailwind.config.js \
	--watch src \
	--watch assets \
	make build
