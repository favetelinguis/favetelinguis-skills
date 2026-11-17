;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; Emacs 31 configuration, originally for graphical (pgtk) Emacs.
;; Organized with outline headings (;;; and ;;;;); M-s M-s (`consult-outline')
;; navigates them.  GUI chrome is disabled in early-init.el.

;;; Elpaca
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))
;; Only read when the file exists; create it with M-x elpaca-write-lock-file.
(setq elpaca-lock-file (expand-file-name "elpaca-lock-file.el" user-emacs-directory))
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;; A GUI Emacs started from the compositor or a launcher does not inherit the
;; login shell environment, so import it.  Started from a shell it already has it.
(use-package exec-path-from-shell
  :ensure t
  :config
  (when (or (daemonp) (display-graphic-p))
    (dolist (var '("NIRI_SOCKET"
		   "OPENAI_API_KEY"
		   "TAVILY_API_KEY"))
      (add-to-list 'exec-path-from-shell-variables var))
    (exec-path-from-shell-initialize)))

;;; Update builtins
;; Magit tracks transient closely, so keep a newer copy than the built-in one.
(use-package transient
  :ensure t)

;;; Builtins

;; Write M-x customize output to its own file and load it first.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror)

(use-package savehist
  :ensure nil
  :init
  ;; save lots of good things between restarts
  ;; (register-alist is left out: markers/window configs in it can't be read back)
  (setq savehist-additional-variables '(kill-ring search-ring regexp-search-ring))
  (savehist-mode 1))

;; This is added only for keybindings that should override all other keybindings
(use-package emacs
  :ensure nil
  :init
  ;; Create the override keymap and mode BEFORE :bind
  (defvar my-override-mode-map (make-sparse-keymap)
    "Keymap for overriding all other keymaps.")
  
  (define-minor-mode my-override-mode
    "Minor mode to override all keybindings."
    :init-value t
    :global t
    :keymap my-override-mode-map)
  
  :bind (:map my-override-mode-map
              ("M-q" . iflipb-kill-buffer)
              ("M-j" . iflipb-next-buffer)
              ("M-k" . iflipb-previous-buffer)
              ("C-M-j" . consult-recent-file))
  
  :config
  ;; This is KEY - it gives your keymap highest priority
  (add-to-list 'emulation-mode-map-alists 
               `((my-override-mode . ,my-override-mode-map)))
  
  ;; Enable the mode
  (my-override-mode 1))

