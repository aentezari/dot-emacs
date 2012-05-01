;; Emacs configuration for Brandon Rhodes, who does lots of Python and
;; also some JavaScript when it has to run in the browser.

(add-to-list 'load-path "~/.emacs.d/site-lisp")

;; Ctrl-Tab and Shift-Ctrl-Tab switch between tabs in my browser.
;; To re-use that muscle memory, make them switch buffers in Emacs.

(global-set-key [C-tab] 'other-window)
(global-set-key [C-S-tab] (lambda () (interactive) (other-window -1)))
(global-set-key [backtab] (lambda () (interactive) (other-window -1)))

;; Flyspell to check my spelling and underline possible mistakes.

(defun turn-on-flyspell ()
  "Force flyspell-mode on."
  (interactive) (flyspell-mode 1))

(add-hook 'message-mode-hook 'turn-on-flyspell)
(add-hook 'rst-mode-hook 'turn-on-flyspell)
(add-hook 'text-mode-hook 'turn-on-flyspell)

;; Auto-fill for text and SGML modes.

(add-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'sgml-mode-hook 'turn-off-auto-fill)

;; Ispell should stop suggesting that it can cure a misspelling by
;; splitting a word into two quite different words.

(defun contains-space-p (s)
  "Determine whether a given string contains spaces."
  (string-match-p " " s))

(defadvice ispell-parse-output (after remove-multi-words activate)
  "Remove multi-word suggestions from ispell-style output."
  (if (listp ad-return-value)
      (setq ad-return-value
            (list (nth 0 ad-return-value) ;; original word
                  (nth 1 ad-return-value) ;; offset in file
                  (remove-if 'contains-space-p (nth 2 ad-return-value))
                  (remove-if 'contains-space-p (nth 3 ad-return-value))
                  ))))

;; Spell-check the whole buffer upon entry (thanks, Ryan McGuire!)
;; unless it is really huge.

(defadvice flyspell-mode
  (after advice-flyspell-check-buffer-on-start activate)
  (if (< (buffer-size) 40000)
      (flyspell-buffer)))

;; Pressing Enter should go ahead and indent the new line.

(global-set-key "\C-m" 'newline-and-indent)

;; Dedicated doctest mode.

(add-to-list 'auto-mode-alist '("\\.doctest$" . doctest-mode))
(autoload 'doctest-mode "doctest-mode" nil t)

;; Run Pymacs and Ropemacs when we enter Python mode.
;; We always use the Python that lives in the virtualenv we
;; built beneath our ".emacs.d" directory.

(setenv "PYMACS_PYTHON" "~/.emacs.d/usr/bin/python")

(autoload 'pymacs-apply "pymacs")
(autoload 'pymacs-call "pymacs")
(autoload 'pymacs-eval "pymacs" nil t)
(autoload 'pymacs-exec "pymacs" nil t)
(autoload 'pymacs-load "pymacs" nil t)

(defun set-up-rope ()
  (require 'pymacs)
  (pymacs-load "ropemacs" "rope-")
  (ropemacs-mode)
  (remove-hook 'python-mode-hook 'set-up-rope))

(add-hook 'python-mode-hook 'set-up-rope)

;; I want Tab to do variable-name completion, but Ctrl-I - which in
;; ASCII also means "Tab" - to indent the current line.  So I have to
;; convince Emacs to treat synonymous keystokes as different.

(defun set-up-tabbing ()
  (setq local-function-key-map (delq '(kp-tab . [9]) local-function-key-map))
  (define-key python-mode-map (kbd "<tab>") 'dabbrev-expand)
  (define-key python-mode-map (kbd "C-i") 'indent-for-tab-command)
  (remove-hook 'python-mode-hook 'set-up-tabbing))

(add-hook 'python-mode-hook 'set-up-tabbing)

;; Typing open-paren or -bracket should auto-insert the closing one.

(require 'autopair)
(autopair-global-mode)
(setq autopair-autowrap t)

;; Handle triple-quotes in Python; from http://code.google.com/p/autopair/

(add-hook 'python-mode-hook
          (lambda ()
            (setq autopair-handle-action-fns
                  (list #'autopair-default-handle-action
                        #'autopair-python-triple-quote-action))
            ))

;; In JavaScript, also complete on Tab but indent on Ctrl-I.

(defun one-shot-js-hook ()
  (setq local-function-key-map (delq '(kp-tab . [9]) local-function-key-map))
  (define-key js-mode-map (kbd "<tab>") 'dabbrev-expand)
  (define-key js-mode-map (kbd "C-i") 'indent-for-tab-command)
  (remove-hook 'js-mode-hook 'one-shot-js-hook))

(add-hook 'js-mode-hook 'one-shot-js-hook)

;; Org mode should activate for files that end in ".org".

(load-library "org")
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

;; Set up Flymake to use PyFlakes.

(when (load "flymake" t)
  (defun flymake-pyflakes-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list "/home/brandon/.emacs.d/usr/bin/pyflakes" (list local-file))))

  (defun flymake-gjslint-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list "/home/brandon/.emacs.d/usr/bin/gjslint"
            (list "--nojsdoc" "--unix_mode" local-file))))

  (setq flymake-allowed-file-name-masks
        (list (list (concat (expand-file-name "~") "/.*\\.py$")
                    'flymake-pyflakes-init)
              (list (concat (expand-file-name "~") "/.*\\.js$")
                    'flymake-gjslint-init)
              ))

  (add-hook 'find-file-hook 'flymake-find-file-hook))

;; A few file extensions.

(add-to-list 'auto-mode-alist '("\\.scss\\'" . css-mode))
(add-to-list 'auto-mode-alist '("\\.mako\\'" . html-mode))

;; Have dired hide irrelevant files by default; this can be toggled
;; interactively with M-o.

(require 'dired-x)
(setq dired-omit-files
      (rx (or (seq bol (? ".") "#")         ;; emacs autosave files
              (seq "~" eol)                 ;; backup-files
              (seq ".pyc" eol)
              (seq ".pyo" eol)
              )))
(setq dired-omit-extensions
      (append dired-latex-unclean-extensions
              dired-bibtex-unclean-extensions
              dired-texinfo-unclean-extensions))
(add-hook 'dired-mode-hook (lambda () (dired-omit-mode 1)))
(put 'dired-find-alternate-file 'disabled nil)

;; I sometimes write presentations right in an Emacs buffer, with "^L"
;; separating the slides.  By turning on "page-mode", I can move between
;; slides while staying in the same buffer with the "PageUp" and
;; "PageDn" keys.

(autoload 'page-mode "page-mode" nil t)

;; Load any local Emacs directives (such as extra packages, and
;; passwords that should not be stored in version control).

(if (file-exists-p "~/.emacs.d/local.el")
    (load-library "~/.emacs.d/local.el"))