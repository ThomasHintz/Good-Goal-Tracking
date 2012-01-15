#!/usr/bin/csi -script

(use awful html-tags srfi-1 posix srfi-19 numbers)
(enable-ajax #t)
(debug-file "bug")

(define-syntax fold*
  (syntax-rules ()
    ((fold* proc s l)
     (letrec ((loop (lambda (rl o)
                      (if (eq? rl '())
                          o
                          (loop (cdr rl) (apply proc (append (car rl) (list o))))))))
       (loop l s)))))

(define-syntax folds*
  (syntax-rules ()
    ((folds* proc l)
     (letrec ((loop (lambda (rl o)
                      (if (eq? rl '())
                          o
                          (string-append o (loop (cdr rl) (apply proc (car rl))))))))
       (loop l "")))))

(define (dash->space s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\- c) " " (->string c)))) "" s))

(define (space->dash s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\space c) "-" (->string c)))) "" s))

(define (id->name id)
  (string-titlecase (dash->space id)))

(define (name->id name)
  (string-downcase (space->dash name)))

(define (date->db date)
  (date->string date "~D"))

(define (short-year? date-string)
  (let ((s (string-split date-string "/")))
    (if (> (length s) 2)
        (if (> (string-length (third s)) 2)
            #f
            #t)
        #f)))

(define (db->date db-date)
   (handle-exceptions
    exn
    #f
    (if (short-year? db-date)
        (string->date db-date "~m/~d/~y")
        (string->date db-date "~m/~d/~Y"))))

(define (days-since d1 d2)
  (inexact->exact (floor (/ (+ (time->seconds (date-difference d2 d1)) 0.0) 86400))))

(define (goal-date g)
  (cadr (with-input-from-file (++ "db/" g)
	  (lambda ()
	    (read)))))

(define (gen-goal-list)
  (fold (lambda (e o)
	  (++ o
	      (<br>)
	      (let* ((v (with-input-from-file (++ "db/" e)
			 (lambda ()
			   (read))))
		     (n (car v))
		     (d (cadr v)))
		(ajax (++ n "p") (++ "#" n "p") 'click
		      (lambda ()
			(with-output-to-file (++ "db/" e)
			  (lambda ()
			    (write `(,n ,(date->db (date-add-duration (db->date d) (make-duration days: 1)))))))
			(gen-goal-list))
		      live: #t
		      target: "goal-list")
		(ajax (++ n "m") (++ "#" n "m") 'click
		      (lambda ()
			(with-output-to-file (++ "db/" e)
			  (lambda ()
			    (write `(,n ,(date->db (date-subtract-duration (db->date d) (make-duration days: 1)))))))
			(gen-goal-list))
		      live: #t
		      target: "goal-list")
		(ajax (++ n "x") (++ "#" n "x") 'click
		      (lambda ()
			(delete-file (++ "db/" e))
			(gen-goal-list))
		      live: #t
		      target: "goal-list")
		(++ (<a> id: (++ n "p") href: "#self" "+") " " (<a> id: (++ n "m") href: "#self" "-")
		    " " (<a> id: (++ n "x") href: "#self" "X") " "
		    n " - " (number->string (days-since (current-date) (db->date d)))))))
	""
	(directory "db/")))

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







(define-page "/000"
  (lambda ()
    (ajax "update" 'save 'click
	  (lambda ()
	    (with-output-to-file "content"
	      (lambda ()
		(write ($ 'content)))))
	  arguments: '((content . "$('#content').val()"))
	  success: "$('#saved').show(); setTimeout(function () { $('#saved').fadeOut(); }, 1500);")
    (++ "<style type='text/css'>body { margin: 0px; padding: 0px; }</style>"
	(<textarea> id: "content" style: "width: 360px; height: 300px; font-size: 18px;"
		    (with-input-from-file "content" (lambda () (read))))
	(<br>)
	(<input> id: "save" type: "button" value: "save") (<span> id: "saved" "...saved...")))
  headers: (++ "<meta name='viewport' content='width=360,user-scalable=false' />"
	       "<script type='text/javascript'>$(document).ready(function () { $('#saved').hide(); });</script>"))