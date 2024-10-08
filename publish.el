;;; package --- summary
;;; Commentary:

;;; Code:
(require 'package)
(setq package-user-dir (expand-file-name "./.elpa"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; 安装依赖包
(dolist (pkg '(org ox-rss dash htmlize json-mode yaml-mode php-mode))
  (unless (package-installed-p pkg)
    (package-install pkg)))

;; 加载依赖包
(require 'dash)
(require 'org)
(require 'ox-publish)
(require 'ox-rss)

(setq debug-on-error t)
(setq org-startup-folded nil)

;; 在本地导出图片即可, 无需每次编译都重新导出
;; (with-eval-after-load 'ob-plantuml
;;   (let ((jar-name "plantuml.jar")
;;         (url "http://jaist.dl.sourceforge.net/project/plantuml/plantuml.jar"))
;;     (setq org-plantuml-jar-path (expand-file-name jar-name user-emacs-directory))
;;     (unless (file-exists-p org-plantuml-jar-path)
;;       (url-copy-file url org-plantuml-jar-path))))

;; (defun kn/org-confirm-babel-evaluate (lang body)
;;   "执行代码前是否需要确认.  LANG: 语言, BODY: 代码块."
;;   (not (or
;;         (string= lang "ditaa")
;;         (string= lang "plantuml"))))
;; (setq org-confirm-babel-evaluate #'kn/org-confirm-babel-evaluate)

;; (defun kn/hash-for-filename (filename)
;;   "计算指定文件的散列值.  FILENAME: 文件路径."
;;   (with-temp-buffer
;;     (insert-file-contents filename)
;;     (secure-hash 'sha256 (current-buffer))))

;; (defun kn/asset-relative-link-to (asset pub-dir &optional versioned)
;;   "获取资源文件相对于文章发布目录的路径.  ASSET: 资源文件, PUB-DIR: 发布目录, VERSIONED: 是否添加版本标记."
;;   (let* ((assets-project (assoc "assets" org-publish-project-alist 'string-equal))
;;          (pub-asset (expand-file-name asset (org-publish-property :publishing-directory assets-project)))
;;          (pub-asset-relative-name (file-relative-name pub-asset pub-dir)))
;;     (if versioned
;;         (format "%s?v=%s" pub-asset-relative-name
;;                 (kn/hash-for-filename (expand-file-name asset (org-publish-property :base-directory assets-project))))
;;       pub-asset pub-asset-relative-name)))

(defvar kn/site-name "珊瑚礁上的程序员"
  "项目/站点名称.")
(defvar kn/site-url "https://demokn.github.io/blog"
  "网站地址.")
(defvar kn/posts-url (concat kn/site-url "posts/")
  "文章地址.")

(defvar kn/src-dir (expand-file-name "src/" (file-name-directory (or load-file-name buffer-file-name)))
  "项目源码根目录.")
(defvar kn/pub-dir (expand-file-name "public/" (file-name-directory (or load-file-name buffer-file-name)))
  "项目发布根目录.")

;; 对于引用的外部CSS库，最好是下载到本地.
;; 使用CDN引用的话，google search 可能无法爬取，导致“移动设备易用性”检查出现错误.
(defvar kn/html-head
  (concat "<link rel=\"icon\" href=\"" kn/site-url "/favicon.ico\" type=\"image/x-icon\">
<link rel=\"stylesheet\" href=\"" kn/site-url "/assets/lib/twitter-bootstrap/4.4.1/bootstrap.min.css\">
<link rel=\"stylesheet\" href=\"" kn/site-url "/assets/lib/font-awesome/5.12.1/all.min.css\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"https://fonts.googleapis.com/css?family=ZCOOL+KuaiLe|Amaranth|Handlee|Libre+Baskerville|Bree+Serif|Ubuntu+Mono|Pacifico&subset=latin,greek\"/>
<link rel=\"stylesheet\" href=\"" kn/site-url "/assets/css/site.css\">
<link rel=\"stylesheet\" href=\"" kn/site-url "/assets/css/highlight.css\">
"))

(defun kn/src-path (sub-path)
  "获取项目源码子路径.  SUB-PATH."
  (expand-file-name sub-path kn/src-dir))

(defun kn/pub-path (sub-path)
  "获取项目发布子路径.  SUB-PATH."
  (expand-file-name sub-path kn/pub-dir))

(defun kn--pre/postamble-format (name)
  "读取snippets目录下的代码片段文件, 返回格式化的pre/postamble内容.
NAME 是代码片段的文件名（不含扩展名）。"
  (let ((file-path (expand-file-name (format "%s.html" name) (kn/src-path "snippets")))
        ;; 定义占位符和实际变量值的映射表
        (placeholders `(("{{kn/site-url}}" . ,kn/site-url)
                        ("{{kn/site-name}}" . ,kn/site-name)
                        ;; 这里可以继续添加更多占位符
                        )))
    (if (file-exists-p file-path)
        (let ((content (with-temp-buffer
                         (insert-file-contents file-path)
                         (buffer-string))))
          ;; 替换占位符
          (dolist (placeholder placeholders)
            (setq content (replace-regexp-in-string (car placeholder) (cdr placeholder) content)))
          ;; 返回替换后的内容
          `(("en" ,content)))
      (progn
        (message "文件 %s 不存在，使用默认内容" file-path)
        `(("en" "<!-- Default content -->"))))))

(defun kn--insert-snippet (filename)
  "读取snippets目录下的代码片段文件, 返回文件内容.  FILENAME."
  (with-temp-buffer
    (insert-file-contents (expand-file-name filename (kn/src-path "snippets")))
    (buffer-string)))

(defun kn/org-html-publish-site-to-html (plist filename pub-dir)
  "Publish site's non-post org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
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
        (insert (kn--insert-snippet "analytics.js.html"))
        (insert (kn--insert-snippet "statcounter.js.html"))
        (save-buffer)
        (kill-buffer)))
    file-path))

(defun kn/org-publish-sitemap--valid-entries (entries)
  "ENTRIES."
  (-filter (lambda (x) (car x)) entries))

(defun kn/org-html-publish-post-to-html (plist filename pub-dir)
  "Publish site's post org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (let* ((project (cons 'blog plist)))
    (plist-put plist
               :subtitle nil)
    (unless (equal "archive.org" (file-name-nondirectory filename))
      (plist-put plist
                 :subtitle (format "发布于 %s"
                                   (format-time-string "%Y-%m-%d" (org-publish-find-date filename project))))))

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
          (insert (kn--insert-snippet "disqus.js.html")))
        (insert "\n</div>\n</div>\n</div>\n")
        (insert (kn--insert-snippet "analytics.js.html"))
        (insert (kn--insert-snippet "statcounter.js.html"))
        (save-buffer)
        (kill-buffer)))
    file-path))

(defun kn/org-publish-sitemap-publish-archive (title sitemap)
  "Default posts archive site map, as a string.

TITLE is the the title of the site map.  SITEMAP is an internal
representation for the files to include, as returned by
‘org-list-to-lisp’.  PROJECT is the current project."
  (let* ((title  (format "%s - Archive" kn/site-name))
         (posts (cdr sitemap))
         (posts (kn/org-publish-sitemap--valid-entries posts)))
    (concat (format "#+TITLE: %s\n#+KEYWORDS:%s, Archive\n#+OPTIONS: title:nil\n\n" title kn/site-name)
            "#+HTML: <header><h1>Blog Archive</h1></header>"
            "\n#+BEGIN_archive\n"
            (mapconcat (lambda (li)
                         (format "@@html:<li>@@ %s @@html:</li>@@" (car li)))
                       (seq-filter #'car posts)
                       "\n")
            "\n#+END_archive\n")))

(defun kn/org-publish-sitemap-format-archive-entry (entry style project)
  "Default format for posts archive site map ENTRY, as a string.

ENTRY is a file name.  STYLE is the style of the sitemap.
PROJECT is the current project."
  (format "@@html:<span class=\"archive-item\"><span class=\"archive-date\">@@ %s @@html:</span>@@ [[file:%s][%s]] @@html:</span>@@"
          (format-time-string "%Y-%m-%d" (org-publish-find-date entry project))
          entry
          (org-publish-find-title entry project)))

(defun kn/org-rss-publish-to-rss (plist filename pub-dir)
  "Publish an org file to RSS.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (if (equal "rss.org" (file-name-nondirectory filename))
      (org-rss-publish-to-rss plist filename pub-dir)))

(defun kn/org-publish-sitemap-publish-rss (title sitemap)
  "Default posts rss site map, as a string.

TITLE is the the title of the site map.  SITEMAP is an internal
representation for the files to include, as returned by
‘org-list-to-lisp’.  PROJECT is the current project."
  (let* ((title kn/site-name))
    (concat (format "#+TITLE: %s\n" title)
            (format "#+KEYWORDS: %s\n\n" title)
            (org-list-to-subtree sitemap nil '(:istart "" :icount "")))))
(defun kn/org-publish-sitemap-format-rss-entry (entry style project)
  "Default format for posts rss site map ENTRY, as a string.

ENTRY is a file name.  STYLE is the style of the sitemap.
PROJECT is the current project."
  (cond ((not (directory-name-p entry))
         (let* ((file (org-publish--expand-file-name entry project)) ;; org文件绝对路径
                (title (org-publish-find-title entry project)) ;; 文章标题(#+TITLE)
                (pubdate (format-time-string "%Y-%m-%d" (org-publish-find-date entry project))) ;; 发布时间(#+DATE)
                ;; git 不会存储文件的元数据(文件的最后修改时间会是git clone的时间)
                ;; (moddate (format-time-string "%Y-%m-%d" (file-attribute-modification-time (file-attributes file)))) ;; 文件最后修改时间
                ;; 这种方式并不能从org文件中取到moddate属性
                ;; (moddate (or (format-time-string "%Y-%m-%d" (org-publish-find-property file :moddate project))
                ;; pubdate))
                (moddate pubdate)
                (link (concat (file-name-sans-extension entry) ".html"))) ;; 文件后缀改为 .html
           (message "文件: %s\n发布时间: %s\n更新时间: %s" file pubdate moddate)
           ;; (message (org-publish-find-property file :title project))
           ;; (message (org-publish-find-property file :date project))

           (with-temp-buffer
             ;; 用链接的方式, title 会取成文件路径
             ;; (insert (format "* [[file:%s][%s]]\n" file title))
             (insert (format "* %s\n" title))
             (org-set-property "RSS_PERMALINK" link)
             (org-set-property "PUBDATE" pubdate)
             (org-set-property "MODDATE" moddate)
             ;; To avoid second update to rss.org by org-icalendar-create-uid
             ;; (org-id-get-create)
             ;; (insert-file-contents file)
             (buffer-string))))
        ((eq style 'tree)
         ;; Return only last subdir.
         (file-name-nondirectory (directory-file-name entry)))
        (t entry)))

(org-export-define-derived-backend 'kn/sitemap 'rss
  :translate-alist
  '((headline . kn/org-sitemap-headline)
    (template . kn/org-sitemap-template)))

(defun kn/org-sitemap-headline (headline contents info)
  "Transcode HEADLINE element into sitemap format.

CONTENTS is the headline contents.  INFO is a plist used as a
communication channel."
  (let* ((htmlext (plist-get info :html-extension))
         (hl-number (org-export-get-headline-number headline info))
         (hl-home (file-name-as-directory (plist-get info :html-link-home)))
         (hl-pdir (plist-get info :publishing-directory))
         (hl-perm (org-element-property :RSS_PERMALINK headline))
         (hl-moddate (org-element-property :MODDATE headline))
         (publink
          (or (and hl-perm (concat (or hl-home hl-pdir) hl-perm))
              (concat
               (or hl-home hl-pdir)
               (file-name-nondirectory
                (file-name-sans-extension
                 (plist-get info :input-file)))
               "."
               htmlext)))
         )
    (format (concat
             "<url>\n"
             "<loc>%s</loc>\n"
             "<lastmod>%s</lastmod>\n"
             "</url>\n")
            publink hl-moddate)))

(defun kn/org-sitemap-template (contents info)
  "Return complete document string after SITEMAP conversion.

CONTENTS is the transcoded contents string.  INFO is a plist used
as a communication channel."
  (concat
   (format "<?xml version=\"1.0\" encoding=\"%s\"?>\n"
           (symbol-name org-html-coding-system))
   "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
   contents
   "</urlset>"))

(defun kn/org-sitemap-publish-to-sitemap (plist filename pub-dir)
  "Publish org file to SITEMAP.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (if (equal "sitemap.org" (file-name-nondirectory filename))
      (org-publish-org-to
       'kn/sitemap filename ".xml" plist pub-dir)))

(defvar kn/org-publish-project-alist
  (list
   (list "blog-posts" ;; 文章发布
         :base-directory (kn/src-path "posts")
         :base-extension "org"
         :recursive t
         :exclude (regexp-opt '("archive.org" "rss.org"))

         :publishing-directory (kn/pub-path "posts")
         :publishing-function #'kn/org-html-publish-post-to-html

         :with-toc nil ;; 是否包含目录
         :with-title t ;; 是否包含标题
         :with-author nil ;; 是否包含作者名称
         :with-creator nil ;; 是否包含 Emacs 和 Org 版本信息
         :section-numbers nil ;; 是否包含块编号
         :time-stamp-file nil ;; 是否包含时间戳
         :html-doctype "html5"
         :html-html5-fancy t
         :html-head-include-scripts nil
         :html-head-include-default-style nil
         :html-head kn/html-head
         :html-preamble t
         :html-preamble-format (kn--pre/postamble-format 'preamble)
         :html-postamble t
         :html-postamble-format (kn--pre/postamble-format 'postamble)
         :html-divs '((preamble "div" "preamble")
                      (content "div" "article")
                      (postamble "div" "postamble"))

         :auto-sitemap t
         :sitemap-style 'list
         :sitemap-filename "archive.org"
         :sitemap-title nil
         :sitemap-sort-folders 'ignore
         :sitemap-sort-files 'anti-chronologically
         :sitemap-ignore-case nil
         :sitemap-date-format "%Y-%m-%d"
         :sitemap-function #'kn/org-publish-sitemap-publish-archive
         :sitemap-format-entry #'kn/org-publish-sitemap-format-archive-entry)

   (list "blog-posts-rss" ;; 文章 RSS 订阅
         :base-directory (kn/src-path "posts")
         :base-extension "org"
         :recursive t
         :exclude (regexp-opt '("archive.org" "rss.org"))

         :publishing-directory (kn/pub-path "posts")
         :publishing-function #'kn/org-rss-publish-to-rss

         :html-link-home kn/posts-url
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
         :sitemap-function #'kn/org-publish-sitemap-publish-rss
         :sitemap-format-entry #'kn/org-publish-sitemap-format-rss-entry)

   (list "site-root" ;; 网站根目录下的 org 文件发布, 如 index.org about.org 等
         :base-directory kn/src-dir
         :base-extension "org"
         :recursive nil
         :exclude (regexp-opt '("sitemap.org"))

         :publishing-directory kn/pub-dir
         :publishing-function #'kn/org-html-publish-site-to-html

         :section-numbers nil
         :with-toc nil
         :with-title nil
         :with-author nil
         :with-creator nil
         :time-stamp-file nil
         :html-doctype "html5"
         :html-html5-fancy t
         :html-head-include-scripts nil
         :html-head-include-default-style nil
         :html-head kn/html-head
         :html-preamble t
         :html-preamble-format (kn--pre/postamble-format 'preamble)
         :html-postamble t
         :html-postamble-format (kn--pre/postamble-format 'postamble))

   (list "sitemap" ;; 网站地图 xml 格式, SEO 需要
         :base-directory kn/src-dir
         :base-extension "org"
         :recursive t
         :exclude (regexp-opt '("drafts/" "posts/rss.org" "sitemap.org"))

         :publishing-directory kn/pub-dir
         :publishing-function #'kn/org-sitemap-publish-to-sitemap

         :html-link-home kn/site-url
         :html-home/up-format ""
         :html-link-use-abs-url t
         :html-link-org-files-as-html t

         :auto-sitemap t
         :sitemap-style 'list
         :sitemap-title nil
         :sitemap-sort-folders 'ignore
         :sitemap-sort-files 'anti-chronologically
         :sitemap-ignore-case nil
         :sitemap-function #'kn/org-publish-sitemap-publish-rss
         :sitemap-format-entry #'kn/org-publish-sitemap-format-rss-entry)

   (list "static-assets" ;; 网站静态资源文件
         :base-directory kn/src-dir
         :base-extension (regexp-opt '("ico" "jpg" "jpeg" "png" "gif" "svg" "css" "js" "pdf"))
         :recursive t
         :include '("robots.txt" "404.html")

         :publishing-directory kn/pub-dir
         :publishing-function #'org-publish-attachment)

   (list "all"
         :components '("blog-posts" "blog-posts-rss" "site-root" "sitemap" "static-assets"))))

(defun kn/org-publish-all ()
  "发布网站."
  (interactive)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((dot .t) (plantuml ,t)))
  (let ((make-backup-files nil)
        (org-publish-project-alist kn/org-publish-project-alist)
        (org-publish-timestamp-directory "./.org-timestamps/")
        (org-publish-cache nil)
        (org-publish-use-timestamps-flag nil)
        (org-export-with-section-numbers nil)
        (org-export-with-smart-quotes t)
        (org-export-with-toc nil)
        (org-export-with-sub-superscripts '{})
        (org-html-container-element "section")
        (org-html-metadata-timestamp-format "%Y-%m-%d")
        (org-html-checkbox-type 'unicode)
        (org-html-doctype "html5")
        (org-html-html5-fancy t)
        (org-html-validation-link nil)
        (org-html-htmlize-output-type 'css))
    (org-publish-all)))

(provide 'publish)
;;; publish.el ends here
