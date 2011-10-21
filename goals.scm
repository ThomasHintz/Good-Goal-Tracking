#!/usr/bin/csi -script

(use awful html-tags)
(enable-ajax #t)

(define-page "/"
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

(awful-start (lambda () #t) dev-mode: #t port: 8084)