;;;; qdiff.asd

(asdf:defsystem #:qdiff
  :serial t
  :depends-on (#:quicklisp
               #:external-program
               #:asdf)
  :components ((:file "package")
               (:file "qdiff")))

