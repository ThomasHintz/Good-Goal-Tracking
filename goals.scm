#!/usr/bin/csi -script

(use awful html-tags)
(load "goals-common.scm")

(enable-ajax #t)
(debug-file "bug")

(define-page "/"
  (lambda ()
    (ajax "add" 'add 'click
	  (lambda ()
	    (with-output-to-file (++ "db/" (name->id ($ 'title)))
	      (lambda ()
		(write `(,($ 'title) ,(date->db (current-date))))))
	    (redirect-to "/"))
	  arguments: '((title . "$('#title').val()")))
    (++ (<div> id: "goal-list" (gen-goal-list))
	(<br>) (<br>)
        (<input> id: "title" type: "text") "&nbsp"
	(<button> type: "button" id: "add" "Add"))))

(awful-start (lambda () #t) dev-mode: #t port: 8084)