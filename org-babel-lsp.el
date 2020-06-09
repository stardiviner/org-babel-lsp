;;; org-babel-lsp.el --- Support lsp-mode in Org Mode Babel -*- lexical-binding: t; -*-

;;; Time-stamp: <2020-06-09 09:11:34 stardiviner>

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "25") (cl-lib "0.5"))
;; Package-Version: 0.1
;; Keywords: org babel lsp
;; homepage: https://github.com/stardiviner/org-babel-lsp

;; org-babel-lsp is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; org-babel-lsp is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Support LSP in Org Babel with header argument `:file'.
;; https://github.com/emacs-lsp/lsp-mode/issues/377

;;; Code:

(defvar org-babel-lsp-explicit-lang-list
  '("java")
  "Org Mode Babel languages which need explicitly specify header argument :file.")

(cl-defmacro lsp-org-babel-enbale (lang)
  "Support LANG in org source code block."
  (let* ((edit-prepare (intern (format "org-babel-edit-prep:%s" lang)))
         (lsp-prepare (intern (format "lsp--%s" (symbol-name edit-prepare)))))
    `(progn
       (defun ,lsp-prepare (info)
         (let* ((lsp-file (or (->> info caddr (alist-get :file))
                              (unless (member ,lang org-babel-lsp-explicit-lang-list)
                                (concat (org-babel-temp-file (format "lsp-%s-" ,lang))
                                        (cdr (assoc ,lang org-babel-tangle-lang-exts)))))))
           (setq-local buffer-file-name lsp-file)
           (setq-local lsp-buffer-uri (lsp--path-to-uri lsp-file))
           (lsp)))
       (if (fboundp ',edit-prepare)
           (advice-add ',edit-prepare :after ',lsp-prepare)
         (progn
           (defun ,edit-prepare (info)
             (,lsp-prepare info))
           (put ',edit-prepare 'function-documentation
                (format "Add LSP info to Org source block dedicated buffer (%s)."
                        (upcase ,lang))))))))

(defcustom org-babel-lsp-lang-list '("shell"
                                     "python" "ipython" "ruby"
                                     "js" "css" "html"
                                     "C" "C++" "go" "rust"
                                     "java" "kotlin")
  "Org Mode Babel languages will enable lsp-mode in source block."
  :type 'list
  :safe #'listp
  :group 'org-babel)

;;; FIXME
(dolist (land org-babel-lsp-lang-list
              ;; (or (seq-intersection
              ;;      (mapcar 'car org-babel-load-languages)
              ;;      (delete nil
              ;;              (mapcar (lambda (client) (lsp--client-language-id client))
              ;;                      (ht-values lsp-clients))))
              ;;     org-babel-lsp-lang-list)
              )
  (eval `(lsp-org-babel-enbale ,lang)))

(defun org-babel-lsp-add-file-header-arg ()
  "A helper command to insert `:file' header argument path."
  (org-babel-insert-header-arg
   "file"
   (format "\"%s\""
           (file-relative-name
            (read-file-name-default "Path to file: ")))))

;; (advice-add 'org-edit-src-code :before #'org-babel-lsp-add-file-header-arg)

(define-key org-babel-map (kbd "M-f") 'org-babel-lsp-add-file-header-arg)



(provide 'org-babel-lsp)

;;; org-babel-lsp.el ends here
