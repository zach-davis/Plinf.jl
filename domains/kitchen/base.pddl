(define (domain base)
  (:requirements :negative-preconditions :typing :equality :conditional-effects)

  (:types
    spatial - object ; object that can be located in space
    physical - spatial ; real object 
    location - spatial ; arbitrary location in space
    agent surface container - physical ; physical objects
  )

  (:constants
    ; our agent
    user - agent

    ; hide location - move hidden objects here to prevent them from showing up in the action menu
    hide_location - location
  )

  (:predicates
     (simulation-running)
     (on ?surface - surface ?object - physical)
     (at ?location - location ?object - physical)
     (in ?container - container ?object - physical)
     (owns ?item - physical ?agent - agent)
     (holding ?item - physical ?agent - agent)
     (liftable ?item - physical)
     (hidden ?item - physical)
  )
  
  ;
  ; simulation actions
  ;

  (:action start-simulation
    :parameters ()
    :precondition (not (simulation-running))
    :effect (simulation-running)
  )

  (:action stop-simulation
    :parameters ()
    :precondition (simulation-running)
    :effect (not (simulation-running))
  )

  ;
  ; containers and surfaces
  ;

  ; place an item on a surface:
  ; the item no longer has a location, it is simply "on" the surface
  (:action place_on
    :parameters(?item - physical ?surface - surface ?agent - agent ?location - location)
    :precondition (and
      (holding ?item ?agent)
      (at ?location ?agent)
      (at ?location ?surface)
      (not (exists (?container - container) (in ?container ?surface)))
    )
    :effect (and
      (not (holding ?item ?agent))
      (on ?surface ?item)
      (at ?location ?item)
    )
  )

  ; place an item in a container:
  ; the item no longer has a location, it is simply "in" the container
  (:action place_in
    :parameters(?item - physical ?container - container ?agent - agent ?location - location)
    :precondition (and
      (holding ?item ?agent)
      (at ?location ?agent)
      (at ?location ?container)
    )
    :effect (and
      (not (holding ?item ?agent))
      (in ?container ?item)
      (at ?location ?item)
    )
  )

  ; pick up an item off a surface
  (:action pick_up
    :parameters(?item - physical ?surface - surface ?agent - agent ?location - location)
    :precondition (and
      (on ?surface ?item)
      (at ?location ?surface)
      (at ?location ?agent)
      (liftable ?item)
      (not (hidden ?item))
    )
    :effect (and
      (holding ?item ?agent)
      (not (on ?surface ?item))
      (not (at ?location ?item))
    )
  )

  ; remove an item from a container
  (:action pick_remove
    :parameters(?item - physical ?container - container ?agent - agent ?location - location)
    :precondition (and
      (in ?container ?item)
      (at ?location ?container)
      (at ?location ?agent)
      (liftable ?item)
      (not (hidden ?item))
    )
    :effect (and
      (holding ?item ?agent)
      (not (in ?container ?item))
      (not (at ?location ?item))
    )
  )

  ;
  ; Move the user from one location to another
  ;
  (:action move
    :parameters(?location - location ?agent - agent)
    :precondition (and
      (not (at ?location ?agent))
    )
    :effect (and
      ; move the agent to the location
      (at ?location ?agent)

      ; all objects the agent is holding are at the agent's new location
      ; (forall (?item - physical) (when (holding ?item ?agent) (at ?location ?item)))

      ; the agent is at no other location
      (forall (?l2 - location) (when (not (= ?l2 ?location)) (not (at ?l2 ?agent))))

      ; no object the agent is holding is at the other location
      ; (forall (?item - physical ?l2 - location) (when (and (not (= ?l2 ?location)) (holding ?item ?agent)) (not (at ?l2 ?item))))
    )
  )
)