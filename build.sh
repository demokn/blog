#!/bin/sh

rm -rf assets/ posts/
emacs --batch --no-init-file --load publish.el --funcall toggle-debug-on-error --funcall demo/org-publish-all
