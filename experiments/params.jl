"Custom relaxed distance heuristic to goal objects."
struct GemHeuristic <: Heuristic end

function Plinf.compute(heuristic::GemHeuristic,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    goals = goal_spec.goals
    goal_objs = [g.args[1] for g in goals if g.name == :has]
    at_terms = find_matches(@julog(at(O, X, Y)), state)
    locs = [[t.args[2].name, t.args[3].name]
            for t in at_terms if t.args[1] in goal_objs]
    pos = [state[:xpos], state[:ypos]]
    dists = [sum(abs.(pos - l)) for l in locs]
    min_dist = length(dists) > 0 ? minimum(dists) : 0
    return min_dist + GoalCountHeuristic()(domain, state, goal_spec)
end

"Custom relaxed distance heuristic for the taxi domain."
struct TaxiHeuristic <: Heuristic end

function Plinf.compute(heuristic::TaxiHeuristic,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    # Extract (sub)goal location
    goal = goal_spec.goals[1]
    if state[pddl"(passenger-at intaxi)"]
        goal_locname = goal.args[1]
    else
        goal_locname = find_matches(pddl"(passenger-at ?loc)", state)[1].args[1]
    end
    loc_term = Compound(Symbol("pasloc-at-loc"), [goal_locname, @julog(L)])
    goal_loc = find_matches(loc_term, state)[1].args[2].name
    goal_loc_idx = parse(Int, string(goal_loc)[4:end])
    # Compute Manhattan distance to goal location
    cur_loc_x, cur_loc_y = state[:xpos], state[:ypos]
    goal_loc_x, goal_loc_y = goal_loc_idx % 5, goal_loc_idx ÷ 5
    dist = abs(cur_loc_x - goal_loc_x) + abs(cur_loc_y - goal_loc_y)
    return dist
end

"Planner heuristics for each domain."
HEURISTICS = Dict{String,Any}()
HEURISTICS["doors-keys-gems"] = GemHeuristic
HEURISTICS["taxi"] = TaxiHeuristic

"Observation parameters for each domain."
OBS_PARAMS = Dict{String,Any}()
OBS_PARAMS["doors-keys-gems"] = observe_params(
    (@julog(xpos), normal, 0.25), (@julog(ypos), normal, 0.25),
    (@julog(forall(doorloc(X, Y), door(X, Y))), 0.05),
    (@julog(forall(item(Obj),has(Obj))), 0.05),
    (@julog(forall(and(item(Obj), itemloc(X, Y)), at(Obj, X, Y))), 0.05)
)
OBS_PARAMS["taxi"] = observe_params(
    (pddl"(xpos)", normal, 0.25), (pddl"(ypos)", normal, 0.25),
    (pddl"(forall (?l - pasloc) (passenger-at ?l))", 0.05)
)