bundler := ../../bundler
build := build/bundle

.PHONY: build
build: $(bundler)/bundler
	mkdir -p $(build)
	cp assets/index.html $(build)/index.html
	gleam build --target=javascript
	$(bundler)/bundler --output $(build) assets/app.js
	-curl -s -X PATCH http://localhost:3210/static
	@echo

$(bundler)/bundler: $(shell find $(bundler) -type f -name '*.go')
	cd $(bundler) && go build -v ./cmd/bundler
