;;; zigself-mode.el --- A major mode for zigSelf code -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 sin-ack
;;
;; Author: sin-ack <sin-ack@protonmail.com>
;; Maintainer: sin-ack <sin-ack@protonmail.com>
;; Created: May 28, 2022
;; Modified: May 28, 2022
;; Version: 0.0.1
;; Keywords: languages, self
;; Homepage: https://github.com/sin-ack/zigself-mode
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  A major mode for zigSelf code.
;;
;;; Code:

(eval-when-compile
  (require 'rx))

(defgroup zigself nil
  "Support for zigSelf code."
  :link '(url-link "https://github.com/sin-ack/zigself/")
  :group 'languages)

(defcustom zigself-indent-offset 4
  "Indent zigSelf code by this number of spaces."
  :type 'integer
  :group 'zigself
  :safe #'integerp)

(defconst zigself--identifier-rx
  (rx
   (seq
    word-boundary
    (in "a-z")
    (0+ (in "a-z" "A-Z" "0-9" "_")))))

(defconst zigself--primitive-keyword-rx
  (rx
   (seq
    ?_
    (1+ (in "a-z" "A-Z" "0-9" "_"))
    ?:)))

(defconst zigself--first-keyword-rx
  (rx
   (seq
    (regexp zigself--identifier-rx)
    ?:)))

(defconst zigself--rest-keyword-rx
  (rx
   (seq
    word-boundary
    (in "A-Z")
    (0+ (in "a-z" "A-Z" "0-9" "_"))
    ?:)))

(defconst zigself--binary-message-characters
  '(?! ?@ ?# ?$ ?% ?& ?* ?, ?/ ?\\ ?> ?= ?+ ?- ?? ?\` ?\~ ?: ?\; ?.)
  "Characters that are definitely part of a binary message.

Note that `=' and `*' can also be used as syntactic constructs,
but they will be highlighted the same way regardless.")

(defconst zigself--assignable-slot-rx
  (rx
   (group (regexp zigself--identifier-rx))
   (0+ whitespace)
   (group (literal "<-"))))

(defvar zigself-mode-highlights
  `(("self" . font-lock-keyword-face)

    ;; Commonly used standard objects
    ("std" . font-lock-constant-face)
    ("nil" . font-lock-constant-face)
    ("true" . font-lock-constant-face)
    ("false" . font-lock-constant-face)

    ("\\(^\\)[^^]" 1 font-lock-keyword-face)

    (,zigself--primitive-keyword-rx . font-lock-function-name-face)
    (,zigself--first-keyword-rx . font-lock-function-name-face)
    (,zigself--rest-keyword-rx . font-lock-function-name-face)
    (,zigself--assignable-slot-rx 1 font-lock-variable-name-face)
    (,zigself--assignable-slot-rx 2 font-lock-keyword-face))
  "Font-lock keywords for `zigself-mode'.")

(defvar zigself-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?: "_" table)
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\" "!" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?| "$" table)

    (dolist (i zigself--binary-message-characters)
      (modify-syntax-entry i "." table))
    table)
  "Syntax table for `zigself-mode'.")

(defun zigself--paren-depth () "The current paren depth." (nth 0 (syntax-ppss)))
(defun zigself--in-comment-p () "Non-nil if in a comment." (nth 4 (syntax-ppss)))
(defun zigself--comment-offset () "The comment position." (nth 8 (syntax-ppss)))
(defun zigself-mode-indent-line ()
  "Indent line according to zigSelf syntactic rules."
  (interactive)
  (let ((indent-offset
         (save-excursion
           (back-to-indentation)
           (let* (;; How many parens and/or blocks we're deep.
                  ;; We want to skip any closing ]s or )s, because that would
                  ;; indent nested closing brackets too much.
                  (paren-depth
                   (save-excursion
                     (while (looking-at "[]})]") (forward-char))
                     (zigself--paren-depth)))
                  ;; Whether we're looking at a | at the start of a line. If we
                  ;; are, then we should go back by one indentation level.
                  (looking-at-slot-list-close
                   (if (<= paren-depth 0)
                       nil
                     (save-excursion
                       (and
                        (looking-at "|")
                        (progn
                          (forward-char)
                          (not (looking-at "|")))))))
                  ;; If we're in a comment, this is non-nil and gives the
                  ;; column that this line should start in.
                  (column-if-in-comment
                   (if (zigself--in-comment-p)
                       (save-excursion
                         (goto-char (zigself--comment-offset))
                         ;; If the comment start is immediately followed by a
                         ;; newline, then the rest of the comment will be
                         ;; aligned to where the comment character was.
                         (let ((comment-char-column (current-column)))
                           (forward-char)
                           (if (= (char-after) 10)
                               comment-char-column
                             (1+ comment-char-column))))
                     nil)))
             (or column-if-in-comment
               (* (if looking-at-slot-list-close
                      (1- paren-depth) paren-depth)
                  zigself-indent-offset))))))
    (if (<= (current-column) (current-indentation))
        (indent-line-to indent-offset)
      (save-excursion (indent-line-to indent-offset)))))

;;;###autoload
(define-derived-mode zigself-mode prog-mode "zigSelf"
  "A major mode for zigSelf code in textual form.

\\{zigself-mode-map}"
  :group 'zigself

  (setq font-lock-defaults '(zigself-mode-highlights))
  (setq-local comment-start "\"")
  (setq-local comment-end "\"")
  (set-syntax-table zigself-mode-syntax-table)
  (setq-local indent-line-function #'zigself-mode-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.self\\'" . zigself-mode))

(provide 'zigself-mode)
;;; zigself-mode.el ends here
