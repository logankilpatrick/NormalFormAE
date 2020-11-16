module NormalFormAE

using LinearAlgebra, Flux, Zygote
using Plots, LaTeXStrings, Printf, Measures
using FileIO, BSON, DifferentialEquations, Distributions

include("ae.jl")
include("exec/backpass_explicit.jl")
include("model.jl")
include("build.jl")
include("exec/build_loss.jl")
include("exec/plot.jl")
include("exec/post_train.jl")
include("exec/batch.jl")

export AE, xModel, NormalForm, NFAE
export gen_plot, plotter, save_posttrain, load_posttrain
export makebatch

end
