all: build

build:
	./build.sh
	cp dist/posts/archive.html dist/posts/index.html

clean:
	rm -rf dist/
	rm -rf .org-timestamps/
	rm -f src/sitemap.org
	rm -f src/posts/archive.org
	rm -f src/posts/rss.org

serve:
	php -S 127.0.0.1:8001 -t dist/
