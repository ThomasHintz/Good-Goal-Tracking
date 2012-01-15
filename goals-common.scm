(use awful html-tags srfi-1 posix srfi-19 numbers)

(define ++ string-append)

(define (insert-file path)
  (with-input-from-file path (lambda () (read-string))))

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
  (inexact->exact (floor (/ (+ (time->seconds (date-difference d1 d2)) 0.0) 86400))))

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