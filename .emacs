;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; File name: ` ~/.emacs '
;;; ---------------------
;;;
;;; If you need your own personal ~/.emacs
;;; please make a copy of this file
;;; an placein your changes and/or extension.
;;;
;;; Copyright (c) 1997-2002 SuSE Gmbh Nuernberg, Germany.
;;;
;;; Author: Werner Fink, <feedback@suse.de> 1997,98,99,2002
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Test of Emacs derivates
;;; -----------------------5
(if (string-match "XEmacs\\|Lucid" emacs-version)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; XEmacs
  ;;; ------
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (progn
     (if (file-readable-p "~/.xemacs/init.el")
        (load "~/.xemacs/init.el" nil t))
  )
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; GNU-Emacs
  ;;; ---------
  ;;; load ~/.gnu-emacs or, if not exists /etc/skel/.gnu-emacs
  ;;; For a description and the settings see /etc/skel/.gnu-emacs
  ;;;   ... for your private ~/.gnu-emacs your are on your one.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (if (file-readable-p "~/.gnu-emacs")
      (load "~/.gnu-emacs" nil t)
    (if (file-readable-p "/etc/skel/.gnu-emacs")
        (load "/etc/skel/.gnu-emacs" nil t)))

  ;; Custom Settings
  ;; ===============
  ;; To avoid any trouble with the customization system of GNU emacs
  ;; we set the default file ~/.gnu-emacs-custom
  (setq custom-file "~/.gnu-emacs-custom")
  (load "~/.gnu-emacs-custom" t t)
;;;
)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 ;'(case-fold-search nil)
 '(column-number-mode t)
 '(line-number-mode t)
 '(mouse-wheel-mode t)
 '(revert-without-query (quote ("*")))
 '(custom-enabled-themes (quote (tango-dark)))
 ;'(ecb-options-version "2.40")
 ;'(ecb-source-path
 ;  (quote
 ;   ("c:/jlu/src/weather/geosys-weather/geosys-weather-api/src/main" "c:/jlu/src/weather/geosys-weather/geosys-weather-repository/src/main")))
 ;'(jdee-jdk-registry (quote (("1.8.0" . "C:/Program Files/Java/jdk1.8.0_91"))))
 '(show-paren-mode t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;(require 'ess-site)
(require 'package)
;; disable automatic loading of packages after init.el is done
(setq package-enable-at-startup nil)
;; and force it to happen now
(package-initialize)

;(add-to-list 'package-archives
;            '("marmalade" . "http://marmalade-repo.org/packages/"))
(add-to-list 'package-archives
             '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/"))

                                        ;(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                                        ;                         ("marmalade" . "https://marmalade-repo.org/packages/")
                                        ;                         ("melpa" . "https://melpa.org/packages/")))
(setq inhibit-startup-message t)
;;Calendrier europeen
(setq european-calendar-style 't)
(setq calendar-week-start-day 1)
;(setq calendar-day-name-array ["Dimanche" "Lundi" "Mardi" "Mercredi" "Jeudi" "Vendredi" "Samedi"])
;(setq calendar-month-name-array ["Janvier" "Fevrier" "Mars" "Avril" "Mai" "Juin" "Juillet" "Aout" "Septembre" "Octobre" "Novembre" "Decembre"])

;;automatically close brackets, quotes, etc when typing
(defun insert-parentheses () "insert parentheses and go between them" (interactive)
(insert "()")
(backward-char 1))
(defun insert-brackets () "insert brackets and go between them" (interactive)
(insert "[]")
(backward-char 1))
(defun insert-braces () "insert curly braces and go between them" (interactive)
(insert "{}")
(backward-char 1))
(defun insert-quotes () "insert quotes and go between them" (interactive)
(insert "\"\"")
(backward-char 1))
(global-set-key "(" 'insert-parentheses) ;;inserts "()"
(global-set-key "[" 'insert-brackets)
(global-set-key "{" 'insert-braces)
(global-set-key "\"" 'insert-quotes)
;(global-set-key [S-mouse-2] 'flyspell-correct-word)
;*** To return to the previous behavior, do the following:
;**** Change `select-active-regions' to nil.
;**** Change `mouse-drag-copy-region' to t.
;**** Change `x-select-enable-primary' to t (on X only).
;**** Change `x-select-enable-clipboard' to nil.
;**** Bind `mouse-yank-at-click' to mouse-2.
(setq x-select-enable-primary t)
(setq x-select-enable-clipboard nil)
(setq mouse-yank-at-point t) 
;(global-set-key (kbd "<mouse-2>") 'yank)
(global-set-key (kbd "<mouse-6>") 'yank)
(if (< emacs-major-version 25)
    ;; in emacs 24 or previous
    (defun paste-primary-selection ()
      (interactive)
      (insert (x-get-selection 'PRIMARY))
      )
  ;; in emacs 25 and above
  (defun paste-primary-selection ()
    (interactive)
    (insert (gui-get-primary-selection)))
  )
(global-set-key (kbd "S-<insert>") 'paste-primary-selection)

;; Mode parantheses
(show-paren-mode t)

;; Quelques redefinitions de touches
(setq kill-whole-line t) ; Supprimer le EOL aussi
(global-set-key [delete]        'delete-char)             ; comportement normal de 'Suppr'
(global-set-key [(meta g)]      'goto-line)               ; aller M-CM-  la ligne ...
(global-set-key [(control tab)] 'other-window)            ; changer de fenetre
(global-set-key [f1]            'indent-region)           ; indent region automatique
(global-set-key [f2]            'comment-region)
(global-set-key [f3]            'uncomment-region)
;(global-set-key [f2]            'ispell-buffer)           ; ispell
;(global-set-key [f3]            'ispell-change-dictionary) ; changer de dictionnaire
;(global-set-key [f4]            'ispell-continue) ; changer de dictionnaire
(global-set-key [f5]            'revert-buffer)
(global-set-key [f6]            'flymd-flyit)

;; Text-mode par defaut
(setq default-major-mode 'text-mode)

;; Tabulations
(setq c-basic-offset 4) ; to set the mod-N indentation used when you hit the TAB key
(setq tab-width 4) ; To cause the TAB file-character to be interpreted as mod-N indentation
(setq-default indent-tabs-mode nil) ;use spaces instead of tabs
;(setq indent-line-function 'insert-tab)

(add-hook 'python-mode-hook
      (lambda ()
        (setq tab-width 4)
        (setq c-basic-offset 4)
        (setq python-indent 4)))

;; affichage de l'heure
(setq display-time-day-and-date t)
(setq display-time-24hr-format t)
;(display-time)

(defvar figlet-default-font "big"
  "Default font to use when none is supplied.")

(put 'scroll-left 'disabled nil)

(defalias 'yes-or-no-p 'y-or-n-p)
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))
;(setq make-backup-files nil)

; disable auto newline
(when (fboundp 'electric-indent-mode) (electric-indent-mode -1))
(setq verilog-auto-newline -1)
(setq electric-indent-mode -1)
(turn-off-auto-fill)
(remove-hook 'text-mode-hook 'turn-on-auto-fill)

(defun how-many-region (begin end regexp &optional interactive)
  "Print number of non-trivial matches for REGEXP in region.
Non-interactive arguments are Begin End Regexp"
  (interactive "r\nsHow many matches for (regexp): \np")
  (let ((count 0) opoint)
    (save-excursion
      (setq end (or end (point-max)))
      (goto-char (or begin (point)))
      (while (and (< (setq opoint (point)) end)
                  (re-search-forward regexp end t))
        (if (= opoint (point))
            (forward-char 1)
          (setq count (1+ count))))
      (if interactive (message "%d occurrences" count))
      count)))
(defun infer-indentation-style ()
  ;; if our source file uses tabs, we use tabs, if spaces spaces, and if
  ;; neither, we use the current indent-tabs-mode
  (let ((space-count (how-many-region (point-min) (point-max) "^  "))
        (tab-count (how-many-region (point-min) (point-max) "^\t")))
    (if (> space-count tab-count) (setq indent-tabs-mode nil))
    (if (> tab-count space-count) (setq indent-tabs-mode t))))


;;;======================================================================
;;; get rid of the default messages on startup
;;;======================================================================
(setq initial-scratch-message nil)
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message t)

(setq-default indent-tabs-mode nil)
(infer-indentation-style)
(setq stack-trace-on-error t)
(setq debug-on-error t)
(setq ecb-version-check nil)

(setq max-specpdl-size 9999)
(setq max-lisp-eval-depth 9999)

;;; unique: unique buffer name(guard duplication of buffer name);; usage:    auto(if (not (require 'uniquify nil t))    (message "[warn] feature 'uniquify' not found!")  (setq uniquify-buffer-name-style 'forward))  ;; unique*
(require 'uniquify) 
(setq 
  uniquify-buffer-name-style 'post-forward
  uniquify-separator ":")

;(add-to-list 'load-path
;            "C:/data/apps/emacs/share/emacs/24.5/lisp/cedet")
;(load-file "C:/data/apps/emacs/share/emacs/24.5/lisp/cedet/cedet.el")
;(add-to-list 'load-path
;            "C:/data/apps/emacs/share/emacs/24.5/lisp/ecb")
;(add-to-list 'load-path
;                "C:/data/apps/emacs/share/emacs/24.5/lisp/docker.el-master")
;(load-file "C:/data/apps/emacs/share/emacs/24.5/lisp/docker.el-master/docker.el")
;(add-to-list 'load-path
;"C:/jlu/.emacs.d/elpa/ecb-20140215.114")
(setenv "GIT_ASKPASS" "git-gui--askpass")

(require 'whitespace)
;; activate whitespace visu
(setq whitespace-style '(trailing tabs newline tab-mark newline-mark))
(autoload 'whitespace-mode           "whitespace" "Toggle whitespace visualization."        t)
(setq whitespace-display-mappings
  ;; all numbers are Unicode codepoint in decimal. ⁖ (insert-char 182 1)
  '(
    (space-mark 32 [183] [46]) ; 32 SPACE 「 」, 183 MIDDLE DOT 「·」, 46 FULL STOP 「.」
    ;(newline-mark 10 [182 10]) ; 10 LINE FEED
    (tab-mark 9 [9655 9] [92 9]) ; 9 TAB, 9655 WHITE RIGHT-POINTING TRIANGLE 「▷」
    ))
;; Draw tabs with the same color as trailing whitespace  
    (add-hook 'font-lock-mode-hook  
              (lambda ()  
                (font-lock-add-keywords  
                  nil  
                  '(("\t" 0 'trailing-whitespace prepend)))))
(global-whitespace-mode t)
