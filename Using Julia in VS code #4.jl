###################################################################################################################################################################
# Date - 2nd November 2020
# Authors - Chris Griffiths and Eva Delmas
# Based on a R code provided by Andrew Beckerman
# Title - Using Julia in VS code #4
###################################################################################################################################################################
# This doc follows on from "Using Julia in VS code" #1, #2 and #3 and assumes that your still working from your directory

# Here we will see how to use DifferentialEquation.jl to solve differential equations

import Pkg
Pkg.add("DifferentialEquations") 
using DifferentialEquations, Plots

# a declining sigmoid function ----
# this is the basis of thinking about how alpha changes with
# increasing contaminant (used below)
Alpha(A) = (1-(1/(1+10^(-5*(A-0)))))
AA = [-1:0.1:1;]
Aout = Alpha.(AA) 
plot(AA, Aout, xlabel = "AA", ylabel = "Aout")

## Core example
​
# Setup of the model/differential equations as a function, 
# the parameters and timesteps and then
# use of solver from DiffEq
​
# 1) Lotka Volterra type model: System of equations
# all models take:
# du : derivatives - will hold a vector with du/dt values
# u : initial values - will hold a vector of abundance (u)
# p : parameters 
# t : time

function LV(du,u,p,t)
    GrowthP = p.growthrate * u[1] * (1 - u[1]/p.K)# logistic resource growth
    IngestC = p.ingestrate * u[1] * u[2] # type I FR by consumer on resource
    MortC = p.mortrate * u[2] # density independent mortality of consumer
    du[1] = GrowthP - IngestC
    du[2] = p.assimeff * IngestC - MortC
  end

## 2) parameters, start values, times, simulation
# initial values:
u_init = [1.0;1.0] #we start with P = C = 1
# parameters:
# Here for the parameters we could have used a vector or a dictionnary
# but I usually chose a named tuple (similar to R lists) because it's unmutable
# meaning that once it's created you can't change it, which makes sense in this changes
# and also allows us to use explicit names. 
p = (
    growthrate = 1.0   # /day, growth rate of prey 
    , ingestrate = 0.2 # /day, rate of ingestion
    , mortrate = 0.2   # /day, mortality rate of consumer
    , assimeff = 0.5   # -, assimilation efficiency
    , K = 10           # mmol/m3, carrying capacity
    )
# time span
tspan = (0.0,200.0)
# define the problem
prob = ODEProblem(LV, u_init, tspan, p)
# solve
sol = solve(prob) #here we use the default algorithm, because it's a simple problem, see more info on how to chose your algorithm here: https://diffeq.sciml.ai/dev/solvers/ode_solve/

# fast view
# there is a plot recipe already defined for dif. eq. solutions, so you can directly pass the solution to plot
plot(sol, ylabel = "Density", title = "Lotka-Volterra", label = ["prey" "predator"], linestyle = [:dash :dot], lw = 2) 

## Modify ingestion rate by sigmoid function of contaminant 
​
# Aout is the declining sigmoid function from above
# shift the max rate of ingestion to the 0.2 as above in example.
# as contaminant increases, ingestion decreases with dose response curve
​
rrII = 0.2*Aout 
plot(rrII) # just to see shape and values
​
# rrII - 10 values of Ingestion Rate along sigmoid function
​
# collection zone
# will run solver for each rrII
# collect final timestep values
​
eqConc = zeros(length(rrII), 2) 
​
# loop over all ingestion rates
for (i,r) in enumerate(rrII) # i is the index (1:1:length(rrII)) and r is the corresponding value in the vector
    #parameters: the consumer rate of ingestion is modified
    parameters = (
        growthrate = 1.0   # /day, growth rate of prey 
        , ingestrate = r   # /day, rate of ingestion
        , mortrate = 0.2   # /day, mortality rate of consumer
        , assimeff = 0.5   # -, assimilation efficiency
        , K = 10
        )
    #initial values and time span are the same as above
    u_init = [1.0;1.0]
    tspan = (0.0,200.0)
    # define the problem
    prob = ODEProblem(LV, u_init, tspan, parameters)
    # solve
    sol = solve(prob) #here we use the default algorithm, because it's a simple problem, see more info on how to chose your algorithm here: https://diffeq.sciml.ai/dev/solvers/ode_solve/
    # store the results 
    eqConc[i,1] = sol.u[end][1] 
    eqConc[i,2] = sol.u[end][2] 
end

plot(rrII, eqConc
    , seriestype = [:scatter, :line]
    , label = ["" "" "prey" "predator"]
    , ylabel = "Abundance at t = 200"
    , xlabel = "rrII"
    , markershape = [:diamond :circle], mc = [:white :white] , msc = [:black :grey50], msw = 2
    , lw = 2, linestyle = [:dash :dot], lc = [:black :grey50])
