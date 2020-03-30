export goal_count, manhattan

"Heuristic that counts the number of goals unsatisfied in the domain."
function goal_count(goals, state::State, domain::Domain)
    count = sum([state[domain, g] for g in goals])
    return count
end

"Manhattan distance heuristic."
function manhattan(goals, state::State, domain::Domain;
                   fluents=@julog([xpos, ypos]))
    goal = State(goals)
    goal_vals = [goal[domain, f] for f in fluents]
    curr_vals = [state[domain, f] for f in fluents]
    dist = sum(abs.(goal_vals - curr_vals))
    return dist
end

"HSP family of delete relaxation heuristics (h_add, h_max, etc.)."
function hsp(goals, state::State, domain::Domain; op::Function=maximum)
    # Initialize fact/action levels/costs in a GraphPlan-style graph
    fact_costs = Dict{Term,Tuple{Int,Float64}}(f => (1, 0) for f in state.facts)
    act_costs = Dict{Term,Tuple{Int,Float64}}()
    level = 1
    while true
        facts = Set(keys(fact_costs))
        state = State(facts, Dict{Symbol,Any}())
        if satisfy(goals, state, domain)[1]
            return op([fact_costs[g][2] for g in goals])
        end
        actions = available(state, domain)
        for act in actions
            # Compute cost of reaching each action
            pre = get_preconds(act, domain)
            cost = op([get(fact_costs, f, (0, 0))[2] for f in pre])
            act_costs[act] = (level, cost)
            additions = execute(act, state, domain; as_diff=true).add
            # Compute cost of reaching each added fact
            cost = cost + 1
            for fact in additions
                if cost < get(fact_costs, fact, (0, Inf))[2]
                    fact_costs[fact] = (level+1, cost)
                end
            end
        end
        level += 1
        if length(fact_costs) == length(facts) && keys(fact_costs) == facts
            # Terminate if there's no change to the number of facts
            return Inf
        end
    end
end

"h_max delete relaxation heuristic."
h_add(goals, state::State, domain::Domain) =
    hsp(goals, state, domain; op=maximum)

"h_add delete relaxation heuristic."
h_add(goals, state::State, domain::Domain) =
    hsp(goals, state, domain; op=sum)
