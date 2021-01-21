;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; .........
; .WWW.WDW.
; .W.WkW.W.
; .W.WWW.W.
; .W.WGW.W.
; .W.W.W.W.
; .W.....W.
; .WWWgWWW.
; ..sWWWg..
(define (problem doors-keys-gems-4)
  (:domain doors-keys-gems)
  (:objects
    up down left right - direction
    key1 - key
    gem1 gem2 gem3 - gem)
  (:init (= (xdiff up) 0) (= (ydiff up) 1)
         (= (xdiff down) 0) (= (ydiff down) -1)
         (= (xdiff right) 1) (= (ydiff right) 0)
         (= (xdiff left) -1) (= (ydiff left) 0)
         (= (width) 9) (= (height) 9) (= (xpos) 3) (= (ypos) 1)
         (wall 4 1)
         (wall 5 1)
         (wall 6 1)
         (at gem1 7 1)
         (itemloc 7 1)
         (wall 2 2)
         (wall 3 2)
         (wall 4 2)
         (at gem2 5 2)
         (itemloc 5 2)
         (wall 6 2)
         (wall 7 2)
         (wall 8 2)
         (wall 2 3)
         (wall 8 3)
         (wall 2 4)
         (wall 4 4)
         (wall 6 4)
         (wall 8 4)
         (wall 2 5)
         (wall 4 5)
         (at gem3 5 5)
         (itemloc 5 5)
         (wall 6 5)
         (wall 8 5)
         (wall 2 6)
         (wall 4 6)
         (wall 5 6)
         (wall 6 6)
         (wall 8 6)
         (wall 2 7)
         (wall 4 7)
         (at key1 5 7)
         (itemloc 5 7)
         (wall 6 7)
         (wall 8 7)
         (wall 2 8)
         (wall 3 8)
         (wall 4 8)
         (wall 6 8)
         (door 7 8)
         (doorloc 7 8)
         (wall 8 8))
  (:goal (has gem3))
)
