using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON

include("render.jl")
include("utils.jl")
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
#--- Generate Search Grid ---#
model_name = "birl"
action_noise = [0.125, 0.25, 0.5, 1, 2, 4]
grid_list = Iterators.product(action_noise)
grid_dict = []
for item in grid_list
    current_dict = Dict()
    current_dict["action_noise"] = item[1]
    push!(grid_dict, current_dict)
end

judgement_points =
[[1,7,17,23],
[1,9,14,17],
[1,9,17,24],
[1,7,14,23,32],
[1,6,11,24],
[1,4,6,11],
[1,5,8,13],
[1,9,12,31,44],
[1,7,22,37,50],
[1,14,24,29,40,54],
[1,7,13,20,26],
[1,6,11,26,36,49],
[1,8,14,20],
[1,4,7,10],
[1,5,8,10],
[1,7,12,18]
]

#--- Bayesian IRL inference ---#

function generate_init_states(state::State, domain::Domain, goals, k=5)
    ff = precompute(GemMazeDist(), domain)
    prob_astar = ProbAStarPlanner(heuristic=ff, search_noise=0.1)
    replanner = Replanner(planner=prob_astar, persistence=(2, 0.95))
    optimal_trajs =
        reduce(vcat, (prob_astar(domain, state, g)[2] for g in goals))
    suboptimal_trajs =
        reduce(vcat, (replanner(domain, state, g)[2]
                      for g in goals for i in 1:k))
    return [optimal_trajs; suboptimal_trajs]
end

function run_birl_inference(state::State, plan::Vector{<:Term},
                            goals, domain::Domain;
                            act_noise::Real=0.1, verbose::Bool=true)
    # Generate set of initial states to sample from
    init_states = [generate_init_states(state, domain, goals);
                   PDDL.simulate(domain, state, plan)]
    # Solve MDP for each goal via real-time dynamic programming
    h = precompute(GemMazeDist(), domain) # Change to GemMazeDist for DKG
    planners =  [RTDPlanner(heuristic=h, act_noise=act_noise, rollout_len=5,
                            n_rollouts=length(init_states)*10) for g in goals]
    for (planner, goal) in zip(planners, goals)
        if verbose println("Solving for $goal...") end
        Plinf.solve!(planner, domain, init_states, GoalSpec(goal))
    end
    # Iterate across plan and compute goal probabilities
    goal_probs = fill(1.0/length(goals), length(goals))
    all_goal_probs = [goal_probs]
    if verbose println("Goal probs.:") end
    for act in plan
        # For each goal, compute likelihood of act given current state
        step_probs = map(zip(planners, goals)) do (planner, goal)
            goal_spec = GoalSpec(goal)
            qs = get!(planner.qvals, hash(state),
                      Plinf.default_qvals(planner, domain, state, goal_spec))
            act_probs = Plinf.softmax(values(qs) ./ planner.act_noise)
            act_probs = Dict(zip(keys(qs), act_probs))
            return act_probs[act]
        end
        # Compute filtering distribution over goals
        goal_probs = goal_probs .* step_probs
        goal_probs ./= sum(goal_probs)
        if verbose
            for prob in goal_probs @printf("%.3f\t", prob) end
            print("\n")
        end
        # Advance to next state
        state = transition(domain, state, act)
        push!(all_goal_probs, goal_probs)
    end
    return all_goal_probs
end

#--- Search ---#
mkpath(joinpath(path, "results_entire_dataset", model_name, "search_results"))

# Load human data
human_data = []
for category in 1:4
    for scenario in 1:4
        category = string(category)
        scenario = string(scenario)
        file_name = category * "_" * scenario * ".csv"
        temp = vec(CSV.read(joinpath(path, "average_human_results_arrays", file_name), datarow=1, Tables.matrix))
        append!(human_data, temp)
    end
end

# Search parameters
corrolation = []
for (i, params) in enumerate(grid_dict)
    model_data = []
    scenarios_list = []
    corrolation_list = []
    for category in 1:4
        category = string(category)
        for scenario in 1:4
            scenario = string(scenario)

            #--- Initial Setup ---#
            # Specify problem
            stimulus_idx = ((parse(Int64,category)-1) * 4) +  parse(Int64,scenario)
            experiment = "scenario-" * category * "-" * scenario
            problem_name = experiment * ".pddl"

            # Load domain, problem, actions, and goal space
            problem = load_problem(joinpath(path, "new-scenarios", problem_name))
            file_name = category * "_" * scenario * ".dat"
            actions = readlines(joinpath(path, "new-scenarios", "actions" ,file_name))
            goals = @julog  [has(gem1), has(gem2), has(gem3)] 

            goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
            gem_terms = @julog [gem1, gem2, gem3]
            gem_colors = Dict(zip(gem_terms, goal_colors))

            # Initialize state
            state = initialize(problem)
            start_pos = (state[:xpos], state[:ypos])
            goal = [problem.goal]

            #--- Initialize algorithm ---#
            plan = parse_pddl.(actions)

            #--- Run inference ---#
            goal_probs = run_birl_inference(state, plan, goals, domain, act_noise=params["action_noise"], verbose=false)
            flattened_array = collect(Iterators.flatten(goal_probs[1:end]))
            only_judgement_model = []
            for i in judgement_points[stimulus_idx]
                idx = (i) * 3
                for j in flattened_array[idx-2:idx]
                    push!(only_judgement_model, j)
                end
            end
            append!(model_data, only_judgement_model)

            #--- Store corrolation for current scenario ---#
            file_name = category * "_" * scenario * ".csv"
            temp_human_data = vec(CSV.read(joinpath(path, "average_human_results_arrays", file_name), datarow=1, Tables.matrix))
            push!(scenarios_list, category*"_"*scenario)
            push!(corrolation_list, cor(only_judgement_model, temp_human_data))
        end
    end

    R = cor(model_data, human_data)
    push!(corrolation, R)

    #--- Save corrolation CSV ---#
    df = DataFrame(Scenario=scenarios_list, Corrolation=corrolation_list)
    CSV.write(joinpath(path, "results_entire_dataset", model_name, "search_results", "parameter_set_"*string(i)*".csv"), df)

    # #--- Save Parameters ---#
    params["corr"] = R
    json_data = JSON.json(params)
    json_file = joinpath(path, "results_entire_dataset", model_name, "search_results", "parameter_set_"*string(i)*".json")
    open(json_file, "w") do f
        JSON.print(f, json_data)
    end
end

#--- Save Best Parameters ---#
mxval, mxindx = findmax(corrolation)
best_params = grid_dict[mxindx]
best_params["corr"] = mxval
json_data = JSON.json(best_params)
json_file = joinpath(path, "results_entire_dataset", model_name, "search_results", "best_params_"*string(mxindx)*".json")
open(json_file, "w") do f
    JSON.print(f, json_data)
end