(use-package emacs
  :ensure nil
  :hook
  (prog-mode . (lambda () (setq truncate-lines t))); prevent long line warpping in prog modes
  ;; Disable electric-pair in Lisp modes
  (emacs-lisp-mode . (lambda () (electric-pair-local-mode -1)))
  (clojure-mode . (lambda () (electric-pair-local-mode -1)))
  (lisp-mode . (lambda () (electric-pair-local-mode -1)))
  ;; get rid of all ansi controls in compilation buffer (only the new output)
  (compilation-filter . (lambda ()
			  (ansi-color-filter-region compilation-filter-start (point))))
  :bind
  (:map global-map
	("M-g o" . ff-find-other-file)
	("M-g O" . ff-find-other-file-other-window)
	("M-`" . window-toggle-side-windows)
	("M-o" . other-window)
	)
  :config
  (recentf-mode 1)
  ;; Display date and time
  (setq display-time-format "%d, Week %V | %H:%M")
  (display-time-mode 1)
  ;; Display battery
  (display-battery-mode 1)
  (winner-mode 1) ; use C-c left/right to go over layouts
  (global-auto-revert-mode 1)
  ;; Open project files read-only; toggle with C-x C-q when editing is needed.
  (defun my/project-file-read-only ()
    "Make newly opened project files read-only."
    (require 'project)
    (when (project-current nil)
      (read-only-mode 1)))
  (add-hook 'find-file-hook #'my/project-file-read-only)
  ;; line:col/total-lines, the total is cached per buffer modification so it
  ;; is not recounted on every redisplay
  (defvar-local my/line-count--cache nil "Cons of (MODIFIED-TICK . LINE-COUNT).")
  (defun my/line-count ()
    "Return the number of lines in the buffer, cached per modification."
    (let ((tick (buffer-chars-modified-tick)))
      (unless (eql (car my/line-count--cache) tick)
	(setq my/line-count--cache
	      (cons tick (count-lines (point-min) (point-max)))))
      (cdr my/line-count--cache)))
  (setq mode-line-position
	'("%l:%c/" (:eval (number-to-string (my/line-count)))))
  (setq global-auto-revert-non-file-buffers t)
  (setq auto-revert-verbose nil)
  (setq auto-revert-interval 1) ; file-notify handles files, this is the polling fallback
  (setq scroll-margin 5)
  (setq compilation-always-kill t) ;; make rerunning compilation buffer better, i dont get asked each time to quit process between runs
  (setq compilation-scroll-output t)
  (setq set-mark-command-repeat-pop t)
  ;; start window management
  (setq switch-to-buffer-obey-display-actions t
	switch-to-buffer-in-dedicated-window 'pop)
  (setq use-short-answers t)
  (electric-pair-mode 1)
  (global-superword-mode 1)
  ;; dissable creating lock files, i can now edit the same file from multiple emacs instances which can be bad
  (setq create-lockfiles nil)
  (setq ring-bell-function 'ignore)
  ;; allow all disabled commands without prompting
  (setq disabled-command-function nil)
  ;; Use ripgrep for project search ripgrep
  (setq xref-search-program 'ripgrep)
  ;; Put auto-save files in a dedicated directory
  (setq auto-save-file-name-transforms
	`((".*" ,(concat user-emacs-directory "auto-save/") t)))
  ;; Create the directory if it doesn't exist
  (make-directory (concat user-emacs-directory "auto-save/") t)
  ;; Put backup files in a dedicated directory
  (setq backup-directory-alist
	`((".*" . ,(concat user-emacs-directory "backup/"))))
  (make-directory (concat user-emacs-directory "backup/") t)
  :custom
  ;; Curfu
  ;; TAB cycle if there are only few candidates
  ;; (completion-cycle-threshold 3)
  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  ;; (tab-always-indent 'complete)
  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)
  ;; Hide commands in M-x which do not apply to the current mode.  Corfu and
  ;; Vertico commands are hidden, since they are not used via M-x.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Vertico
  ;; Enable the right-click context menu.
  ;; `vertico-multiform-mode' adds a menu in the minibuffer to switch display modes.
  (context-menu-mode t)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

(defun my/copy-code-with-location ()
  "Copy the active region, or current line, with its file location."
  (interactive)
  (unless buffer-file-name
    (user-error "This buffer is not visiting a file"))
  (require 'project)
  (let* ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
         (end (if (use-region-p) (region-end) (line-end-position)))
         (first-line (line-number-at-pos beg t))
         ;; A region ending at the beginning of a line excludes that line.
         (last-line (line-number-at-pos (max beg (1- end)) t))
         (project (project-current nil))
         (file (if project
                   (file-relative-name buffer-file-name (project-root project))
                 buffer-file-name))
         (location (if (= first-line last-line)
                       (format "%s:%d" file first-line)
                     (format "%s:%d-%d" file first-line last-line)))
         (code (buffer-substring-no-properties beg end)))
    (kill-new (format "%s\n```\n%s%s```"
                      location code
                      (if (string-suffix-p "\n" code) "" "\n")))
    (message "Copied %s" location)))

;;; GUI
(use-package emacs
  :ensure nil
  :custom
  ;; Never use GTK dialogs or tooltips; ask in the echo area / minibuffer.
  (use-dialog-box nil)
  (use-file-dialog nil)
  (x-gtk-use-system-tooltips nil)
  ;; Quiet, steady cursor.
  (blink-cursor-mode nil)
  (cursor-in-non-selected-windows nil)
  ;; Resize frames by pixel, not character cells (tiling-window-manager friendly).
  (frame-resize-pixelwise t)
  (window-resize-pixelwise t)
  ;; Draw underlines at the font descent line, for cleaner text.
  (x-underline-at-descent-line t)
  ;; Use the system clipboard for kill/yank (pgtk talks to Wayland natively).
  (select-enable-clipboard t)
  (select-enable-primary nil)
  ;; Keep text copied in other programs on the kill ring before killing.
  (save-interprogram-paste-before-kill t)
  (kill-do-not-save-duplicates t)
  :config
  (tooltip-mode -1)                     ; show tooltips in the echo area
  ;; Smooth, pixel-precise mouse and touchpad scrolling.
  (pixel-scroll-precision-mode 1)
  ;; Font.  JetBrains Mono is installed; fall back silently when it is missing.
  (when (find-font (font-spec :name "JetBrains Mono"))
    (set-face-attribute 'default nil :family "JetBrains Mono" :height 120)))

;;; Tree-sitter
(use-package treesit
  :ensure nil
  :custom
  ;; Emacs 31: use the built-in tree-sitter mode; the grammar is installed on
  ;; first use (`treesit-auto-install-grammar' defaults to `ask').
  (treesit-enabled-modes '(dockerfile-ts-mode)))

(use-package isearch
  :ensure nil
  :bind
  ("C-M-s" . isearch-forward-other-window)
  ("C-M-r" . isearch-backward-other-window)
  :config
  (defun isearch-forward-other-window (prefix)
    "Function to isearch-forward in other-window."
    (interactive "P")
    (unless (one-window-p)
      (save-excursion
        (let ((next (if prefix -1 1)))
          (other-window next)
          (isearch-forward)
          (other-window (- next))))))

  (defun isearch-backward-other-window (prefix)
    "Function to isearch-backward in other-window."
    (interactive "P")
    (unless (one-window-p)
      (save-excursion
        (let ((next (if prefix 1 -1)))
          (other-window next)
          (isearch-backward)
          (other-window (- next))))))            )

(use-package eglot
  :ensure nil
  :hook ((java-mode . eglot-ensure)
         (java-ts-mode . eglot-ensure)
         (my/java-index-yaml-mode . eglot-ensure)
         (my/java-index-properties-mode . eglot-ensure))
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-edits nil)
  :config
  (add-to-list 'eglot-ignored-server-capabilities :inlayHintProvider)
  ;; ty is among the built-in python alternatives, but it is not the first
  ;; one tried, so pin it.
  (add-to-list 'eglot-server-programs
	       '((python-mode python-ts-mode) . ("ty" "server")))
  ;; Group all supported modes so Eglot shares one project connection.
  (add-to-list 'eglot-server-programs
               '(((java-mode :language-id "java")
                  (java-ts-mode :language-id "java")
                  (my/java-index-yaml-mode :language-id "yaml")
                  (my/java-index-properties-mode :language-id "properties"))
                 . ("jindex")))
  :bind
  (:map eglot-mode-map ; C-h . for eldoc M-.,? for xref
	("C-c a" . eglot-code-actions)
	("C-c r" . eglot-rename)))

;;; Debugger

(use-package gud
  :ensure nil
  :config
  (defun my-gud-display-line-advice (orig-fun &rest args)
    "Make gud-display-line reuse existing windows."
    (let ((display-buffer-overriding-action
           '((display-buffer-reuse-window 
	      display-buffer-use-some-window)
             (inhibit-same-window . t))))
      (apply orig-fun args)))

  (advice-add 'gud-display-line :around #'my-gud-display-line-advice))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer)
  :config (setq ibuffer-expert t))

(use-package which-key
  :ensure nil
  :config
  (which-key-mode 1))

(use-package ediff
  :ensure nil
  :config
  ;; dont open external frame with ediff
  (setq ediff-window-setup-function 'ediff-setup-windows-plain))

(use-package repeat
  :ensure nil
  :config
  (repeat-mode 1))

(use-package project
  :ensure nil
  :preface
  (defun my/project-refresh ()
    (interactive)
    (project-remember-projects-under "~/repos" t)))

(use-package flymake
  :ensure nil
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)
         ("C-x p D" . flymake-show-project-diagnostics)))

;;; In-Buffer Completion 
(use-package corfu
  :ensure t
  :custom
  ;; Make the popup appear quicker
  (corfu-popupinfo-delay '(0.5 . 0.5))
  ;; Always have the same width
  (corfu-min-width 80)
  (corfu-max-width corfu-min-width)
  (corfu-count 14)
  (corfu-scroll-margin 4)
  ;; Have Corfu wrap around when going up
  (corfu-cycle t)
  (corfu-preselect 'first)
  (corfu-auto nil) ; set to t to autoshow
  (corfu-quit-no-match 'separator)
  :config
  (define-key corfu-map (kbd "M-p") #'corfu-popupinfo-scroll-down) ;; corfu-next
  (define-key corfu-map (kbd "M-n") #'corfu-popupinfo-scroll-up)  ;; corfu-previous
  :init

  ;; Recommended: Enable Corfu globally.  Recommended since many modes provide
  ;; Capfs and Dabbrev can be used globally (M-/).  See also the customization
  ;; variable `global-corfu-modes' to exclude certain modes.
  (global-corfu-mode)

  ;; Enable optional extension modes (corfu-history persists via savehist):
  (corfu-history-mode)
  (corfu-popupinfo-mode))

(use-package cape
  :ensure t
  ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  ;; Press M-<tab> ? to for help (a window manager may grab M-<tab>).
  :bind ("M-<tab>" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  ;; (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  ;; (add-hook 'completion-at-point-functions #'cape-elisp-block)
  ;; (add-hook 'completion-at-point-functions #'cape-history)
  ;; ...
  )

;;; Theme
;; Built-in Modus themes, matching the ghostty theme.
(load-theme 'modus-operandi t)

;; Config file modes
(use-package markdown-mode
  :ensure t
  :hook (markdown-mode . visual-line-mode))

;;; Version control
(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch)
	 ;; Override just these VC keys; the rest of C-x v (incl. Emacs 31's
	 ;; worktree commands on C-x v w) stays available.
	 :map vc-prefix-map
	 ("v" . magit-status)
	 ("d" . magit-diff)
	 ("l" . magit-log)
	 ("b" . magit-blame)
	 ("f" . magit-file-dispatch))
  :init
  ;; Make project.el use magit (in :init so it works before magit is loaded)
  (with-eval-after-load 'project
    (setq project-switch-commands
	  (assoc-delete-all 'project-vc-dir project-switch-commands))
    (keymap-set project-prefix-map "v" #'magit-project-status)
    (add-to-list 'project-switch-commands '(magit-project-status "Magit") t)))

(use-package git-timemachine
  :ensure t
  :bind (:map vc-prefix-map
	      ("t" . git-timemachine))
  :config
  ;; Show abbreviated commit hash in header line
  (setq git-timemachine-show-minibuffer-details t)
  ;; Automatically kill timemachine buffer when quitting
  (setq git-timemachine-quit-to-invoking-buffer t))

;; Indicators are drawn in the fringe.
(use-package diff-hl
  :ensure t
  :demand t
  :bind-keymap ("C-x v h" . my/diff-hl-repeat-map)
  :bind
  (:repeat-map my/diff-hl-repeat-map
	       ("n" . diff-hl-next-hunk)
	       ("p" . diff-hl-previous-hunk)
	       ("k" . diff-hl-revert-hunk)
	       ("=" . diff-hl-show-hunk)
	       ("m" . diff-hl-mark-hunk)
	       ("s" . diff-hl-stage-dwim)
	       :exit
	       ("v" . magit-status)
	       ("f" . magit-file-dispatch))
  :hook
  (magit-post-refresh . diff-hl-magit-post-refresh)
  :config
  (which-key-add-key-based-replacements
    "C-x v h"  "git-hunk")
  (global-diff-hl-mode 1))

;;; Completions stack vertico - orderless - marginalia - consult
(use-package vertico
  :ensure t
  :custom
  ;; (vertico-scroll-margin 0) ;; Different scroll margin
  ;; (vertico-count 20) ;; Show more candidates
  ;; (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

(use-package orderless
  :ensure t
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion))))
  ;; Emacs 31: partial-completion matches anywhere, like substring
  (completion-pcm-leading-wildcard t))

(use-package marginalia
  :ensure t
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
	      ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))

(use-package consult
  :ensure t
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
	 ;;         ("C-c k" . consult-kmacro)
	 ;;         ("C-c m" . consult-man)
	 ;;         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ("C-x r j" . consult-register-load)
         ("C-x r SPC" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-x r r" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
	 ("M-g a" . consult-yank-pop)
         ("M-g e" . consult-compile-error)
         ("M-g r" . consult-grep-match)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-s M-s" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-fd)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config
  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'nil)
  (setq consult-preview-key "C-.")
  (consult-customize
   consult-theme consult-man consult-org-agenda :preview-key '(:debounce 0.2 any))
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  ;; (consult-customize
  ;;  consult-theme :preview-key '(:debounce 0.2 any)
  ;;  consult-ripgrep consult-git-grep consult-grep consult-man
  ;;  consult-bookmark consult-recent-file consult-xref
  ;;  consult--source-bookmark consult--source-file-register
  ;;  consult--source-recent-file consult--source-project-recent-file
  ;;  ;; :preview-key "M-."
  ;;  :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )

;;; Tasks (Org)
;; Built-in Org; loaded on first use through its autoloads.
(use-package org
  :ensure nil
  :hook (org-mode . visual-line-mode)
  :config
  (setq org-startup-indented t)
  (setq org-directory "~/org-agenda")
  (setq org-default-todo-file (expand-file-name "tasks.org" org-directory))
  (setq org-agenda-files (list org-directory))
  (unless (file-exists-p org-directory)
    (make-directory org-directory t))
  (setq org-capture-templates
	'(("T" "Todo with link" entry
           (file org-default-todo-file)
           "* TODO %?\n %U\n Created from: %a\n  %i"
           :empty-lines 1
	   :prepend t)
          ("t" "Todo without link" entry
           (file org-default-todo-file)
           "* TODO %?\n  %U"
           :empty-lines 1
	   :prepend t))))

;;; Notes (Denote)
;; Plain files named <identifier>--<title>__<keywords>.org in `denote-directory'.
;; Links and backlinks are derived from filenames, so there is no database.
;; Keys live under C-c n (see `my-prefix-note-map').
(use-package denote
  :ensure t
  :demand t
  :hook
  ((text-mode . denote-fontify-links-mode-maybe)
   (dired-mode . denote-dired-mode))
  :init
  (setq denote-directory (expand-file-name "~/notes/"))
  (unless (file-directory-p denote-directory)
    (make-directory denote-directory t))
  :custom
  (denote-file-type 'org)
  (denote-prompts '(title keywords))
  (denote-known-keywords '("emacs" "work" "reading" "idea" "project"))
  (denote-infer-keywords t)
  (denote-sort-keywords t)
  (denote-rename-buffer-format "%t [%k]")
  (denote-excluded-directories-regexp "\\.git\\|archive")
  (denote-backlinks-display-buffer-action
   '((display-buffer-in-side-window)
     (side . right)
     (window-width . 0.33)))
  :config
  (denote-rename-buffer-mode 1))

;; Fuzzy search over notes, built on Consult (see `consult-notes-denote-mode').
(use-package consult-notes
  :ensure t
  :demand t
  :after (consult denote)
  :config
  (consult-notes-denote-mode 1))

;;; Buffer management
(use-package iflipb
  :ensure t)

;;; Misc modes
(use-package x509-mode
  :ensure t)

(use-package jwt
  :ensure t
  :commands (jwt-decode jwt-encode))

;; OBS will need to run kdl-install-treesitter on first use
(use-package kdl-mode
  :ensure t
  :mode "\\.kdl\\'"
  :hook
  (kdl-mode . (lambda ()
                (setq-local indent-line-function #'indent-relative-first-indent-point)
		(setq-local tab-width 4))))

(use-package apheleia
  :ensure t
  :demand t
  :config
  ;; KDL
  (add-to-list 'apheleia-formatters
	       '(kdlfmt . ("kdlfmt" "format" "-")))
  (add-to-list 'apheleia-mode-alist '(kdl-mode . kdlfmt))
  ;; Markdown, apheleia ships `prettier-markdown' but does not enable it
  (add-to-list 'apheleia-mode-alist '(markdown-mode . prettier-markdown))
  (add-to-list 'apheleia-mode-alist '(gfm-mode . prettier-markdown))
  (apheleia-global-mode +1))

(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml\\'" . yaml-mode))

;; java-index recognizes these Spring/Quarkus config filenames, not all YAML
;; or properties files.  Derived modes preserve their usual editing behavior.
(define-derived-mode my/java-index-yaml-mode yaml-mode "Java-Index YAML"
  "Edit Java application YAML with java-index navigation.")
(define-derived-mode my/java-index-properties-mode conf-javaprop-mode "Java-Index Properties"
  "Edit Java application properties with java-index navigation.")
(add-to-list 'auto-mode-alist
             '("/\\(?:application\\|bootstrap\\)[^/]*\\.ya?ml\\'" . my/java-index-yaml-mode))
(add-to-list 'auto-mode-alist
             '("/\\(?:\\(?:application\\|bootstrap\\)[^/]*\\|microprofile-config\\)\\.properties\\'" . my/java-index-properties-mode))

;;; Keymap C-c
(defvar-keymap my-prefix-note-map
  :doc "My prefix key map for notes (Denote)."
  "n" #'denote
  "o" #'denote-open-or-create
  "s" #'consult-notes
  "d" #'denote-sort-dired
  "l" #'denote-link
  "L" #'denote-add-links
  "b" #'denote-backlinks
  "f" #'denote-link-find-file
  "r" #'denote-rename-file
  "k" #'denote-keywords-add
  "K" #'denote-keywords-remove)

(defun my/capture-todo ()
  "Capture a todo without a link."
  (interactive)
  (org-capture nil "t"))

(defun my/capture-todo-with-link ()
  "Capture a todo with a link to the current context."
  (interactive)
  (org-capture nil "T"))

(defvar-keymap my-prefix-task-map
  :doc "My prefix key map for tasks (Org)."
  "a" #'consult-org-agenda
  "t" #'my/capture-todo
  "T" #'my/capture-todo-with-link)

(which-key-add-keymap-based-replacements my-prefix-task-map
  "t" '("Todo without link" . my/capture-todo)
  "T" '("Todo with link" . my/capture-todo-with-link))

(defvar-keymap my-prefix-gptel-map
  :doc "Home-row prefix key map for gptel.")

(defvar-keymap my-prefix-map
  :doc "My prefix key map.
Its parent is `mode-specific-map' so standard C-c bindings keep working."
  :parent mode-specific-map
  "n" my-prefix-note-map
  "k" my-prefix-task-map
  "l" my-prefix-gptel-map
  "m" (lambda () (interactive) (man (format "3 %s" (thing-at-point 'word t))))
  "o" #'find-file-at-point
  "v" #'project-recompile
  "w" #'my/copy-code-with-location
  ;; "l" obs l is reseved for local-only config
  "i" #'my/open-in-intellij
  "b" #'my/switch-to-bb-playground)

(which-key-add-keymap-based-replacements my-prefix-map
  "n" `("note" . ,my-prefix-note-map)
  "k" `("task" . ,my-prefix-task-map)
  "l" `("gptel" . ,my-prefix-gptel-map))

(keymap-set global-map "C-c" my-prefix-map)

;;; Terminal (Ghostel)
;; Ghostel is a terminal emulator built on libghostty-vt.  It runs the real
;; Pi / Claude Code TUIs in a buffer.  The native module is downloaded on first
;; use after confirmation (`ghostel-module-auto-install').
(use-package ghostel
  :ensure t
  :demand t
  :custom
  ;; Keep the native module outside Elpaca's rebuildable package tree.
  (ghostel-module-directory (expand-file-name "ghostel/" user-emacs-directory))
  (ghostel-module-auto-install 'ask)
  ;; Keys Emacs keeps instead of sending to the terminal (semi-char mode).
  ;; M-o (`other-window'), M-` (side windows), M-g (goto) and M-s (search)
  ;; stay available inside a terminal.
  (ghostel-keymap-exceptions
   '("C-c" "C-x" "C-u" "C-h" "M-x" "M-:" "C-\\" "M-o" "M-`" "M-g" "M-s"))
  :bind (:map project-prefix-map
              ("m" . ghostel-project)
              ("M" . ghostel-project-list-buffers))
  :config
  ;; Mode-line count of terminals that are working / need you / are done
  ;; (reported by agents through OSC 7501).  `ghostel-status-next' jumps to one.
  (ghostel-status-indicator-mode 1)
  ;; Offer a project terminal in `project-switch-project'.
  (with-eval-after-load 'project
    (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t)
    ;; Let `project-kill-buffers' kill the project's terminals too.
    (add-to-list 'project-kill-buffer-conditions '(derived-mode . ghostel-mode))))

;; Extensions that ship inside the ghostel package.
(use-package ghostel-eshell
  :ensure nil
  :after (ghostel eshell)
  :config (ghostel-eshell-visual-command-mode 1)) ; vim, htop, ... in Ghostel

(use-package ghostel-comint
  :ensure nil
  :after ghostel
  :config (ghostel-comint-global-mode 1)) ; accurate colours/links in M-x shell

(use-package ghostel-org
  :ensure nil
  :after (ghostel org)) ; [[ghostel:~/dir]] links

;; Not enabled: `ghostel-compile-global-mode' and
;; `ghostel-shell-command-global-mode' reroute every `compile' and
;; `async-shell-command' into a terminal.  Try them separately.

;; Separate MELPA package from the same repository: Consult picker with preview.
(use-package consult-ghostel
  :ensure t
  :after ghostel
  :demand t
  :bind (("C-c t" . consult-ghostel)
         :map project-prefix-map
         ("m" . consult-ghostel-project))
  :config (consult-ghostel-mode 1))

;;; Window layout

;; Give occur focus when it opens, by default focus is not switched
;; https://blog.chmouel.com/posts/emacs-isearch/
(setq display-buffer-alist
      '(((derived-mode . occur-mode)
	 (display-buffer-reuse-window display-buffer-pop-up-window)
	 (post-command-select-window . t)
	 (dedicated . t)
	 (preserve-size . (t . t)))))

(dolist (pattern '("\\*compilation\\*"
                   "\\*.*eshell\\*"
                   "\\*Man.*\\*"
		   "\\*eldoc.*\\*"		   
                   "\\*gud-.*\\*"))
  (add-to-list 'display-buffer-alist
	       `(,pattern
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.4)
                 (preserve-size . (nil . t))
                 (window-parameters . ((no-delete-other-windows . t))))))

(defun my/open-in-intellij ()
  "Open current file at point in an IDE selected from project root markers."
  (interactive)
  (let* ((file (buffer-file-name))
	 (line (number-to-string (line-number-at-pos)))
	 (col (number-to-string (current-column)))
	 (project (project-current nil))
	 (root (and project (project-root project)))
	 (has-pom (and root (file-exists-p (expand-file-name "pom.xml" root))))
	 (has-cargo (and root (file-exists-p (expand-file-name "Cargo.toml" root))))
	 (ide (cond (has-pom "idea")
		    (has-cargo "rustrover")
		    (t (completing-read "Open with: "
					'("idea" "rustrover")
					nil t nil nil "idea")))))
    (if file
	(start-process "open-in-ide" nil ide "--line" line "--column" col file)
      (user-error "Buffer is not visiting a file"))))

;;; Clojure
;; override from local_only using
;; (setq my/bb-playground-initial-content
;;       (concat
;;        ";; Local Babashka Playground\n\n"
;;        "(ns my.scratch)\n"
;;        "(println :hello)\n"))
(defvar my/bb-playground-initial-content
  (concat
   ";; Babashka Playground\n\n"
   "(ns bb-malli\n  (:require [babashka.deps :as deps]))\n"
   "(deps/add-deps '{:deps {metosin/malli {:mvn/version \"0.9.0\"}}})\n"
   "(require '[malli.core :as malli])\n\n"
   ";; Your code here\n")
  "Default content inserted into *bb-playground*.")
(use-package cider
  :ensure t
  :if (or (executable-find "clj") (executable-find "bb"))
  :defer t ; cider hooks itself into clojure-mode through its autoloads
  ;; Defined in :preface so the commands exist before cider is loaded.
  :preface
  (defun my/cider-jack-in-babashka (&optional project-dir)
    "Start a utility CIDER REPL backed by Babashka, not related to a
specific project."
    (interactive)
    (require 'cider)
    (when (get-buffer "*babashka-repl*")
      (kill-buffer "*babashka-repl*"))
    (when (get-buffer "*bb-playground*")
      (kill-buffer "*bb-playground*"))
    (let ((project-dir (or project-dir user-emacs-directory)))
      (nrepl-start-server-process
       project-dir
       "bb --nrepl-server 0"
       (lambda (server-buf)
	 (set-process-query-on-exit-flag
          (get-buffer-process server-buf) nil)
	 (cider-nrepl-connect
          (list :repl-buffer server-buf
		:repl-type 'clj
		:host (plist-get nrepl-endpoint :host)
		:port (plist-get nrepl-endpoint :port)
		:session-name "babashka"
		:repl-init-function (lambda ()
				      (setq-local cljr-suppress-no-project-warning t
                                                  cljr-suppress-middleware-warnings t
                                                  process-query-on-exit-flag nil)
				      (set-process-query-on-exit-flag
				       (get-buffer-process (current-buffer)) nil)
				      (rename-buffer "*babashka-repl*")
				      ;; Create and link playground buffer
				      (let ((playground-buffer (get-buffer-create "*bb-playground*")))
					(with-current-buffer playground-buffer
                                          (clojure-mode)
					  (insert my/bb-playground-initial-content)
					  (goto-char (point-max)) ; Move cursor to end
                                          (sesman-link-with-buffer playground-buffer '("babashka")))
					(switch-to-buffer playground-buffer)))))))))
  (defun my/switch-to-bb-playground ()
    "Switch to *bb-playground* buffer if it exists, otherwise start babashka REPL and switch to playground."
    (interactive)
    (unless (executable-find "bb")
      (user-error "Babashka (bb) is not installed"))
    (if (get-buffer "*bb-playground*")
	(switch-to-buffer "*bb-playground*")
      (my/cider-jack-in-babashka)))
  :custom
  (cider-jack-in-default 'babashka)
  (cider-repl-pop-to-buffer-on-connect nil))

;;; AI - gptel
(use-package gptel
  :ensure t
  :preface
  ;; These commands do not have upstream autoloads and live outside gptel.el.
  (autoload 'gptel-context-remove-all "gptel-context" nil t)
  (autoload 'gptel-abort "gptel-request" nil t)
  :bind
  (:map my-prefix-gptel-map
        ("m" . gptel-menu)
        ("s" . gptel-send)
        ("l" . gptel)
        ("r" . gptel-rewrite)
        ("a" . gptel-add)
        ("f" . gptel-add-file)
        ("k" . gptel-context-remove-all)
        ("x" . gptel-abort))
  :config
  (defun my/pi-agent-openrouter-api-key ()
    "Return the OpenRouter API key from pi agent's auth.json.

This reuses the same key configured for the pi coding agent
\(see ~/.pi/agent/auth.json) instead of duplicating it in this config."
    (let ((auth-file (expand-file-name "~/.pi/agent/auth.json")))
      (if (file-exists-p auth-file)
          (let-alist (json-read-file auth-file)
            (or .openrouter.key
                (user-error "No openrouter key found in %s" auth-file)))
        (user-error "pi agent auth file not found: %s" auth-file))))

  (setq gptel-backend
        (gptel-make-openai "OpenRouter"
          :host "openrouter.ai"
          :endpoint "/api/v1/chat/completions"
          :stream t
          :key #'my/pi-agent-openrouter-api-key
          :request-params '(:reasoning (:effort "low"))
          :models '(openai/gpt-6-luna))
        gptel-model 'openai/gpt-6-luna))

;; Load local_only config if present important this comes last so i can override
;; Patterns to use in extensions
;; build modes extending tabulated-list-mode with trasient menues for each mode kubed is a good example module
;; for quick access to devops command use a alist of command populating completing-read
;; then execute command with (compilation-start <cmd> t) this will support sudo and ansi output via comint mode
;; extend the compilation buffer in all good ways
(let ((local-dir (expand-file-name "local_only" user-emacs-directory)))
  (when (file-directory-p local-dir)
    (add-to-list 'load-path local-dir)
    (load (expand-file-name "init-local" local-dir) t)))
