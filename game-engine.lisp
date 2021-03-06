(require 'pal)

(defpackage :text-destroyer
  (:use :cl :pal))

(in-package :text-destroyer)

(defparameter buttonvalue nil)
(defparameter filenametext nil)

(define-tags avatar-1 (load-image  #P"/home/keith/lispspace/text-destroyer/avatar-1.png")
	     imgt1    (load-image  #P"/home/keith/lispspace/text-destroyer/projectile-1.png")
	     imgt2    (load-image  #P"/home/keith/lispspace/text-destroyer/projectile-2.png")
	     imgt3    (load-image  #P"/home/keith/lispspace/text-destroyer/projectile-3.png")
	     imgt4    (load-image  #P"/home/keith/lispspace/text-destroyer/projectile-4.png")
	     splash   (load-image  #P"/home/keith/lispspace/text-destroyer/stringemup.png")
	     gdwk     (load-image  #P"/home/keith/lispspace/text-destroyer/goodwork.png")
	     olay     (load-image  #P"/home/keith/lispspace/text-destroyer/goodwork-olay.png")
	     intromus (load-music  #P"/home/keith/lispspace/text-destroyer/stringemintro.wav")
	     outromus (load-music  #P"/home/keith/lispspace/text-destroyer/stringemoutro.wav")
	     lasersam (load-sample #P"/home/keith/lispspace/text-destroyer/stringemlaser.wav"))

(defclass automove-object ()
  ((x-vel :initarg :x-vel :initform 0 :accessor x-vel)
   (y-vel :initarg :y-vel :initform 0 :accessor y-vel)))

(defclass projectile ( sprite automove-object )
  ((fcount :initform 0 :accessor fcount)
   (imgt1 :initform 'imgt1 :accessor imgt1)
   (imgt2 :initform 'imgt2 :accessor imgt2)
   (imgt3 :initform 'imgt3 :accessor imgt3)
   (imgt4 :initform 'imgt4 :accessor imgt4)))

(defclass sprite ()
  ((x-pos :initarg :x :initform 0 :accessor x)
   (y-pos :initarg :y :initform 0 :accessor y)))

(defclass text-sprite ( sprite )
  ((text :initarg :text :initform "" :accessor text)))

(defclass word-sprite (text-sprite automove-object)
  ((counter :initarg counter :initform 0 :accessor counter)))

(defclass image-sprite ( sprite )
  ((pos :initarg :pos :initform (v 0 0) :accessor pos)
   (imaget :initarg :imaget :initform nil :accessor imaget)
   (scale :initarg :scale :initform 1 :accessor scal)))

(defmethod text ((pr projectile))
  (format t "Projectile acting as text!!!"))

(defgeneric draw ( sprite ))

(defmethod draw ((spr text-sprite))
  (with-transformation (:scale 3f0)
    (draw-text (text spr) (v (x spr) (y spr)))))

(defmethod draw :before ((spr word-sprite))
  (incf (y spr) (* (/ (get-fps)) (y-vel spr)))
  (if (< (y spr) -10) (setf (counter spr) -1  )))

(defmethod draw :after ((spr word-sprite))
  (if (minusp (counter spr)) (progn (setf +spritelist+ (remove spr +spritelist+)) (setf +collidableobjects+ (remove spr +collidableobjects+))(setf +wordspritelist+ (remove spr +wordspritelist+))))
  (if (> (counter spr) 3) (setf (text spr) (string-upcase (text spr))) (setf (text spr) (string-downcase (text spr)))))

(defmethod draw ((spr image-sprite))
  (draw-image (tag (imaget spr)) (pos spr) :scale (scal spr) :valign :middle :halign :middle))

(defmethod draw ((spr projectile))
  (incf (fcount spr))
  (collision?)
  (incf (y spr) (* (/ (get-fps) )(y-vel spr)))
  (draw-image (tag (if (> (fcount spr) 20) (imgt4 spr) (if (> (fcount spr) 10) (imgt3 spr) (if (> (fcount spr) 5) (imgt2 spr) (imgt1 spr)))))
	      (v (x spr) (y spr)) :scale 2f0)
  (if (> (y spr) (get-screen-height)) (remove-projectile spr)))

(defun remove-projectile ( spr )
  (setf +projectilelist+ (remove spr +projectilelist+)) 
  (setf +spritelist+ (remove spr +spritelist+)))

(defparameter +wordspritesbyphrase+ nil)
(defparameter +collidableobjects+ nil)
(defparameter +wordspritelist+ nil)

(defun populate-wordsprites (textlist)
  (mapcar #'(lambda ( text )
	      (let ((by-word (break-into-sentences text " "))
		    (this-phrase nil))
		(format t "Processing ~s...~%" by-word)
		(mapcar #'(lambda ( te )
			    (let ((temp (make-instance 'word-sprite :text (string-upcase te) :x 0 :y-vel -20 :y (+ (get-screen-height) -5))))
			      (if (find 65279 (map 'list #'char-code (text temp))) (setf temp (make-instance 'word-sprite :text "" :y-vel -20))) 
			      (if (find 8217  (map 'list #'char-code (text temp))) (setf temp (make-instance 'word-sprite :text "" :y-vel -20)))
			      (push temp +spritelist+)
			      (push temp +collidableobjects+)
			      (push temp +wordspritelist+)
			      (push temp this-phrase))) by-word)
		(push this-phrase +wordspritesbyphrase+))) textlist))

(defun collision? ()
  (loop for proj in +projectilelist+ doing
       (loop for obj in +collidableobjects+ doing
	    (let*((yobjs  (* (y obj)  3))
		  (yprojs (* (y proj) 1))
		  (xobjs  (* (x obj)  3))
		  (xprojs (* (x proj) 1))
		  (bool1 (< yobjs yprojs))
		  (bool2 (< yprojs (+ (* (get-font-height) 3) yobjs)))
		  (bool3 (< xobjs xprojs))
		  (bool4 (< xprojs (+ (* (get-text-size (text obj)) 3) xobjs))))
	      (if (and bool1 bool2 bool3 bool4) (collide proj obj) nil)))))	     

(defun collide ( proj obj )
  (decf (counter obj))
  (add-points (- 10 (length (text obj))))
  (remove-projectile proj))

(defun choose-file ()
  (let ((etr-box   nil))
    (ltk:with-ltk ()
      (let* ((top-label (make-instance 'ltk:label
				      :text "Choose a file:"
				      ))
	    
	    (ok-bttn   (make-instance 'ltk:button
				      :text "Ok"
				      :command (lambda ()
						 (setf buttonvalue t)
						 (setf filenametext (ltk:text etr-box))
						 (setf ltk:*exit-mainloop* t))))
	    (cncl-bttn (make-instance 'ltk:button
				      :text "Cancel"
				      :command (lambda ()
						 (setf buttonvalue nil)
						 (setf filenametext nil)
						 (setf ltk:*exit-mainloop* t)))))
	(setf etr-box (make-instance 'ltk:entry))
	(ltk:pack top-label)
	(ltk:pack etr-box)
	(ltk:pack ok-bttn :side :right)
	(ltk:pack cncl-bttn :side :left))))
        filenametext)

(defparameter +score+ 0)

(defun add-points ( no )
  (incf +score+ no))


(defun align-wordsprites (  )
  (setf alignonce nil)
  (let*
      ((space-width  (* (get-text-size " ") 1))
       (em-width     (* (get-text-size "M") 1))
       (screen-width    (get-screen-width ))
       (max-width (/ (- screen-width em-width em-width) 3))
       (text-height  (* (get-font-height) 1))
       (y-line (+ (/ (get-screen-height) 3)))
       (x-line em-width)
       (delta-y (* text-height 1.1)))
    (loop for s in (nreverse +wordspritelist+) doing
	 (if (find 65279 (map 'list #'char-code (text s))) (setf s (make-instance 'word-sprite :text ""))) 
	 (if (find 8217  (map 'list #'char-code (text s))) (setf s (make-instance 'word-sprite :text "")))
	
	 (if (> (+ (get-text-size (text s)) x-line) max-width)
	     (progn
	       (setf x-line em-width)
	       (incf y-line delta-y)))
	 (format t "Aligning word ~s at line ~s and column ~s ~%" (text s) y-line x-line)
	 (setf (y s) y-line)
	 (setf (x s) x-line)
	 (incf x-line (+ (get-text-size (text s)) space-width)))))

(defparameter +spritelist+ nil)
(defparameter +projectilelist+ nil)

(defparameter +gun+ (make-instance 'image-sprite :imaget 'avatar-1 :pos (v 100 75) :x 100 :y 75 :scale 4f0))
(push +gun+ +spritelist+)


(defun fire! ( x y )
  (play-sample (tag 'lasersam) :volume 75)
  (let ((newp (make-instance 'projectile :x x :y y :y-vel 750)))
    (push newp +spritelist+)
    (push newp +projectilelist+)))


(defparameter +exit-requested+ nil)
(defun request-exit ()
  (setf +exit-requested+ t))

(defparameter mousex 100)
(defparameter mousey 75)

(defun handle-mouse-motion (x y)
  (setf (pos +gun+) (v x 75))
  (setf (x +gun+) x (y +gun+) 75)
  (setf mousex x)
  (setf mousey y))

(defparameter keyvelocity 0)

(defun handle-key-down ( keysym )
  (if (eql keysym :key-mouse-1) (fire! mousex 100))
  (if (eql keysym :key-up) (fire! (x +gun+) 100))
  (if (eql keysym :key-left) (setf keyvelocity -10))
  (if (eql keysym :key-right) (setf keyvelocity 10))
  (if (eql keysym :key-space) (fire! (x +gun+) 75)))


(defun handle-key-up ( keysym ) 
  (if (eql keysym :key-escape) (request-exit) )
  (if (eql keysym :key-left) (setf keyvelocity 0))
  (if (eql keysym :key-right) (setf keyvelocity 0))
  (if (key-pressed-p :key-left) (setf keyvelocity -10))
  (if (key-pressed-p :key-right) (setf keyvelocity 10)))

(defparameter selected 0)
(defparameter alignonce t)

(defun handle-menu-key-down (keysym) 
  (if (equal keysym :key-up) (decf selected))
  (if (equal keysym :key-down) (incf selected)))

(defun handle-menu-key-up (keysym) 
  (if (equal keysym :key-return) (setf +exit-requested+ t)))

(defun draw-menu (paths selected)
  
 (with-transformation (:scale 3f0)
   (let ((y (get-font-height)) (i 0))
    (draw-text "Please choose a .txt file and hit Return:" (v 0 0))
     (loop for p in paths doing
	  (if (equal i selected) (draw-rectangle (v 0 y) (get-screen-width) (get-font-height) 255 0 0 128 :fill t))
	  (draw-text (concatenate 'string (pathname-name p) ".txt") (v 0 y))
	  (incf i)
	  (incf y (get-font-height))))))


(defun run (&optional (fulls nil))
  (setf alignonce t)
  (setf +score+ 0)
  (let ((fname ""))
    (if (equalp fname "") 
	(progn
	  
	; (format t "Processing finished successfully~%")
	  (with-pal (:title "The Text Destroyer" :fullscreenp fulls)
	;     (format t "Window created successfully~%")
	   
	    (play-music (tag 'intromus) :volume 100 )
	    (draw-image (tag 'splash) (v 0 0) :scale 5)
	    (set-blend-color (color 255 0 0))
	    (with-transformation (:scale 3f0)
	      (draw-text "Press any key to Begin" (v 10 175)))
	    (set-blend-color (color 255 255 255))
	    (update-screen)
	    (wait-keypress)
	    
	    (event-loop (:key-up-fn #'handle-menu-key-up :key-down-fn #'handle-menu-key-down)
	      (clear-screen (color 33 33 33))
	      (let ((files (directory "*.txt")))
		(if (< selected 0) (setf selected 0))
		(if (>= selected (length files)) (setf selected (1- (length files))))
		(draw-menu files selected)
		(setf fname (nth selected files)))
		
	      (if +exit-requested+ (return-from event-loop))
	      )
	   
	    (populate-wordsprites (parse-txt-file fname))
	    (halt-music)
	    (setf +exit-requested+ nil)
	    (event-loop (:key-up-fn #'handle-key-up :key-down-fn #'handle-key-down :mouse-motion-fn #'handle-mouse-motion)
	;	(format t "Event loop begun~%")
	      (if +exit-requested+ (return-from event-loop))
	;	(format t "Exit request checked.~%")
	      (clear-screen (color 66 66 66))
	;	(format t "Screen cleared~%")
	      (if alignonce (align-wordsprites))
	;	(format t "Wordsprites aligned.~%")
	      (let ((newx (incf (x +gun+) keyvelocity))
		    (screen-width (get-screen-width)))
		(if (< newx 0) (setf newx 0))
		(if (< screen-width newx) (setf newx screen-width))
		(setf (x +gun+) newx)
		(setf (pos +gun+) (v newx (y +gun+)))
		)
	      (draw-fps)
        ;	(format t "The font height is ~s and the width of \"This width\" is ~s." (get-font-height) (get-text-size "This width")) 
	      (loop for spr in +spritelist+ doing (draw spr))
	      (set-blend-color (color 255 30 20))
	      (with-transformation (:scale 3f0 )
		(draw-text (format nil "Score: ~s"  +score+) (v 200 -2)))
	      (set-blend-color (color 255 255 255))
	      (if (null +collidableobjects+) (return-from event-loop)))
	    (let ((sr 0.05))
	      (play-music (tag 'outromus) :volume 100 )
	      (event-loop ( :key-up-fn #'(lambda ( s ) (return-from event-loop)))
		
		(draw-image (tag 'gdwk) (v 0 0) :scale sr)
		
		(incf sr (* (/ (get-fps)) 2))
		(if (> sr 5) (return-from event-loop))))
	    (draw-image (tag 'olay) (v 0 0) :scale 5)
	    (with-transformation (:scale 3f0)
	      (draw-text "Press any key to Exit" (v 10 175)))
	    (wait-keypress)
	    (halt-music)
	    )))))


(defun run-as-fullscreen ()
  (run t))