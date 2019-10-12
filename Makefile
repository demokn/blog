all: build

build:
	./build.sh
	cp public/posts/archive.html public/posts/index.html

clean:
	rm -rf public/
	rm -rf .org-timestamps/
	rm -f src/sitemap.org
	rm -f src/posts/archive.org
	rm -f src/posts/rss.org
