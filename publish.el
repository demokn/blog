;;; package --- summary
;;; Commentary:

;;; Code:
(require 'package)
(package-initialize)
(unless package-archive-contents
  ;;(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)
  ;;(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
  (add-to-list 'package-archives '("org" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/org/") t)
  (add-to-list 'package-archives '("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/") t)
  (package-refresh-contents))
(dolist (pkg '(dash org-plus-contrib htmlize))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(require 'dash)
(require 'org)
(require 'ox-rss)
(require 'ox-publish)

;; (defun demo/hash-for-filename (filename)
;;   "计算指定文件的散列值.  FILENAME: 文件路径."
;;   (with-temp-buffer
;;     (insert-file-contents filename)
;;     (secure-hash 'sha256 (current-buffer))))

;; (defun demo/asset-relative-link-to (asset pub-dir &optional versioned)
;;   "获取资源文件相对于文章发布目录的路径.  ASSET: 资源文件, PUB-DIR: 发布目录, VERSIONED: 是否添加版本标记."
;;   (let* ((assets-project (assoc "assets" org-publish-project-alist 'string-equal))
;;          (pub-asset (expand-file-name asset (org-publish-property :publishing-directory assets-project)))
;;          (pub-asset-relative-name (file-relative-name pub-asset pub-dir)))
;;     (if versioned
;;         (format "%s?v=%s" pub-asset-relative-name
;;                 (demo/hash-for-filename (expand-file-name asset (org-publish-property :base-directory assets-project))))
;;       pub-asset pub-asset-relative-name)))

(defvar demo/project-name "珊瑚礁上的程序员"
  "项目/站点名称.")

(defvar demo/project-src-root (expand-file-name "src/" (file-name-directory (or load-file-name buffer-file-name)))
  "项目源码根目录.")
(defvar demo/project-pub-root (expand-file-name "public/" (file-name-directory (or load-file-name buffer-file-name)))
  "项目发布根目录.")

(defvar demo/project-html-head
  "<link rel=\"icon\" href=\"/favicon.ico\" type=\"image/x-icon\">
<link rel=\"stylesheet\" href=\"https://cdn.staticfile.org/twitter-bootstrap/4.3.1/css/bootstrap.min.css\">
<link rel=\"stylesheet\" href=\"https://cdn.staticfile.org/font-awesome/5.11.2/css/all.min.css\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"https://fonts.googleapis.com/css?family=Amaranth|Handlee|Libre+Baskerville|Bree+Serif|Ubuntu+Mono|Pacifico&subset=latin,greek\"/>
<link rel=\"stylesheet\" href=\"/assets/css/site.css\">
")

(defun demo/project-src-path (sub-path)
  "获取项目源码子路径.  SUB-PATH."
  (expand-file-name sub-path demo/project-src-root))

(defun demo/project-pub-path (sub-path)
  "获取项目发布子路径.  SUB-PATH."
  (expand-file-name sub-path demo/project-pub-root))

(defun demo--pre/postamble-format (name)
  "读取snippets目录下的代码片段文件, 返回格式化的pre/postamble内容.  NAME."
  `(("en" ,(with-temp-buffer
             (insert-file-contents (expand-file-name (format "%s.html" name) (demo/project-src-path "snippets")))
             (buffer-string)))))

(defun demo--insert-snippet (filename)
  "读取snippets目录下的代码片段文件, 返回文件内容.  FILENAME."
  (with-temp-buffer
    (insert-file-contents (expand-file-name filename (demo/project-src-path "snippets")))
    (buffer-string)))

(defun demo/org-html-publish-site-to-html (plist filename pub-dir)
  "PLIST, FILENAME, PUB-DIR."
  (let* ((file-path (org-html-publish-to-html plist filename pub-dir)))
    (save-window-excursion
      (with-current-buffer (find-file-noselect file-path)
        (goto-char (point-min))
        (search-forward "<body>")
        (insert (concat "\n<div class=\"content-wrapper container\">"
                        "\n<div class=\"row\">"
                        "\n<div class=\"col-lg-8 col-md-10 mx-auto\">\n"))
        (goto-char (point-max))
        (search-backward "</body>")
        (insert "\n</div>\n</div>\n</div>\n")
        (insert (demo--insert-snippet "analytics.js.html"))
        (insert (demo--insert-snippet "statcounter.js.html"))
        (save-buffer)
        (kill-buffer)))
    file-path))

(defun demo/org-publish-sitemap--valid-entries (entries)
  "ENTRIES."
  (-filter (lambda (x) (car x)) entries))

(defun demo/org-html-publish-post-to-html (plist filename pub-dir)
  "PLIST, FILENAME, PUB-DIR."
  (let* ((project (cons 'blog plist)))
    (plist-put plist
               :subtitle nil)
    (unless (equal "archive.org" (file-name-nondirectory filename))
      (plist-put plist
                 :subtitle (format "Published on %s"
                                   (format-time-string "%h %d, %Y" (org-publish-find-date filename project))))))

  (let* ((file-path (org-html-publish-to-html plist filename pub-dir)))
    (save-window-excursion
      (with-current-buffer (find-file-noselect file-path)
        (goto-char (point-min))
        (search-forward "<body>")
        (insert (concat "\n<div class=\"content-wrapper container\">"
                        "\n<div class=\"row\">"
                        "\n<div class=\"col-lg-8 col-md-10 mx-auto\">\n"))
        (goto-char (point-max))
        (search-backward "</body>")
        (unless (equal "archive.org" (file-name-nondirectory filename))
          (insert (demo--insert-snippet "disqus.js.html")))
        (insert "\n</div>\n</div>\n</div>\n")
        (insert (demo--insert-snippet "analytics.js.html"))
        (insert (demo--insert-snippet "statcounter.js.html"))
        (save-buffer)
        (kill-buffer)))
    file-path))

(defun demo/org-publish-sitemap-publish-archive (title sitemap)
  "TITLE, SITEMAP."
  (let* ((title  (format "%s - Archive" demo/project-name))
         (posts (cdr sitemap))
         (posts (demo/org-publish-sitemap--valid-entries posts)))
    (concat (format "#+TITLE: %s\n#+KEYWORDS:%s, Archive\n#+OPTIONS: title:nil\n\n" title demo/project-name)
            "#+HTML: <header><h1>Blog Archive</h1></header>"
            "\n#+begin_archive\n"
            (mapconcat (lambda (li)
                         (format "@@html:<li>@@ %s @@html:</li>@@" (car li)))
                       (seq-filter #'car posts)
                       "\n")
            "\n#+end_archive\n")))

(defun demo/org-publish-sitemap-format-archive-entry (entry style project)
  "ENTRY, STYLE, PROJECT."
  (format "@@html:<span class=\"archive-item\"><span class=\"archive-date\">@@ %s @@html:</span>@@ [[file:%s][%s]] @@html:</span>@@"
          (format-time-string "%h %d, %Y" (org-publish-find-date entry project))
          entry
          (org-publish-find-title entry project)))

(defun demo/org-rss-publish-to-rss (plist filename pub-dir)
  "PLIST, FILENAME, PUB-DIR."
  (if (equal "rss.org" (file-name-nondirectory filename))
      (org-rss-publish-to-rss plist filename pub-dir)))

(defun demo/org-publish-sitemap-publish-rss (title sitemap)
  "TITLE, SITEMAP."
  (let* ((title demo/project-name))
    (concat (format "#+TITLE: %s\n\n" title)
            (org-list-to-subtree sitemap '(:icount "" :istart "")))))

(defun demo/org-publish-sitemap-format-rss-entry (entry style project)
  "ENTRY, STYLE, PROJECT."
  (cond ((not (directory-name-p entry))
         (let* ((file (org-publish--expand-file-name entry project))
                (title (org-publish-find-title entry project))
                (date (format-time-string "%Y-%m-%d" (org-publish-find-date entry project)))
                (link (concat (file-name-sans-extension entry) ".html")))
           (with-temp-buffer
             (insert (format "* [[file:%s][%s]]\n" file title))
             (org-set-property "RSS_PERMALINK" link)
             (org-set-property "PUBDATE" date)
             ;; To avoid second update to rss.org by org-icalendar-create-uid
             (org-id-get-create)
             (insert-file-contents file)
             (buffer-string))))
        ((eq style 'tree)
         ;; Return only last subdir.
         (file-name-nondirectory (directory-file-name entry)))
        (t entry)))

(defvar demo/org-publish-project-alist
  (list
   (list "blog-posts"
         :base-directory (demo/project-src-path "posts")
         :base-extension "org"
         :recursive t
         :exclude (regexp-opt '("archive.org" "rss.org"))

         :publishing-directory (demo/project-pub-path "posts")
         :publishing-function #'demo/org-html-publish-post-to-html

         :section-numbers nil
         :with-toc nil
         :with-title t
         :with-author nil
         :with-creator nil
         :html-doctype "html5"
         :html-html5-fancy t
         :html-head-include-scripts nil
         :html-head-include-default-style nil
         :html-head-extra demo/project-html-head
         :html-preamble t
         :html-preamble-format (demo--pre/postamble-format 'preamble)
         :html-postamble t
         :html-postamble-format (demo--pre/postamble-format 'postamble)

         :auto-sitemap t
         :sitemap-style 'list
         :sitemap-filename "archive.org"
         :sitemap-title nil
         :sitemap-sort-folders 'ignore
         :sitemap-sort-files 'anti-chronologically
         :sitemap-ignore-case nil
         :sitemap-date-format "%h %d, %Y"
         :sitemap-function #'demo/org-publish-sitemap-publish-archive
         :sitemap-format-entry #'demo/org-publish-sitemap-format-archive-entry)

   (list "blog-rss"
         :base-directory (demo/project-src-path "posts")
         :base-extension "org"
         :recursive t
         :exclude (regexp-opt '("archive.org" "rss.org"))

         :publishing-directory (demo/project-pub-path "posts")
         :publishing-function #'demo/org-rss-publish-to-rss

         :html-link-home "http://demokn.com/posts/"
         :html-home/up-format ""
         :html-link-use-abs-url t
         :html-link-org-files-as-html t

         :auto-sitemap t
         :sitemap-style 'list
         :sitemap-filename "rss.org"
         :sitemap-title nil
         :sitemap-sort-folders 'ignore
         :sitemap-sort-files 'anti-chronologically
         :sitemap-ignore-case nil
         :sitemap-function #'demo/org-publish-sitemap-publish-rss
         :sitemap-format-entry #'demo/org-publish-sitemap-format-rss-entry)

   (list "site"
         :base-directory demo/project-src-root
         :base-extension "org"
         :recursive nil

         :publishing-directory demo/project-pub-root
         :publishing-function #'demo/org-html-publish-site-to-html

         :section-numbers nil
         :with-toc nil
         :with-title nil
         :with-author nil
         :with-creator nil
         :html-doctype "html5"
         :html-html5-fancy t
         :html-head-include-scripts nil
         :html-head-include-default-style nil
         :html-head-extra demo/project-html-head
         :html-preamble t
         :html-preamble-format (demo--pre/postamble-format 'preamble)
         :html-postamble t
         :html-postamble-format (demo--pre/postamble-format 'postamble))

   (list "assets"
         :base-directory demo/project-src-root
         :base-extension (regexp-opt '("ico" "jpg" "jpeg" "png" "gif" "svg" "css" "js"))
         :recursive t
         :include '("CNAME")

         :publishing-directory demo/project-pub-root
         :publishing-function #'org-publish-attachment)

   (list "all"
         :components '("blog-posts" "blog-rss" "site" "assets"))))

(defun demo/org-publish-all ()
  "发布博客."
  (interactive)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((dot .t) (plantuml ,t)))
  (let ((make-backup-files nil)
        (org-publish-project-alist demo/org-publish-project-alist)
        (org-publish-timestamp-directory "./.org-timestamps/")
        (org-publish-cache nil)
        (org-publish-use-timestamps-flag nil)
        (org-export-with-section-numbers nil)
        (org-export-with-smart-quotes t)
        (org-export-with-toc nil)
        (org-export-with-sub-superscripts '{})
        (org-thml-container-element "section")
        (org-html-metadata-timestamp-format "%h %d, %Y")
        (org-html-checkbox-type 'html)
        (org-html-html5-fancy t)
        (org-html-validation-link nil)
        (org-html-doctype "html5")
        (org-html-htmlize-output-type 'css))
    (org-publish-all)))

(provide 'publish)
;;; publish.el ends here
