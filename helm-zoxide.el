;;; helm-zoxide.el --- Helm Interface for Zoxide
;;
;; Copyright: see LICENSE
;; Version: 0.0.1
;;

;;; Code:
(require 'helm)
(defgroup zoxide nil
  "Use Zoxide for finding file and opening directory."
  :group 'convenience)

(defcustom zoxide-executable (executable-find "zoxide")
  "The zoxide executable."
  :type 'string
  :group 'zoxide)

(defcustom helm-zoxide-actions
  '(("Find in dired" . helm-zoxide-find-in-dired))
  "actions for helm-zoxide"
  :type '(alist :key-type string :value-type function)
  :group 'helm-zoxide)

(defun helm-zoxide--run (async &rest args)
  "Run zoxide command with args.
The first argument ASYNC specifies whether calling asynchronously or not.
The second argument ARGS is passed to zoxide directly, like query -l"
  (if async
      (apply #'start-process "zoxide" "*zoxide*" zoxide-executable args)
    (with-temp-buffer
      (if (equal 0 (apply #'call-process zoxide-executable nil t nil args))
          (buffer-string)
        (append-to-buffer "*zoxide*" (point-min) (point-max))
        (warn "Zoxide error. See buffer *zoxide* for more details.")))))

(defun helm-zoxide--register-candidate (candidate)
  (if (and candidate (file-directory-p candidate))
      (helm-zoxide--run t "add" candidate)))

(defun helm-zoxide--register-dir-at-p ()
  (let ((filename (dired-get-filename nil t)))
    (helm-zoxide--register-candidate filename)))

(defun helm-zoxide-find-in-dired (candidate)
  "Open the given candidate in dired"
  (helm-zoxide--register-candidate candidate)
  (dired candidate))


;;;###autoload
(defun helm-zoxide ()
  "Helm for Zoxide

Called interactively, Use Zoxide to jump to a directory in dired.
"
  (interactive)
  (helm
   :prompt "zoxide: "
   :sources (helm-build-async-source "zoxide query"
              :candidates-process (lambda ()
                                    (helm-zoxide--run t "query" "-l" helm-pattern))
              :action helm-zoxide-actions)
   :buffer "*helm zoxide query*"))
(advice-add 'dired-find-file :before #'helm-zoxide--register-dir-at-p)
(advice-add 'dired-find-file-other-window :before #'helm-zoxide--register-dir-at-p)

(provide 'helm-zoxide)

;;; helm-zoxide.el ends here
