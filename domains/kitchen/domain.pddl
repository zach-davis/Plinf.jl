(define (domain kitchen)
  (:requirements :negative-preconditions :typing)

  (:import base)

  (:types
    appliance food tool - physical ; physical objects
    pan - container
  )

  (:constants
    ; tools  
    knife - tool

    ; utensils
    frying_pan - pan

    ; surfaces
    cutting_board - surface
    plate - surface

    ; appliance
    stove - appliance

    ; openable things
    cupboard drawer fridge - container

    ; ingredients
    pineapple ice_cream - food

    ; locations
    stove_location cupboard_location fridge_location counter_location drawer_location - location

    ; surfaces
    counter_top stove_top - surface
  )

  (:predicates
    (sliced ?food - food)
    (fried ?food - food)
    (ice_cream_added ?food - food)
    (turned_on ?appliance - appliance)
  )

  (:functions
    (temperature ?oven - appliance) - number
  )

  (:init
    ; non-movable objects:
    (at stove_location stove)

    ; non-movable containers:
    (at cupboard_location cupboard)
    (at drawer_location drawer)
    (at fridge_location fridge)

    ; non-movable surfaces:
    (at stove_location stove_top)
    (at counter_location counter_top)
    
    ; in cupboard - TODO - would be nice to be able to specify this atomically
    (in cupboard frying_pan)
    (at cupboard_location frying_pan)
    (in cupboard cutting_board)
    (at cupboard_location cutting_board)
    (in cupboard plate)
    (at cupboard_location plate)

    ; in drawer
    (in drawer knife)
    (at drawer_location knife)

    ; in fridge:
    (in fridge ice_cream)
    (at fridge_location ice_cream)
    (in fridge pineapple)
    (at fridge_location pineapple)

    ; the liftable things:
    (liftable knife)
    (liftable cutting_board)
    (liftable pineapple)
    (liftable ice_cream)
    (liftable frying_pan)
    (liftable plate)

    ; a list of the known ingredients in the space
    (owns ice_cream user)
    (owns pineapple user)
  )

  ;
  ; appliances
  ;
  (:action turn_on
    :parameters(?appliance - appliance ?location - location ?agent - agent)
    :precondition (and
      (at ?location ?agent)
      (at ?location ?appliance)
      (not (turned_on ?appliance))
    )
    :effect (and
      (turned_on ?appliance)
    )
  )

    (:action turn_off
    :parameters(?appliance - appliance ?location - location ?agent - agent)
    :precondition (and
      (at ?location ?agent)
      (at ?location ?appliance)
      (turned_on ?appliance)
    )
    :effect (and
      (not (turned_on ?appliance))
    )
  )

  ;
  ; state change of objects
  ;
  (:action slice
    :parameters (?food - food ?agent - agent)
    :precondition (and
      (not (hidden ?food))
      (not (sliced ?food))
      (on cutting_board ?food)
      (holding knife ?agent)
      (at counter_location ?agent)
      (on counter_top cutting_board)
    )
    :effect (and
      (sliced ?food)
    )
  )

  (:action fry
    :parameters (?food - food ?pan - pan ?agent - agent)
    :precondition (and
      (not (hidden ?food))
      (in ?pan ?food)
      (sliced ?food)
      (not (fried ?food))
      (on stove_top ?pan)
      (at stove_location ?agent)
      (turned_on stove)
    )
    :effect (and
      (fried ?food)
    )
  )

  (:action add_ice_cream
    :parameters (?food - food ?agent - agent)
    :precondition (and
      (not (hidden ?food))
      (holding ice_cream ?agent)
      (fried ?food)
      (on plate ?food)
      (at counter_location ?agent)
    )
    :effect (and
      (ice_cream_added ?food)
    )
  )
)