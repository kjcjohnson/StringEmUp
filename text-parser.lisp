;;;This system parses text files into paragraphs and sentences

(defpackage :text-destroyer
  (:use :cl :pal))

(in-package :text-destroyer)

(defun read-txt-file (file)
  (let ((text nil))
    (with-open-file (file-stream file :direction :input)
      (labels ((read-line-and-push (instream)
	       (let ((vals (multiple-value-list (read-line instream nil t t))))
		 
		 (if (cadr vals) nil (progn (push (car vals) text) (read-line-and-push instream))))))
	(read-line-and-push file-stream)))
    (apply #'concatenate 'string (nreverse text))))

(defun break-into-sentences (text chr)
  (let* ((indices (find-all-chars text chr))
	 (first1 (cons -1 indices))
	 (last1  (append indices ())))
    (loop for i from 0 to (length indices) collecting
	 (string-trim " " (subseq text (1+ (nth i first1)) (if (null (nth i last1)) nil (1+ (nth i last1))))))))

(defun find-all-chars (text chr)
  (let ((char-rep nil))
    (loop for i from 0 to (1- (length text)) doing
	 (if (string= chr (char text i)) (push i char-rep) nil)
	 (if (string= #\; (char text i)) (push i char-rep) nil))
    (reverse char-rep)))
  
(defun parse-txt-file (path)
  (if (null path) nil 
      (if (probe-file path) (break-into-sentences (read-txt-file path) #\.)  nil)))

