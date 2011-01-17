;; n.b. php-mode is the modified version provided by nxhtml
;; at: lisp/nxhtml/related/php-mode.el. lisp/nxhtml/related
;; was added to the load path by nxhtml/autostart.el (which
;; is loaded in my-programming.el prior to defining the PHP
;; autoloads).
(load "php-mode") ;load the real php-mode

;; Custom php-mode configuration
(add-hook 'php-mode-hook 'my-php-mode t)

;; .php files use nxhtml-mumamo-mode
(add-hook 'nxhtml-mumamo-mode-hook 'my-nxhtml-mumamo-mode-hook t)
(defun my-nxhtml-mumamo-mode-hook ()
  ;; (and (buffer-file-name)
  ;;      (string-match "\\.php\\'" (buffer-file-name))
  ;;      ;; If this is a Drupal site, .php files need to be in Drupal
  ;;      ;; mode as well.
  ;;      (cdr (assoc 'drupal-p dir-local-variables-alist))
  ;;      (drupal-mode)))
  (and (buffer-file-name)
       (string-match "\\.php\\'" (buffer-file-name))
       (not (string-match "\\.tpl\\.php\\'" (buffer-file-name)))
       (drupal-mode)))

(defconst my-php-style
  '((c-offsets-alist . ((arglist-close . c-lineup-close-paren))))
  "My PHP programming style")
(c-add-style "my-php-style" my-php-style)

;; Configure imenu usage with php-imenu (also provided by nxhtml)
(autoload 'php-imenu-create-index "php-imenu" nil t)

(defun my-php-mode ()
  "My php-mode customisations."
  (c-set-style "my-php-style")

  ;; The electric flag (toggled by `c-toggle-electric-state').
  ;; If t, electric actions (like automatic reindentation, and (if
  ;; c-auto-newline is also set) auto newlining) will happen when an
  ;; electric key like `{' is pressed (or an electric keyword like
  ;; `else').
  (setq c-electric-flag nil)
  ;; electric behaviours appear to be bad/unwanted in php-mode

  ;; This is bugging out recently. Not sure why. Thought it
  ;; was a conflict with (my-coding-config), but not certain
  ;; any longer. Commenting out for now.
  ;; Configure imenu
  ;; (php-imenu-setup)

  ;; ;; If this is a Drupal site, .php files need to be in Drupal
  ;; ;; mode as well.
  ;; (if (cdr (assoc 'drupal-p dir-local-variables-alist))
  ;;     (my--drupal-mode))
  (my--drupal-mode);; the other code is not working

  ;; Find documentation online
  (local-set-key (kbd "<f1>") 'my-php-symbol-lookup))

(defun php-imenu-setup ()
  (setq imenu-create-index-function (function php-imenu-create-index))
  ;; uncomment if you prefer speedbar:
  ;;(setq php-imenu-alist-postprocessor (function reverse))
  (imenu-add-menubar-index))

(defun my-php-symbol-lookup ()
  "Find the symbol at point in the online PHP documentation."
  (interactive)
  (let ((symbol (symbol-at-point)))
    (if (not symbol)
        (message "No symbol at point.")
      (browse-url (concat "http://php.net/manual-lookup.php?pattern="
                          (symbol-name symbol))))))

(defun drupal-mode ()
  "PHP mode configured for Drupal development."
  (interactive)
  (php-mode)
  (my--drupal-mode)
  (message "Drupal mode activated."))

(defun my--drupal-mode ()
  "PHP mode customisations for Drupal development."
  (set 'tab-width 2)
  (set 'c-basic-offset 2)
  (set 'indent-tabs-mode nil)
  (c-set-offset 'case-label '+)
  (c-set-offset 'arglist-intro '+) ; for FAPI arrays and DBTNG
  (c-set-offset 'arglist-cont-nonempty 'c-lineup-math) ; for DBTNG fields and values

  ;; Don't clobber (too badly) doxygen comments when using fill-paragraph
  (setq paragraph-start (concat paragraph-start "\\| \\* @[a-z]+")
        paragraph-separate "$"))

