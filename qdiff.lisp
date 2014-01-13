;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; qdiff.lisp
;;   This project provides an easy way to determine the differences between
;;   a local copy of a library installed using QuickLisp and the canonical
;;   version as QuickLisp knows it.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (c) 2011 Hans Huebner, Jonathan Lee
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Change Log
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; 2011-09-27  Hans Huebner  Original version
;; 2011-10-01  Jonathan Lee  Added the ability to find diffs on a Windows box
;;                           and packaged it into a project
;; 2011-11-10  Jonathan Lee  Added the ability to generate unified diff files
;;                           for an individual project or all changed projects
;; 2014-01-12  Jonathan Lee  Added code to implement the option of not creating
;;                           diff files. Updated functions to handle changes in
;;                           the way external-program:run works.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; All installed systems can be checked at once using the QDIFF-ALL function.
;;
;; Usage:
;; (qdiff-all)
;;  or
;; (qdiff-all :verbose t)
;; or, to create unified diff files for each modified system
;; (qdiff-all :to-files t :verbose t)
;;
;; An individual package can be checked using the QDIFF method.
;;
;; Usage:
;; (qdiff "project-name")
;;  or
;; (qdiff "project-name" :diff-function 'diff)
;;  or
;; (qdiff "project-name" :diff-function 'diff :verbose t)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(in-package #:qdiff)

(defun string-replace-all (old new big)
  "Replace all occurences of OLD string with NEW string in BIG string."
  (do ((newlen (length new))
       (oldlen (length old))
       (i (search old big)
          (search old big :start2 (+ i newlen))))
      ((null i) big)
    (setq big
          (concatenate 'string
            (subseq big 0 i)
            new
            (subseq big (+ i oldlen))))))

(defun find-diff-executable ()
  "Locate the diff program on a Windows box, if one exists"
  (dolist (loop-values '((("diff") ("" ""))
                         (("/R" "c:\\Program Files" "diff") ("Program Files" "PROGRA~1"))
                         (("/R" "c:\\Program Files (x86)" "diff") ("Program Files (x86)" "PROGRA~2"))))
    (let* ((output (make-array '(0) :element-type 'character
                               :fill-pointer 0 :adjustable t))
           (path-args (first loop-values))
           (replace-args (second loop-values)))
      (with-output-to-string (*standard-output* output)
        (multiple-value-bind (exit-symbol exit-code)
            (external-program:run "where" path-args
                                  :output *standard-output* :error *standard-output*)
          (declare (ignore (exit-symbol)))
          (when (= 0 exit-code)
            (let ((diff-path (string-replace-all
                               (first replace-args)
                               (second replace-args)
                               (subseq output 0 (position #\Newline output :test #'char=)))))
              (when (position #\Space diff-path)
                (warn "~&The path to the diff application contains a space and will likely not~%~
                       work correctly. Please set the value of the qdiff:*DIFF-PATH* parameter to~%~
                       a valid, spaceless path to the diff executable.~%"))
              (return-from find-diff-executable diff-path)))))))
  (warn "~&You do not appear to have a diff application installed.  The installer for~%~
         one may be found at http://gnuwin32.sourceforge.net/packages/diffutils.htm~%~
         Please set the value of the qdiff:*DIFF-PATH* parameter to the path to the~%~
         diff executable.~% ")
  "")

(defparameter *diff-path* #-windows "diff" #+windows (find-diff-executable))

(defun diff (old-pathname new-pathname &key verbosep)
  (nth-value 1
             (external-program:run
               *diff-path*
               (list "-aurN"
                     (native-namestring (truename old-pathname))
                     (native-namestring (truename new-pathname)))
               :input nil :output (and verbosep *standard-output*)
               :error *standard-output*)))

(defun qdiff (project-name &key (diff-function 'diff) (verbosep t))
  "Write the differences between the local copy of a system and the canonical version
as QuickLisp knows it to the standard output."
  (let ((release (release project-name)))
    (unless release
      (error "Unknown project -- ~S" project-name))
    (let ((tarball (ensure-local-archive-file release))
          (tmpbase (qmerge "tmp/qdiff/"))
          (tmptree (qmerge (format nil "tmp/qdiff/~A/"
                                   (prefix release))))
          (tmptar (qmerge "tmp/qdiff/release.tar")))
      (ensure-directories-exist tmpbase)
      (gunzip tarball tmptar)
      (unpack-tarball tmptar :directory tmpbase)
      (prog1
        (funcall diff-function tmptree (base-directory release) :verbosep verbosep)
        (delete-directory-tree tmpbase)))))

(defun qdiff-to-file (project-name target-dir
                      &key (diff-function 'diff) (verbosep nil) (write-on-diff-only t))
  "Write the differences between the local copy of a system and the canonical version
as QuickLisp knows it to a unified diff file in the TARGET-DIR. Returns diff results
and filename."
  (let* ((datetime (nreverse (subseq (multiple-value-list
                                       (decode-universal-time
                                         (get-universal-time)))
                                     1 6)))
         (filename (make-pathname :name (format nil "~A_~{~2,'0D~}"
                                                project-name datetime)
                                  :type "diff" :defaults target-dir))
         (contents (make-array '(0) :element-type 'character
                               :fill-pointer 0 :adjustable t))
         results)
    (with-output-to-string (*standard-output* contents)
      (setf results (qdiff project-name :diff-function diff-function :verbosep t)))
    (when verbosep (princ contents))
    (let ((write-file (or (and write-on-diff-only (= results 1))
                          (not write-on-diff-only))))
      (when write-file
        (with-open-file (out filename :direction :output :element-type 'character)
          (write-sequence contents out)))
      (values results (and write-file (truename filename))))))

(defun qdiff-all (&key verbosep (to-files nil) (target-dir *default-pathname-defaults*))
  "Print a list of systems with local changes. When TO-FILES is T, generate a unified
diff file for each changed system in the TARGET-DIR directory."
  (dolist (system (ql-dist:installed-releases t))
    (if to-files
      (multiple-value-bind (result filename)
          (qdiff-to-file (name system) target-dir :verbosep verbosep :write-on-diff-only t)
        (when (= result 1)
          (format t "~&; ~A has local changes.~@[~%;   Generated diff file: ~A~]~%"
                  (name system) filename)))
      (let ((contents (make-array '(0) :element-type 'character
                                  :fill-pointer 0 :adjustable t))
            results)
        (with-output-to-string (*standard-output* contents)
          (setf results (qdiff (name system) :diff-function 'diff :verbosep t)))
        (when verbosep (princ contents))
        (when (= results 1)
          (format t "~&; ~A has local changes.~%"
                  (name system)))))))

;eof
