all: build

build:
	./build.sh
	cp posts/archive.html posts/index.html

clean:
	rm -rf assets/
	rm -rf posts/
	rm -rf .org-timestamps/
	rm -f *.html
