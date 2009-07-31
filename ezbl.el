;;; ezbl.el --- Emacs interface for Uzbl (uzbl.org)
;;
;; Author: Daniel Hackney
;; Copyright (C) 2009 Daniel Hackney

;; This file is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3, or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
;; A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;; USA.

;;; Commentary:
;;
;;  Uzbl version 2009.07.18 or greater is required. It has not been tested with
;;  other versions.

(defgroup ezbl nil "Settings for Ezbl, the Emacs frontend for Uzbl.")

(defcustom ezbl-exec-path "/usr/bin/uzbl"
  "The location of the Uzbl executable."
  :group 'ezbl
  :type 'file)

(defvar ezbl-processes nil "A list of Uzbl processes")

(defvar ezbl-instance nil
  "A buffer-local variable storing the current Ezbl instance.

See `ezbl-start' for a description of the format of this
variable.")

(defconst ezbl-buffer-format "*ezbl-%s*"
  "The format used for transforming ezbl instance names into
buffer names.")

(defvar ezbl-commands
  '(((name . "set")
     (format . "set <key> = <value>")
     (doc . "Used for changing variables on the fly. Sets KEY
     equal to VALUE.

* the changes are effective immediately; for example, setting the
  variable uri will make uzbl start loading, and changing
  status_format will make the status bar react immediately

* if you want to unset a string, use `set' with one space as the
  value."))

    ((name . "print")
     (format . "print <key>")
     (doc . "Print the value of KEY.

If KEY contains a string of the form '@var', the value of the Uzl
variable 'var' is printed.

* use this to print the value of a variable."))
    ((name . "bind")
     (format . "bind <string> = <command>")
     (doc . "Sets the character sequence STRING to invoke COMMAND
     when typed interactively in Uzbl.

* there are a few tricks you can do:

  - STRING ends with an underscore: the command will only be
    invoked after pressing return/enter. If the user enters text
    where STRING has the underscore, %s in the COMMAND string
    will be replaced by this text. (optional)

  - STRING ends with an asterisk: similar behavior as with an
    underscore, but also makes the binding incremental (i.e. the
    command will be invoked on every keystroke).

  - STRING ends on a different character: you need to type the
    full string, which will trigger the command immediately,
    without pressing enter/return.

* examples:
  - bind o _ = uri %s
                + uzbl will load the url when you type: 'o '
  - bind /* = search %s

    + a search command which is called on every character typed
      after the slash, letting you see the search narrow down
      while typing.

    + Hitting return, enter or esc will terminate the search.

  - bind ZZ = exit

    + When you type ZZ and nothing else, the exit command will be
      triggered immediately."))
    ((name . "back")
     (format . "back")
     (doc . "Move backwards in the browser history."))
    ((name . "forward")
     (format . "forward")
     (doc . "Move forwards in the browser history."))
    ((name . "scroll_vert")
     (format . "scroll_vert <amount>")
     (doc . "Scroll vertically by AMOUNT.

AMOUNT is specified either in pixels, with a 'px' ending (55px)
or percentage (55%).

* amount is given in pixels(?) or as a percentage of the size of
  the view

* set amount to 100% to scroll a whole page."))
    ((name . "scroll_horz")
     (format . "scroll_horz <amount>")
     (doc . "Scroll horizontally by AMOUNT.

AMOUNT is specified either in pixels, with a 'px' ending (55px)
or percentage (55%).

* amount is given in pixels(?) or as a percentage of the size of
  the view

* set amount to 100% to scroll a whole page"))
    ((name . "scroll_begin")
     (format . "scroll_begin")
     (doc . "Scroll to the beginning of the page."))
    ((name . "scroll_end")
     (format . "scroll_end")
     (doc . "Scroll to the end of the page."))
    ((name . "reload")
     (format . "reload")
     (doc . "Reload the current page."))
    ((name . "reload_ign_cache")
     (format . "reload_ign_cache")
     (doc . "Reload the current page, clearing the cache."))
    ((name . "stop")
     (format . "stop")
     (doc . "Stop the currently loading page."))
    ((name . "zoom_in")
     (format . "zoom_in")
     (doc . "Increase the zoom level."))
    ((name . "zoom_out")
     (format . "zoom_out")
     (doc . "Decrease the zoom level."))
    ((name . "uri")
     (format . "uri <address>")
     (doc . "Visit the Uri ADDRESS"))
    ((name . "js")
     (format . "js <body>")
     (doc . "Execute JavaScript within the browser.

* execute the javascript in BODY.
* remember that the commands must not contain line breaks."))
    ((name . "script")
     (format . "script <file>")
     (doc . "execute the JavaScript in FILE."))
    ((name . "toggle_status")
     (format . "toggle_status")
     (doc . ""))
    ((name . "spawn")
     (format . "spawn <executable> <additonal args>")
     (doc . "Runs a command.

* See the \"external scripts\" section of the Uzbl readme for
  details.

* PATH is searched so giving the full path to commands is not
  necessary.

* note that the arguments as specified in \"external scripts\"
  are appended at the end, so the argument numbers will be
  higher."))
    ((name . "sh")
     (format . "sh <command>")
     (doc . "Run a shell command.

* runs a shell command by expanding %s in the shell_cmd variable
  with the specified command; primarily useful as a shortcut for
  \"spawn sh -c BODY\"

* note that the arguments as specified in \"external scripts\"
  are appended at the end, so the argument numbers will be
  higher."))
    ((name . "sync_spawn")
     (format . "sync_spawn <executable> <additional args>")
     (doc . "Tell Uzbl to synchronously spawn a command.

See `ezbl-command-spawn' for details.

* these are synchronous variants of spawn and sh, which means
  uzbl will wait for them to return.

* you should only need to use these manually if you want to use a
  chain command in a handler that wants output from the command
  it runs"))
    ((name . "sync_sh")
     (format . "sync_sh <command>")
     (doc . "Tell Uzbl to synchronously run a shell command.

See `ezbl-command-sh' for details.

* these are synchronous variants of spawn and sh, which means
  uzbl will wait for them to return.

* you should only need to use these manually if you want to use a
  chain command in a handler that wants output from the command
  it runs"))
    ((name . "exit")
     (format . "exit")
     (doc . "Close this instance of Uzbl."))
    ((name . "search")
     (format . "search <string>")
     (doc . "Search for STRING within the content of the current
     Uzbl page.

* search with no string will search for the next/previous
  occurrence of the string previously searched for."))
    ((name . "search_reverse")
     (format . "search_reverse <string>")
     (doc . "Search backwards for STRING in the current page.

* search with no string will search for the next/previous
  occurrence of the string previously searched for."))
    ((name . "toggle_insert_mode")
     (format . "toggle_insert_mode <optional state>")
     (doc . "Set the insert mode to OPTIONAL_STATE.

If the optional state is 0, disable insert mode. If 1, enable
insert mode."))
    ((name . "dump_config")
     (format . "dump_config")
     (doc . "Dump the current Uzbl configuration.

* dumps your current config (which may have been changed at
  runtime) to stdout, in a format you can use to pipe into uzbl
  again (or use as config file)"))
    ((name . "keycmd")
     (format . "keycmd <string>")
     (doc . "Set the interactive command buffer to STRING.

If STRING is a valid binding, it will execute."))
    ((name . "keycmd_nl")
     (format . "keycmd_nl <string>")
     (doc . "Set the interactive command buffer to STRING and emulate pressing return.

See `ezbl-command-keycmd'.

`ezbl-command-keycmd_nl' is like `ezbl-command-keycmd', but it
also emulates a press of return, causing bindings with a
parameter to execute. For example, keycmd_nl o google.com would
load the said url if you have a binding like \"bind o _ = uri %s\"."))
    ((name . "keycmd_bs")
     (format . "keycmd_bs")
     (doc . "Erase (backspace) one character from the command buffer."))
    ((name . "chain")
     (format . "chain <command> <command>")
     (doc . "Use for chaining multiple commands.

* remember to quote the commands; one command must come as one
  parameter.

* If you use chain with a handler script which must return some
  output (such as a cookie handler -- uzbl will wait for and use
  its output), use 'sync_spawn' or 'sync_sh' instead of 'spawn'
  or 'sh' in the command that should give the output.")))
  "A list of commands which Uzbl accepts. These are used to
generate the functions to call each command.

The following attributes can be used in each alist:

- name (mandatory)

  The name of the command. This is the string that is passed to
  Uzbl when invoking the command.

- format (mandatory)

  The format of the command, for example

    scroll_vert <amount>

  All variables must be enclosed in angle brackets.")

(defun ezbl-get-command-args (command)
  "Extracts the arguments (as symbols) from a Uzbl command specification.

For example, the spec

  scroll_vert <amount>

Would return (amount)."
  (let ((start 0)
        (args nil))
    (while (string-match "<\\([[:alnum:]_-]+\\)>" command start)
      (setq args (append (list (intern (match-string 1 command))) args))
      (setq start (match-end 1)))
    args))

(defun ezbl-make-command-func (spec)
  "Creates a function which produces the Uzbl command string described by SPEC.

The function created takes a number of arguments specified by the
`format' attribute of SPEC and returns a string suitable for
`ezbl-exec-command'.

See `ezbl-commands' for a description of the format of SPEC."
  (let* ((name (cdr (assq 'name spec)))
         (format (cdr (assq 'format spec)))
         (args (ezbl-get-command-args format))
         (doc (cdr (assq 'doc spec)))
         (output-format (replace-regexp-in-string "<[[:alnum:]_-]+>" "%s" format))
         (command-name (intern (concat "ezbl-command-" name))))
    (fset command-name
          `(lambda (instance ,@args)
             ,doc
             (ezbl-exec-command instance (format ,output-format ,@args))))
    command-name))

(defun ezbl-init-commands ()
  "Create Emacs functions from `ezbl-commands'.

Read through `ezbl-commands' and call `ezbl-make-command-func' on
each one."
  (interactive)
  (mapcar 'ezbl-make-command-func ezbl-commands))

(defun ezbl-start (name &rest args)
  "Start an instance of Uzbl. ARGS is a keyword list of
options and values to pass to the Uzbl instance.

NAME is the base from which to form the process and buffer
names. If NAME is '1234', then the process 'uzbl-1234' and buffer
'*uzbl-1234*' would be created.

The following keywords are used:

:class VALUE
        Program class as used by the window manager
:gtk-name NAME
        Program name as used by the window manager
:screen SCREEN
        X screen to use
:sync nil
        Make X calls synchronous. Must include `nil' as the argument.
:gtk-module MODULES
        Load additional GTK+ modules. MODULES should be a list of
        string names of modules.
:g-fatal-warnings nil
        Make all warnings fatal. Must include `nil' as the argument.
:uri URI
        Uri to load at startup (equivalent to 'set uri = URI')
:verbose nil
        Whether to print all messages or just errors. Must
        include `nil' as the argument.
:name NAME
          Name of the current instance (defaults to Xorg window id)
:config FILE
        Config file (this is pretty much equivalent to 'uzbl < FILE' )
:socket SOCKET
        Socket ID for GtkSocket.
:display DISPLAY
        X display to use

Returns an ezbl instance alist of the form:

  ((arguments . (\"--option1\" \"value\" \"--switch\"))
   (process . #<process ezbl-name>)
   (name . NAME)
   (buffer . \"*ezbl-name*\")
   (proc-name . \"ezbl-name\"))

This 'ezbl instance' is used in various other functions.
"
  (let ((program-args nil)
        (instance `((name . ,name)
                    (buffer . ,(format ezbl-buffer-format name))
                    (proc-name . ,(concat "ezbl-" name)))))
    ;; Process keywords
    (while args
      (let ((arg (car args)))
        (setq args (cdr args))
        (unless (symbolp arg)
          (error "Junk in args %S" args))
        (let ((keyword arg)
              (value (car args)))
          (unless args
            (error "Keyword %s is missing an argument" keyword))
          (setq args (cdr args))
          (cond
           ((eq keyword :class)
            (setq program-args (append program-args (list "--class") (list value))))
           ((eq keyword :gtk-name)
            (setq program-args (append program-args (list "--gtk-name") (list value))))
           ((eq keyword :screen)
            (setq program-args (append program-args (list "--screen") (list value))))
           ((eq keyword :sync)
            (setq program-args (append program-args (list "--sync"))))
           ((eq keyword :gtk-module)
            (setq program-args (append program-args (list "--gtk-module")
                                       (list (mapconcat 'identity value ",")))))
           ((eq keyword :g-fatal-warnings)
            (setq program-args (append program-args (list "--g-fatal-warnings "))))
           ((eq keyword :uri)
            (setq program-args (append program-args (list "--uri") (list value))))
           ((eq keyword :verbose)
            (setq program-args (append program-args (list "--verbose"))))
           ((eq keyword :name)
            (setq program-args (append program-args (list "--name") (list value))))
           ((eq keyword :config)
            (setq program-args (append program-args (list "--config") (list value))))
           ((eq keyword :socket)
            (setq program-args (append program-args (list "--socket") (list value))))
           ((eq keyword :display)
            (setq program-args (append program-args (list "--display") (list value))))))))

    ;; Start process
    (let* ((proc-name (cdr (assq 'proc-name instance)))
           (buffer-name (cdr (assq 'buffer instance)))
           (proc (apply 'start-process
                        (append (list proc-name
                                      buffer-name
                                      ezbl-exec-path)
                                program-args))))
      (setq instance (append `((arguments . ,program-args)
                               (process . ,proc))
                             instance))
      (with-current-buffer buffer-name
        (set (make-local-variable 'ezbl-instance) instance)))))

(defun ezbl-get-instance (instance-or-buffer)
  "Returns the ezbl instance from INSTANCE-OR-BUFFER.

If INSTANCE-OR-BUFFER is an ezbl instance, then it is returned
unchanged. If it is a buffer, then the local variable of
`ezbl-instance' is returned.

Returns an ezbl instance, or `nil' if none was found."
  (let ((instance
         (cond
          ;; Is an instance.
          ((listp instance-or-buffer)
           instance-or-buffer)
          ;; Is a buffer.
          ((bufferp instance-or-buffer)
           (with-current-buffer instance-or-buffer
             ezbl-instance))
          ;; Is the name of a buffer.
          ((stringp instance-or-buffer)
           (if (and (bufferp (get-buffer instance-or-buffer))
                    (not (null (with-current-buffer instance-or-buffer
                                 ezbl-instance))))
               (with-current-buffer instance-or-buffer
                 ezbl-instance)
             ;; Is the name of an instance, so open the buffer named "*ezbl-name*"
             (with-current-buffer (format ezbl-buffer-format instance-or-buffer)
               ezbl-instance))))))
    (when (null instance)
      (error (concat instance-or-buffer " is not an Ezbl instance or an Ezbl buffer.")))
    instance))

(defun ezbl-exec-command (instance-or-buffer command)
  "Sends the string COMMAND to the Uzbl instance INSTANCE-OR-BUFFER.

If INSTANCE-OR-BUFFER is a buffer, use the value of
`ezbl-instance' in that buffer. If

COMMAND is a Uzbl command as described by the Uzbl
readme (http://www.uzbl.org/readme.php).

See `ezbl-start' for a description of the format of INSTANCE."
  (let ((instance (ezbl-get-instance instance-or-buffer)))


    ;; Append a newline (\n) to the end of COMMAND if one is not already there.
    (when (not (string= "\n" (substring command -1)))
      (setq command (concat command "\n")))
    (process-send-string (cdr (assq 'process instance)) command)))

(defun ezbl-get-variable (instance-or-buffer var)
  "Return the value of VAR from the ezbl instance INSTANCE-OR-BUFFER."
  (let ((instance (ezbl-get-instance instance-or-buffer))
        (tag (sha1 (int-to-string (random)))))
    (with-current-buffer (cdr (assq 'buffer instance))
      (ezbl-command-print instance
                          (format "ezbl-tag(%s){@%s}" tag var))
      (goto-char (point-max))
      ;; Keep trying until tag is found. TODO: avoid searching backwards through
      ;; the whole buffer.
      (while (not (re-search-backward (format "ezbl-tag(%s){\\(.*\\)}" tag) (point-min) t))
        (goto-char (point-max))
        ;; Sleep for 1 millisecond
        (sleep-for 0 1))
      (match-string 1))))

;;; ezbl.el ends here
