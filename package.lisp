;;;; package.lisp

(defpackage #:qdiff
  (:use #:cl)
  (:shadowing-import-from #:ql-dist
                          #:name
                          #:release
                          #:ensure-local-archive-file
                          #:base-directory
                          #:prefix)
  (:shadowing-import-from #:ql-setup
                          #:qmerge)
  (:shadowing-import-from #:ql-gunzipper
                          #:gunzip)
  (:shadowing-import-from #:ql-minitar
                          #:unpack-tarball)
  (:shadowing-import-from #:ql-impl-util
                          #:delete-directory-tree
                          #:native-namestring)
  (:shadowing-import-from #:asdf
                          #:*verbose-out*
                          #:run-shell-command)
  (:export #:qdiff
           #:qdiff-to-file
           #:qdiff-all
           #:*diff-path*))

