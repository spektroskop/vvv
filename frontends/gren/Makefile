.DEFAULT_GOAL := build
.PHONY: clean build watch

bundler := ../../bundler
reload := PATCH http://localhost:3210/static

clean:
	make -C $(bundler) clean
	rm -rf build

build:
	make -C $(bundler) build/bundler
	mkdir -p build
	cp assets/index.html build/index.html
	$(bundler)/build/bundler assets/app.js assets/app.css \
	--output build --activate tailwind
	@-curl --silent --request $(reload) | jq

watch:
	watchexec \
	--watch gren.json \
	--watch tailwind.config.js \
	--watch src \
	--watch assets \
	make build
