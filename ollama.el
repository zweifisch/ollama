;;; ollama.el --- ollama client for Emacs

;; Copyright (C) 2023 ZHOU Feng

;; Author: ZHOU Feng <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/ollama
;; Keywords: ollama llama2
;; Version: 0.0.1
;; Created: 6th Aug 2023

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; ollama client for Emacs
;;

;;; Code:
(require 'json)
(require 'cl-lib)
(require 'url)

(defgroup ollama nil
  "Ollama client for Emacs."
  :group 'ollama)

(defcustom ollama:endpoint "http://localhost:11434/api/generate"
  "Ollama http service endpoint."
  :group 'ollama
  :type 'string)

(defcustom ollama:model "llama2-uncensored"
  "Ollama model."
  :group 'ollama
  :type 'string)

(defun ollama-fetch (url prompt model)
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/json")))
         (url-request-data
          (encode-coding-string
           (json-encode `((model . ,model) (prompt . ,prompt)))
           'utf-8)))
    (with-current-buffer (url-retrieve-synchronously url)
      (goto-char url-http-end-of-headers)
      (decode-coding-string
       (buffer-substring-no-properties
        (point)
        (point-max))
       'utf-8))))

(defun ollama-get-response-from-line (line)
  (cdr
   (assoc 'response
          (json-read-from-string line))))

(defun ollama-prompt (url prompt model)
  (mapconcat 'ollama-get-response-from-line
             (cl-remove-if #'(lambda (str) (string= str "")) 
                        (split-string (ollama-fetch url prompt model) "\n")) ""))

;;;###autoload
(defun ollama-prompt-line ()
  "Prompt with current word."
  (interactive)
  (with-output-to-temp-buffer "*ollama*"
    (princ
     (ollama-prompt ollama:endpoint (thing-at-point 'line) ollama:model))))

;;;###autoload
(defun ollama-define-word ()
  "Find definition of current word."
  (interactive)
  (with-output-to-temp-buffer "*ollama*"
    (princ
     (ollama-prompt ollama:endpoint (format "define %s" (thing-at-point 'word)) ollama:model))))

;;;###autoload
(defun ollama-summarize-region ()
  "Summarize marked text."
  (interactive)
  (with-output-to-temp-buffer "*ollama*"
    (princ
     (ollama-prompt ollama:endpoint (format "summarize \"\"\"%s\"\"\"" (buffer-substring (region-beginning) (region-end))) ollama:model))))

(provide 'ollama)
;;; ollama.el ends here
