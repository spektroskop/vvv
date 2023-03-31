.PHONY: all build clean

all: build

bundler/bundler:
	cd bundler && go build -v ./cmd/bundler

build: bundler/bundler
	mkdir -p build
	cp index.html build/index.html
	cp heart.svg build/heart.svg
	bundler/bundler --output build app.js
	tailwind --input app.css --output build/app.css
	-curl -s -X PATCH http://localhost:3210/static

clean:
	rm -f bundler/bundler
	rm -rf build
