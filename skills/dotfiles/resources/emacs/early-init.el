;;; early-init.el --- GUI early init -*- lexical-binding: t; -*-

;; Elpaca manages packages, so keep package.el from activating anything.
(setq package-enable-at-startup nil)

;; Defer garbage collection during startup, then restore a sane threshold.
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024))))

;; Log async native-compilation warnings instead of popping up *Warnings*.
(setq native-comp-async-report-warnings-errors 'silent)

;; Keep the eln-cache beside this configuration.
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "eln-cache/" user-emacs-directory)))

;;;; Disable GUI chrome
;; Set in the frame alists, before the first frame exists, so nothing flashes
;; and no frame is created and then resized.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

;; Avoid resizing the frame when fonts and other UI settings change.
(setq frame-inhibit-implied-resize t)

;; No startup screen, splash or echo-area advertisement.
(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

;; Start in a minimal major mode; Emacs 31 would otherwise load Lisp mode.
(setq initial-major-mode 'fundamental-mode)

;; Avoid a white flash before the theme loads.
(push '(background-color . "#ffffff") default-frame-alist)
(push '(foreground-color . "#000000") default-frame-alist)
