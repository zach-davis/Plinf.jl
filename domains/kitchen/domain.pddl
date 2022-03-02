; added cook as a function
(define (domain kitchen)
    (:requirements :fluents :adl :typing)
    (:types key gem - item direction)
    (:predicates (wall ?x ?y) (door ?x ?y) (stove ?x ?y) (obstacle ?x ?y)
                 (at ?o - item ?x ?y) (has ?o - item) (cooked ?o - item)
                 (itemloc ?x ?y) (doorloc ?x ?y) (stoveloc ?x ?y))
    (:derived (obstacle ?x ?y) (or (wall ?x ?y) (door ?x ?y) (stove ?x ?y)))
    (:functions (xpos) (ypos) (width) (height)
                (xdiff ?d - direction) (ydiff ?d - direction))
    (:action pickup
     :parameters (?i - item)
     :precondition (at ?i xpos ypos)
     :effect (and (not (at ?i xpos ypos)) (has ?i))
    )
    (:action unlock
     :parameters (?k - key ?dir - direction)
     :precondition (and (has ?k)
                        (door (+ xpos (xdiff ?dir)) (+ ypos (ydiff ?dir))))
     :effect (and (not (has ?k))
                  (not (door (+ xpos (xdiff ?dir)) (+ ypos (ydiff ?dir)))))
    )
    ; if the agent has a gem and puts it on the stove, the gem is cooked
    (:action cook
     :parameters (?g - gem ?dir - direction)
     :precondition (and (has ?g)
                        (stove (+ xpos (xdiff ?dir)) (+ ypos (ydiff ?dir))))
     :effect (cooked ?g)
    )
    (:action up
     :precondition (and (< ypos height) (not (obstacle xpos (+ ypos 1))))
     :effect (increase ypos 1)
    )
    (:action down
     :precondition (and (> ypos 1) (not (obstacle xpos (- ypos 1))))
     :effect (decrease ypos 1)
    )
    (:action right
     :precondition (and (< xpos width) (not (obstacle (+ xpos 1) ypos)))
     :effect (increase xpos 1)
    )
    (:action left
     :precondition (and (> xpos 1) (not (obstacle (- xpos 1) ypos)))
     :effect (decrease xpos 1)
    )
)
