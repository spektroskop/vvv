.PHONY: clean build watch
.DEFAULT_GOAL := build

bundler := ../../bundler

$(bundler)/bundler: $(shell find $(bundler) -type f -name '*.go')
	cd $(bundler) && go build -v ./cmd/bundler

clean:
	rm -f $(bundler)/bundler
	rm -rf build

build: $(bundler)/bundler
	@mkdir -p build
	@cp assets/index.html build/index.html
	@cp assets/heart.svg build/heart.svg
	@$(bundler)/bundler --output build --tailwind assets/app.js assets/app.css
	@-curl -s -X PATCH http://localhost:3210/static && echo

watch:
	watchexec \
	--watch elm.json \
	--watch tailwind.config.js \
	--watch src \
	--watch assets \
	make build
