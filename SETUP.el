;; Install Jedi

(setq package-archives
      '(("gnu" . "http://elpa.gnu.org/packages/")
        ("melpa" . "http://melpa.milkbox.net/packages/")
        ))
(package-initialize)
(package-refresh-contents)
(package-install 'ag)
(package-install 'browse-kill-ring)
(package-install 'coffee-mode)
(package-install 'fzf)
(package-install 'json-mode)
(package-install 'jedi)
(package-install 'magit)
(package-install 'multiple-cursors)
(package-install 'org)
