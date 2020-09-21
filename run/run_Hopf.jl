ENV["JULIA_CUDA_VERBOSE"] = true
ENV["JULIA_CUDA_MEMORY_POOL"] = "split" # Efficient allocation to GPU (Julia garbage collection is inefficient for this code apparently)
ENV["JULIA_CUDA_MEMORY_LIMIT"] = 8000_000_000

import Pkg
Pkg.activate(".")
using NormalFormAE
using Zygote

# Load correct rhs
include("../src/problems/Lorenz96.jl")

args = Dict()

# Define all necessary parameters
args["ExpName"] = "Lorenz96"
args["par_dim"] = 1
args["z_dim"] = 2
args["x_dim"] = 64
args["mean_init"] = 0.01f0 .+ zeros(Float32,args["x_dim"])
args["mean_a"] = [0.0]
args["xVar"] = 2.0f0
args["aVar"] = 0.5f0
args["tspan"] = [0.0, 40.0]
args["tsize"] = 300

args["bif_x"] = 0.84975f0 .+ zeros(Float32,args["x_dim"])
args["bif_p"] = [0.84975f0]

args["AE_widths"] = [64,32,16,8,2]
args["AE_acts"] = ["elu","elu","elu","id"]
args["Par_widths"] = [1,16,16,1]
args["Par_acts"] = ["elu","elu","id"]

args["training_size"] = 1000
args["test_size"] = 20
args["BatchSize"] = 50

args["nPlots"] = 20
args["nEnsPlot"] = 100
args["varPlot"] = 2.0f0

# Generate training data, test data and all neural nets
NN, training_data, test_data = pre_train(args,dxdt_rhs,dxdt_sens_rhs)


args["nEpochs"] = 30
#args["nBatches"] = 100
args["nIt"] = 1
args["ADAMarg"] = 0.001
args["P_AE_state"] = 1f0
args["P_cons_x"] = 0.001f0
args["P_cons_z"] = 0.001f0
args["P_AE_par"] = 1f0
args["P_sens_dtdzdb"] = 0.0f0
args["P_sens_x"] = 0.0f0
args["P_AE_id"] = 0.0f0
args["P_NLRAN_in"] = 0.001f0
args["P_NLRAN_out"] = 0.001f0
args["P_orient"] = 1.0f0
args["P_zero"] = 1f0
trained_NN = (NN["encoder"],NN["decoder"],NN["par_encoder"],NN["par_decoder"])
plot_ = train(args,training_data,test_data,NN,trained_NN,dzdt_rhs,dzdt_solve,dzdt_sens_rhs)

# args["nEpochs"] = 5
# #args["nBatches"] = 100
# args["nIt_1"] = 1
# args["nIt_2"] = 10
# args["ADAMarg"] = 0.01
# args["P_AE_state"] = 1f0
# args["P_cons_x"] = 0.001f0
# args["P_cons_z"] = 0.001f0
# args["P_AE_par"] = 1f0
# args["P_sens_dtdzdb"] = 0.0f0
# args["P_sens_x"] = 0.0f0
# args["P_AE_id"] = 0.0f0
# trained_NN1 = (NN["par_encoder"],NN["par_decoder"],NN["encoder"],NN["decoder"])
# trained_NN2 = (NN["u0_train"],)
# train(args,training_data,test_data,NN,trained_NN1,trained_NN2,dzdt_rhs,dzdt_sens_rhs)


