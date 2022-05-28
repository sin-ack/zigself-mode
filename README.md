# zigself-mode

Major mode for [zigSelf](https://github.com/sin-ack/zigself) in GNU Emacs.

## Features

- Basic syntax highlighting (keyword messages, objects, numbers, common
  keywords)
- Indentation
- `electric-indent-mode` and `smartparens` integration (allows you to open a
  pair with `(||)` and press <kbd>RET</kbd> to indent it correctly)

## Usage

Clone this repository, and use `use-package` (or `use-package!` on Doom Emacs):

```emacs-lisp
(use-package zigself-mode
    :load-path "path/to/zigself-mode"
    :hook (zigself-mode . rainbow-delimiters-mode)
    :mode ("\\.self\\'" . zigself-mode)
    :config
    ;; On Doom Emacs, disable +default-want-RET-continue-comments in order to
    ;; prevent a newline from terminating the current comment and starting a
    ;; new one.
    (setq-local +default-want-RET-continue-comments nil))

;; If you have smartparens installed:
(sp-local-pair '(zigself-mode) "|" "|"
               :post-handlers '(("||\n[i]" "RET")
                                ("| " "SPC")))
```

Using `require` is left as an exercise for the reader.

## License

Copyright &copy; 2022 sin-ack. This repository is licensed under the GNU
General Public License, version 3.
