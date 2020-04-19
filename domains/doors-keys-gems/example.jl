using Julog, PDDL, Gen, Printf
using Plinf

include("utils.jl")
include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Initialize state, set goal and goal colors
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]
goal_colors = [:red, :gold, :blue]
gem_terms = @julog [gem1, gem2, gem3]
gem_colors = Dict(zip(gem_terms, goal_colors))

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=goal_count)
plan, _ = planner(domain, state, goal)
println("== Plan ==")
display(plan)
plt = render(state; start=start_pos, plan=plan, gem_colors=gem_colors)
traj = PDDL.simulate(domain, state, plan)
@assert satisfy(goal, traj[end], domain)[1] == true

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=goal_count, search_noise=10)
plt = render(state; start=start_pos, gem_colors=gem_colors)
@gif for i=1:20
    plan, traj = planner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=goal_count, search_noise=2)
replanner = Replanner(planner=astar, persistence=0.95)
plt = render(state; start=start_pos, gem_colors=gem_colors)
@gif for i=1:20
    plan, traj = replanner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

#--- Goal Inference Setup ---#

# Specify possible goals
goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]
goal_names = [repr(t[1]) for t in goals]

# Sample a trajectory as the ground truth (no observation noise)
goal = goals[uniform_discrete(1, length(goals))]
_, traj = planner(domain, state, goal)
traj = traj[1:min(length(traj), 25)]
plt = render(state; start=start_pos, gem_colors=gem_colors)
plt = render!(traj, plt; alpha=0.5)

# Define observation noise model
obs_params = observe_params(
    (pddl"(xpos)", normal, 0.25), (pddl"(ypos)", normal, 0.25),
    (pddl"(door ?x ?y)", 0.05),
    (pddl"(forall (?obj - item) (has ?obj))", 0.05),
    (pddl"(forall (?obj - item) (at ?obj ?x ?y))", 0.05)
)
obs_terms = collect(keys(obs_params))

# Assume either a planning agent or replanning agent as a model
agent_model = plan_agent # replan_agent
if agent_model == plan_agent
    agent_args = (planner, domain, state, goals, obs_params)
else
    @gen observe_fn(state::State) =
        @trace(observe_state(state, domain, obs_params))
    agent_args = (replanner, domain, state, goals, observe_fn)
end

#--- Offline Goal Inference ---#

# Run importance sampling to infer the likely goal
n_samples = 20
observations = traj_choices(traj, domain, obs_terms, :traj)
traces, weights, _ =
    importance_sampling(agent_model, (length(traj), agent_args...),
                        observations, n_samples)

# Plot sampled trajectory for each trace
plt = render(state; start=start_pos, gem_colors=gem_colors)
render_traces!(traces, weights, plt; goal_colors=goal_colors)
plt = render!(traj, plt; alpha=0.5) # Plot original trajectory on top

# Compute posterior probability of each goal
goal_probs = get_goal_probs(traces, weights, 1:length(goals))
println("Posterior probabilities:")
for (goal, prob) in zip(goals, values(sort(goal_probs)))
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end

# Plot bar chart of goal probabilities
plot_goal_bars!(goal_probs, goal_names, goal_colors)

#--- Online Goal Inference ---#

# Set up visualization and logging callbacks for online goal inference
anim = Animation() # Animation to store each plotted frame
goal_probs = [] # Buffer of goal probabilities over time
plotters = [ # List of subplot callbacks:
    render_cb,
    goal_lines_cb,
    # goal_bars_cb,
    # plan_lengths_cb,
    # particle_weights_cb,
]
canvas = render(state; start=start_pos, show_objs=false)
callback = (t, s, trs, ws) ->
    (multiplot_cb(t, s, trs, ws, plotters;
                  canvas=canvas, animation=anim, show=true,
                  gem_colors=gem_colors, goal_colors=goal_colors,
                  goal_probs=goal_probs, goal_names=goal_names);
     print("t=$t\t");
     print_goal_probs(get_goal_probs(trs, ws, 1:length(goals))))

# Run a particle filter to perform online goal inference
n_samples = 20
traces, weights =
    agent_pf(agent_model, agent_args, traj, obs_terms, domain, n_samples;
             callback=callback)
# Show animation of goal inference
gif(anim; fps=2)