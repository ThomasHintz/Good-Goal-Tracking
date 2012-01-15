(use send-grid)

(load "goals-common.scm")
(api-user (insert-file "send-grid-user"))
(api-key (insert-file "send-grid-key"))

(send-mail subject: "Goal Progress" html: (gen-goal-list) from: "goals@thintz.com" to: "t@thintz.com" from-name: "Goal Mailer" reply-to: "goals@thintz.com")