;; (defun my-ido-filename ()
;;   "Return the filename selected with ido."
;;   (interactive)
;;   (flet ((ido-visit-buffer (filename &rest) filename)
;;          (find-file-noselect (filename &rest) filename))
;;     (let ((filename (ido-file-internal nil)))
;;       (message filename)
;;       filename)))

(defun set-region-read-only (begin end)
  "See http://stackoverflow.com/questions/7410125"
  (interactive "r")
  (let ((modified (buffer-modified-p)))
    (add-text-properties begin end '(read-only t))
    (set-buffer-modified-p modified)))

(defun set-region-writeable (begin end)
  "See http://stackoverflow.com/questions/7410125"
  (interactive "r")
  (let ((modified (buffer-modified-p))
        (inhibit-read-only t))
    (remove-text-properties begin end '(read-only t))
    (set-buffer-modified-p modified)))

(defun my-hippie-expand-completions (&optional hippie-expand-function)
  "Return the full list of possible completions generated by `hippie-expand'.
The optional argument can be generated with `make-hippie-expand-function'."
  (let ((this-command 'my-hippie-expand-completions)
        (last-command last-command)
        (buffer-modified (buffer-modified-p))
        (hippie-expand-function (or hippie-expand-function 'hippie-expand)))
    (flet ((ding)) ; avoid the (ding) when hippie-expand exhausts its options.
      (while (progn
               (funcall hippie-expand-function nil)
               (setq last-command 'my-hippie-expand-completions)
               (not (equal he-num -1)))))
    ;; Evaluating the completions modifies the buffer, however we will finish
    ;; up in the same state that we began, and (save-current-buffer) seems a
    ;; bit heavyweight in the circumstances.
    (set-buffer-modified-p buffer-modified)
    ;; Provide the options in the order in which they are normally generated.
    (delete he-search-string (reverse he-tried-table))))

(defmacro my-ido-hippie-expand-with (hippie-expand-function)
  "Generate an interactively-callable function that offers ido-based completion
using the specified hippie-expand function."
  `(lambda (&optional selection)
     (interactive
      (let ((options (my-hippie-expand-completions ,hippie-expand-function)))
        (when options
          (list (ido-completing-read "Completions: " options)))))
     (if selection
         (he-substitute-string selection t)
       (message "No expansion found"))))

(defun my-ido-hippie-expand ()
  "Offer ido-based completion for the word at point."
  (interactive)
  (call-interactively (my-ido-hippie-expand-with 'hippie-expand)))

(defun my-ido-hippie-expand-filename ()
  "Offer ido-based completion for the filename at point."
  (interactive)
  (call-interactively
   (my-ido-hippie-expand-with
    (make-hippie-expand-function '(try-complete-file-name)))))

;; Functions/keys for moving within and switching between
;; buffers and windows

(defun expand-other-window ()
  "Move to and expand the next window"
  (interactive)
  (other-window 1)
  (delete-other-windows))


;; @see https://gist.github.com/1415844
(require 'cl)
(defun my-rotate-left (l) (append (cdr l) (list (car l))))
(defun my-rotate-windows ()
  (let ((start-positions (my-rotate-left (mapcar 'window-start (window-list))))
        (buffers (my-rotate-left (mapcar 'window-buffer (window-list)))))
    (mapcar* (lambda (window buffer pos)
               (set-window-buffer window buffer)
               (set-window-start window pos))
             (window-list)
             buffers
             start-positions)))

(defun kill-other-buffer ()
  "Kill the next buffer, and expand the current one"
  (interactive)
  (other-window 1)
  (kill-buffer nil)
  (other-window -1)
  (delete-other-windows))

(defun split-window-vertically-change-buffer ()
  "Split the window vertically, and switch to the next buffer"
  (interactive)
  (split-window-vertically)
  (other-window 1)
  (switch-to-buffer (other-buffer)))

(defun scroll-one-line-ahead ()
  "Scroll ahead one line"
  (interactive)
  (scroll-up 1)
  (forward-line 1))

(defun scroll-one-line-back ()
  "Scroll back one line"
  (interactive)
  (scroll-down 1)
  (forward-line -1))

(defun my-multi-occur-in-matching-buffers (regexp &optional allbufs)
  "Show all lines matching REGEXP in all buffers.
Enhance this to ignore other known-bad files?
http://stackoverflow.com/questions/2641211/emacs-interactively-search-open-buffers/2642655#2642655"
  (interactive (occur-read-primary-args))
  (let* ((not-tags "\\([^T]\\|T[^A]\\|TA[^G]\\|TAG[^S]\\|TAGS.\\)")
         (exclude-tags-pattern (if allbufs
                                   (concat "^" not-tags)
                                 (concat "/" not-tags "[^/]*$"))))
    (multi-occur-in-matching-buffers
     exclude-tags-pattern
     regexp)))

(defun my-multi-occur-in-visible-buffers (regexp &optional arg)
  "Show all lines matching REGEXP in the current frame's visible buffers."
  (interactive (occur-read-primary-args)) ;; optional arg required but ignored
  (let ((visible-buffers nil))
    (walk-windows (lambda (window)
                    (add-to-list 'visible-buffers (window-buffer window))))
    (multi-occur visible-buffers regexp)))

(defun my-forward-word-or-buffer-or-windows (&optional arg)
  "Enable <C-left> to call next-buffer if the last command was
next-buffer or previous-buffer, and winner-redo if the last
command was winner-undo or winner-redo."
  (interactive "p")
  (cond ((memq last-command (list 'next-buffer 'previous-buffer))
         (progn (next-buffer)
                (setq this-command 'next-buffer)))
        ((memq last-command (list 'winner-redo 'winner-undo))
         (progn (winner-redo)
                (setq this-command 'winner-redo)))
        (t ;else
         (progn (forward-word arg)
                (setq this-command 'forward-word)))))

(defun my-backward-word-or-buffer-or-windows (&optional arg)
  "Enable <C-left> to call previous-buffer if the last command
was next-buffer or previous-buffer, and winner-undo if the last
command was winner-undo or winner-redo."
  (interactive "p")
  (cond ((memq last-command (list 'next-buffer 'previous-buffer))
         (progn (previous-buffer)
                (setq this-command 'previous-buffer)))
        ((memq last-command (list 'winner-redo 'winner-undo))
         (progn (winner-undo)
                (setq this-command 'winner-undo)))
        (t ;else
         (progn (backward-word arg)
                (setq this-command 'backward-word)))))

;; Provide a simpler backwards zap-to-char (than prefixing with C-u -1)
(defun zap-to-char-backwards (arg char)
  (interactive "p\ncZap backwards to char: ")
  (zap-to-char (- arg) char))

;; Enable apply-macro-to-region-lines with named macros
(defun apply-named-macro-to-region-lines (top bottom)
  "Apply named keyboard macro to all lines in the region."
  (interactive "r")
  (let ((macro (intern
                (completing-read "kbd macro (name): "
                                 obarray
                                 (lambda (elt)
                                   (and (fboundp elt)
                                        (or (stringp (symbol-function elt))
                                            (vectorp (symbol-function elt))
                                            (get elt 'kmacro))))
                                 t))))
    (apply-macro-to-region-lines top bottom macro)))

;; Uniqify region (alternative to "C-u M-| uniq RET")
(defun uniquify-region ()
  "remove duplicate adjacent lines in the given region"
  (interactive)
  (narrow-to-region (region-beginning) (region-end))
  (goto-char (point-min))
  (while (re-search-forward "\\(.*\n\\)\\1+" nil t)
    (replace-match "\\1" nil nil))
  (widen)
  nil)

;; Uniqify region (alternative to "C-u M-| sort | uniq RET")
(defun uniquify-region-sorted ()
  "sort and remove duplicate lines in the given region"
  (interactive)
  (sort-lines nil (region-beginning) (region-end))
  (uniquify-region))

;; Rename file and buffer together
(defun rename-file-and-buffer ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (message "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (cond ((get-buffer new-name)
               (message "A buffer named '%s' already exists!" new-name))
              (t
               (rename-file name new-name 1)
               (rename-buffer new-name)
               (set-visited-file-name new-name)
               (set-buffer-modified-p nil)))))))

;; Duplicate / clone the current line.
(defun clone-line (&optional arg)
  "Duplicate the line at point (arg times)."
  (interactive "*p")
  (save-excursion
    ;; The last line of the buffer cannot be killed
    ;; if it is empty. Instead, simply add a new line.
    (if (and (eobp) (bolp))
        (newline)
      ;; Otherwise kill the whole line, and yank it back.
      (let ((kill-read-only-ok t)
            deactivate-mark)
        (setq buffer-read-only t)
        (kill-whole-line)
        (setq buffer-read-only nil)
        (while (> arg 0)
          (yank)
          (setq arg (1- arg)))))))

;; Toggle between BOL and beginning of code
(defun my-beginning-of-line-or-indentation ()
  "Move to beginning of line, or indentation."
  (interactive)
  (if (bolp)
      (back-to-indentation)
    (beginning-of-line)))

(defun my-capitalize-word (&optional arg)
  "Used to invoke capitalize-word despite subword-mode remappings."
  (interactive "*p")
  (capitalize-word arg))

;; Display non-critical messages with minimal interference.
;; See also the following:
;; (minibuffer-message)
;; (with-temp-message)
(defun my-unimportant-notification (format-string &rest args)
  "Display a message temporarily, if/when minibuffer isn't active."
  (my--unimportant-notification
   format-string args
   6 ;; seed the remaining attempts counter (maximum)
   5 ;; number of seconds to increase delay by when minibuffer is active
   ))

(defun my--unimportant-notification
  (format-string args attempts increment &optional delay total)
  "Private logic for \\[my-unimportant-notification]"
  (let ((delay (or delay 0))
        (total (or total 0)))
    (if (and (eq (selected-window) (minibuffer-window))
             (> attempts 0))   ; ^^ or: (minibufferp (current-buffer)) ?
                               ; and: (not cursor-in-echo-area) ?
                               ; see: (eldoc-display-message-no-interference-p)

        ;; if the minibuffer is active, then postpone the message by an
        ;; ever-increasing delay, until we exceed our available attempt
        ;; limit (at which point we display the message regardless).
        (let* ((delay (+ increment delay))
               (total (+ total delay)))
          (run-with-timer
           delay nil
           'my--unimportant-notification
           format-string args (1- attempts) increment delay total))
      ;; otherwise show the message
      (let* ((backup-message (current-message))
             (delay-message " (message delayed %d seconds)")
             (delay-arg (or (and (zerop total) "")
                            (format delay-message total)))
             (args (append args (list delay-arg) nil))
             (format-string (concat format-string "%s"))
             (tmp-message (apply 'format format-string args)))
        ;; show message briefly, then revert.
        (message tmp-message)
        (run-with-timer
         3 nil
         (lambda (tmp-message backup-message)
           ;; revert to the backup message, unless something
           ;; else has already over-written our temporary one
           (when (string= tmp-message (current-message))
             (message backup-message)))
         tmp-message
         backup-message)))))

(defun my-interactive-ding ()
  (interactive)
  (ding))

;; Convert file's EOL style to Unix
(defun to-unix-eol (fpath)
  "Change file's line ending to unix convention."
  (let (mybuffer)
    (setq mybuffer (find-file fpath))
    (set-buffer-file-coding-system 'unix) ; or 'mac or 'dos
    (save-buffer)
    (kill-buffer mybuffer)))

;; Bulk-convert EOL style to Unix (for marked files in Dired).
(defun dired-2unix-marked-files ()
  "Change to unix line ending for marked (or next arg) files."
  (interactive)
  (mapc 'to-unix-eol (dired-get-marked-files)))

;; pop-to-mark-command in the opposite direction
;; around the local mark-ring
(defun unpop-to-mark-command ()
  "Unpop off mark ring into the buffer's actual mark.
Does not set point.  Does nothing if mark ring is empty."
  (interactive)
  (let ((num-times
         (if (equal last-command 'pop-to-mark-command) 2 1
           ;; (if (equal last-command 'unpop-to-mark-command) 1
           ;;   (error "Previous command was not a (un)pop-to-mark-command"))
           )))
    (dotimes (x num-times)
      (when mark-ring
        (setq mark-ring (cons (copy-marker (mark-marker)) mark-ring))
        (set-marker (mark-marker) (+ 0 (car (last mark-ring))) (current-buffer))
        (when (null (mark t)) (ding))
        (setq mark-ring (nbutlast mark-ring))
        (goto-char (mark t)))
      (deactivate-mark))))

(defmacro activate-my-unpop-to-mark-advice ()
  "Enable reversing direction with un/pop-to-mark."
  `(defadvice ,(key-binding (kbd "C-SPC"))
     (around my-unpop-to-mark-advice activate)
     "Unpop-to-mark with negative arg"
     (let* ((arg (ad-get-arg 0))
            (num (prefix-numeric-value arg)))
       (cond
        ;; Enabled repeated un-pops with C-SPC
        ((eq last-command 'unpop-to-mark-command)
         (if (and arg (> num 0) (<= num 4))
             ad-do-it ;; C-u C-SPC reverses back to normal direction
           ;; Otherwise continue to un-pop
           (setq this-command 'unpop-to-mark-command)
           (unpop-to-mark-command)))
        ;; Negative argument un-pops: C-- C-SPC
        ((< num 0)
         (setq this-command 'unpop-to-mark-command)
         (unpop-to-mark-command))
        (t
         ad-do-it)))))
(activate-my-unpop-to-mark-advice)

;; Kill ring / Yank assistance
(defun my-yank-menu ()
  "Select text to yank from a pop-up menu of recently killed items."
  (interactive)
  (popup-menu 'yank-menu))

(when (require 'browse-kill-ring nil 'noerror)
  ;; Either...
  ;; make it the default behaviour:
  ;;(browse-kill-ring-default-keybindings)
  ;;
  ;; or use a custom key binding:
  (global-set-key (kbd "C-c k") 'browse-kill-ring)
  )

;; Grab copy of the current buffer's filename.
(defun my-copy-buffer-file-name (&optional arg)
  "Copy the buffer's filename to the kill ring.
With a prefix arg, use the file's truename."
  (interactive "P")
  (let ((filename (if arg
                      (file-truename (buffer-file-name))
                    (buffer-file-name))))
    (if (not filename)
        (message "No buffer filename")
      (message filename)
      (kill-new filename))))

(defun my-parent-of-dir-in-buffer-file-name (dir)
  "Return the path to the parent of the named directory (arg),
within the current buffer-file-name."
  (let* ((bfn-list (split-string (buffer-file-name) "/"))
         (dir-list (reverse (cdr (member dir (reverse bfn-list))))))
    (when dir-list
      (mapconcat 'identity dir-list "/"))))

(defun my-before-save-create-directory-maybe ()
  "Offer to create the file's parent directories, if they do not exist."
  (let ((dir (file-name-directory buffer-file-name)))
    (when (and (not (file-exists-p dir))
               (y-or-n-p (format "Directory %s does not exist. Create it? " dir)))
      (make-directory dir t))))

;; Add a 'F'ind marked files keybinding to dired
(eval-after-load "dired"
  '(progn
     (define-key dired-mode-map "F" 'my-dired-find-file)
     (defun my-dired-find-file (&optional arg)
       "Open each of the marked files, or the file under the point, or when prefix arg, the next N files "
       (interactive "P")
       (let* ((fn-list (dired-get-marked-files nil arg)))
         (mapc 'find-file fn-list)))))

;; Toggle between a vertical and horizontal window split
(defun toggle-window-split ()
  (interactive)
  (when (= (count-windows) 2)
    (let* ((this-win-buffer (window-buffer))
           (next-win-buffer (window-buffer (next-window)))
           (this-win-edges (window-edges (selected-window)))
           (next-win-edges (window-edges (next-window)))
           (this-win-2nd (not (and (<= (car this-win-edges)
                                       (car next-win-edges))
                                   (<= (cadr this-win-edges)
                                       (cadr next-win-edges)))))
           (splitter
            (if (= (car this-win-edges)
                   (car (window-edges (next-window))))
                'split-window-horizontally
              'split-window-vertically)))
      (delete-other-windows)
      (let ((first-win (selected-window)))
        (funcall splitter)
        (when this-win-2nd (other-window 1))
        (set-window-buffer (selected-window) this-win-buffer)
        (set-window-buffer (next-window) next-win-buffer)
        (select-window first-win)
        (when this-win-2nd (other-window 1))))))

;; Toggle window dedication
(defun toggle-window-dedicated ()
  "Toggle whether the current active window is dedicated or not"
  (interactive)
  (message (if (let* ((window (selected-window))
                      (toggle (not (window-dedicated-p window))))
                 (set-window-dedicated-p window toggle))
               "Window '%s' is dedicated"
             "Window '%s' is normal")
           (current-buffer)))

;;
;; Ediff the current buffer's file with its auto-saved backup file.
;;
(defun ediff-auto-save ()
  "Compare the current buffer's file with its auto-saved backup file."
  (interactive)
  (let ((auto-file-name (make-auto-save-file-name))
        (file-major-mode major-mode))
    (ediff-files buffer-file-name auto-file-name)
    (switch-to-buffer-other-window (file-name-nondirectory auto-file-name))
    (apply file-major-mode '())
    (other-window 1))) ;; back to ediff panel

;;
;; Diff the current buffer with the file contents
;;
(defun diff-current-buffer-with-disk ()
  "Compare the current buffer with it's disk file."
  (interactive)
  (diff-buffer-with-file (current-buffer)))

;;(defun ediff-file-with-buffer (file-A buf-B &optional startup-hooks job-name merge-buffer-file)
;;  (let (buf-A buf-C)
;;    (message "Reading file %s ... " file-A)
;;    ;;(sit-for 0)
;;    (ediff-find-file 'file-A 'buf-A 'ediff-last-dir-A 'startup-hooks)
;;    (ediff-setup buf-B file-B
;;       startup-hooks
;;       (list (cons 'ediff-job-name job-name))
;;       merge-buffer-file)))
;;
;; see defun ediff-setup (ediff-utils.el)
;; see defun ediff-files-internal (ediff.el)


;; (defadvice kill-buffer (around my-kill-buffer-check activate)
;;   "Prompt when a buffer is about to be killed."
;;   (let* ((buffer-file-name (buffer-file-name))
;;          backup-file)
;;     ;; see 'backup-buffer
;;     (if (and (buffer-modified-p)
;;              buffer-file-name
;;              (file-exists-p buffer-file-name)
;;              (setq backup-file (car (find-backup-file-name buffer-file-name))))
;;         (let ((answer (completing-read (format "Buffer modified %s, (d)iff, (s)ave, (k)ill? " (buffer-name))
;;                                        '("d" "s" "k") nil t)))
;;           (cond ((equal answer "d")
;;                  (set-buffer-modified-p nil)
;;                  (let ((orig-buffer (current-buffer))
;;                        (file-to-diff (if (file-newer-than-file-p buffer-file-name backup-file)
;;                                          buffer-file-name
;;                                        backup-file)))
;;                    (set-buffer (get-buffer-create (format "%s last-revision" (file-name-nondirectory file-to-diff))))
;;                    (buffer-disable-undo)
;;                    (insert-file-contents file-to-diff nil nil nil t)
;;                    (set-buffer-modified-p nil)
;;                    (setq buffer-read-only t)
;;                    (ediff-buffers (current-buffer) orig-buffer)))
;;                 ((equal answer "k")
;;                  (set-buffer-modified-p nil)
;;                  ad-do-it)
;;                 (t
;;                  (save-buffer)
;;                  ad-do-it)))
;;       ad-do-it)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Improved alternative to backward-up-list
(defun backward-up-sexp (arg)
  (interactive "p")
  (let ((ppss (syntax-ppss)))
    (cond ((elt ppss 3)
           (goto-char (elt ppss 8))
           (backward-up-sexp (1- arg)))
          ((backward-up-list arg)))))

(global-set-key [remap backward-up-list] 'backward-up-sexp)


(defun my-semnav-up (arg)
  "Helper for `my-extend-selection'
By Nikolaj Schumacher, 2008-10-20. Licensed under GPL."
  (interactive "p")
  (when (nth 3 (syntax-ppss))
    (if (> arg 0)
        (progn
          (skip-syntax-forward "^\"")
          (goto-char (1+ (point)))
          (decf arg))
      (skip-syntax-backward "^\"")
      (goto-char (1- (point)))
      (incf arg)))
  (up-list arg))

(defun my-extend-selection (arg &optional incremental)
  "Mark the symbol surrounding point.
Subsequent calls mark higher levels of sexps.
By Nikolaj Schumacher, 2008-10-20. Licensed under GPL."
  (interactive (list (prefix-numeric-value current-prefix-arg)
                     (or (and transient-mark-mode mark-active)
                         (eq last-command this-command))))
  (if incremental
      (progn
        (my-semnav-up (- arg))
        (forward-sexp)
        (mark-sexp -1))
    (if (> arg 1)
        (my-extend-selection (1- arg) t)
      (if (looking-at "\\=\\(\\s_\\|\\sw\\)*\\_>")
          (goto-char (match-end 0))
        (unless (memq (char-before) '(?\) ?\"))
          (forward-sexp)))
      (mark-sexp -1))))

(defun my-region-or-word (prompt)
  "Read a string from the minibuffer, prompting with PROMPT.
If `transient-mark-mode' is non-nil and the mark is active,
it defaults to the current region, else to the word at or before
point. This function returns a list (string) for use in `interactive'."
  (list (read-string prompt (or (and transient-mark-mode mark-active
                                     (buffer-substring-no-properties
                                      (region-beginning) (region-end)))
                                (current-word)))))

(defcustom my-www-search-url
  "http://google.com/search?num=100&q=%s"
  "URL for WWW search, with %s placeholder for search string"
  :group 'www)

(defun my-www-search (string)
  "Ask a WWW browser to perform a web search for a given string.
Prompts for a string, defaulting to the active region or the current word at
or before point."
  (interactive (my-region-or-word "WWW search: "))
  (browse-url (format my-www-search-url (url-hexify-string string))))

(defun my-copy-rectangle (start end &optional fill)
  "Trigger the read-only behaviour of `kill-rectangle'."
  (interactive "r\nP")
  (let ((read-only-state buffer-read-only)
        (kill-read-only-ok t))
    (setq buffer-read-only t)
    (kill-rectangle start end fill)
    (setq buffer-read-only read-only-state)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'my-utilities)

;;; Local Variables:
;;; mode:outline-minor
;;; eval:(hide-body)
;;; End:
