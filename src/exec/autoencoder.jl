using Flux

function get_activation(x::String)
    if x == "relu"
        activation_ = relu
    elseif x == "elu"
        activation_ = elu
    elseif x == "sigmoid"
        activation_ = sigmoid
    elseif x == "leakyrelu"   
        activation_ = leakyrelu
    elseif x == "tanh"
        activation_ = Flux.tanh
    elseif x == "id"
        activation_ = -1
    end

    return activation_
end

function act_der(act::String,x,avgder=0)
    if act == "sigmoid"
        der_ = sigmoid.(x) .*(1.0f0 .- sigmoid.(x))
    elseif act == "tanh"
        der_ = 1.0f0 .- (tanh.(x)).^2
    elseif act == "relu"
        if avgder == 1
            der_ = 0.5f0 .*(sign.(x) .+ 1.0f0)
        else
            der_ = 0.5f0 .*(sign.(x) .+ abs.(sign.(x)))
        end
    elseif act == "leakyrelu"
        if avgder == 1
            der_ = 0.5f0 .*(sign.(x) .+ 1.0f0) .+ 0.01f0./2.0f0 .*( -sign.(x) .+ 1.0f0)
        else
            der_ = 0.5f0 .*(sign.(x) .+ abs.(sign.(x))) .- 0.01f0./2.0f0 .*( sign.(x) .- abs.(sign.(x)))
        end
    elseif act == "elu"
        if avgder == 1
            der_ = 0.5f0 .*(sign.(x) .+ 1.0f0) .+ exp.(x)./2.0f0 .*( -sign.(x) .+ 1.0f0)
        else
            der_ = 0.5f0 .*(sign.(x) .+ abs.(sign.(x))) .- exp.(x)./2.0f0 .*( sign.(x) .- abs.(sign.(x)))
        end
    end
    return der_
end
        
function get_autoencoder(args::Dict)
    function get_NN_Flux(widths::Array,act_widths::Array)
        local NN = []
        for i in 1:(size(widths)[1]-1)
            activation_ = get_activation(act_widths[i])
            if activation_ == -1
                append!(NN,[Dense(widths[i],widths[i+1])])
            else
                append!(NN,[Dense(widths[i],widths[i+1],activation_)])
            end
        end
        return Chain(NN...)
    end
    
    AE_widths = args["AE_widths"]
    Hom_widths = args["Hom_widths"]
    AE_acts = args["AE_acts"]
    Hom_acts = args["Hom_acts"]

    encoder = get_NN_Flux(AE_widths,AE_acts)
    decoder = get_NN_Flux(reverse(AE_widths),reverse(AE_acts))
    hom_encoder = get_NN_Flux(Hom_widths,Hom_acts)
    hom_decoder = get_NN_Flux(reverse(Hom_widths),reverse(Hom_acts))

    return encoder, decoder, hom_encoder, hom_decoder
end

function dt_NN(NN, input_, left_dt, acts)
    # Given input, left_dt and neural net NN, compute right hand side time-derivative via chain rule
    # As per Champion et al. (PNAS 2019)
    W_,b_ = Flux.params(NN.layers[1])
    l = W_*input_.+b_
    dl = W_*left_dt
    act = acts[1]
    nlayers = div(length(Flux.params(NN)),2)
    for i=2:nlayers
        W_,b_ = Flux.params(NN.layers[i])
        act_fun = get_activation(act)
        if act != "id"
            dl = W_*(act_der(act,l).*dl)
            l = W_*act_fun.(l) .+ b_
        else
            dl = W_*dl
            l = W_*l .+ b_
        end
        act = acts[i]
    end
    act_fun = get_activation(act)
    if act != "id"
        dl = act_der(act,l).*dl
        l = act_fun.(l)
    end     
    return dl
end

    
#         l = W_*act_fun.(l) .+ b_
#         if act == "elu"
#             dl = W_*(min.(exp.(l)).*dl)
#             l = W_*elu.(l) .+ b_
#         elseif act == "relu"
#             dl = W_*(Flux.TrackedArray(Float32.(l.>0)).*dl)
#             l = W_*relu.(l) .+ b_
#         elseif act == "sigmoid"
#             dl = W_*((1.0f0 .- sigmoid.(l)).*sigmoid.(l).*dl)
#             l = W_*sigmoid.(l) .+ b_
#         elseif act == "id"
#             dl = W_*dl
#             l = W_*l .+ b_
#         end
#         act = acts[i]
#     end
#     return dl
# end

function build_loss(args,normalform_,encoder, decoder)
    function loss_(in_,dx_)
        enc_ = encoder(in_)
        dz1 = dt_NN(encoder,in_,dx_,args["AE_acts"])
        dec_ = decoder(enc_)
        #nf_hom = hcat([normalform_(hom_[:,i],0.0f0,0.0f0) for i in 1:size(hom_)[2]]...) |> gpu
        dx1 = dt_NN(decoder,enc_,normalform_(enc_),reverse(args["AE_acts"]))
        #dx1 = dt_NN(hom_decoder,hom_,nf_hom,reverse(args["Hom_acts"]))
        loss_datafid = args["P_DataFid"]*Flux.mse(in_,dec_)
        loss_dx = args["P_dx"]*Flux.mse(dx_,dx1)
        loss_dz = args["P_dz"]*Flux.mse(dz1,normalform_(enc_))
        #loss_dz2 = args["P_dz2"]*sum(abs,dz1[4:end,:])
        #loss_dz = args["P_dz"]*Flux.mse(dz_,nf_hom)
        args["loss_AE"] = loss_datafid
        args["loss_dxdt"] = loss_dx
        args["loss_dzdt"] = loss_dz
        #args["loss_dzdt2"] = loss_dz2
        loss_total = loss_datafid  + loss_dz + loss_dx #+ loss_dz2
        args["loss_total"] = loss_total
        return loss_total
    end
    return loss_
end

        
        
        
    
        
