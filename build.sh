#!/bin/sh

set -x

EMACS_BIN=emacs
if `command -v emacs27 >/dev/null 2>&1`; then
    EMACS_BIN=emacs27
fi

$EMACS_BIN --batch --no-init-file --load publish.el --funcall toggle-debug-on-error --funcall demo/org-publish-all
