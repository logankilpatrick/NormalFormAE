using DifferentialEquations, Flux
NN["encoder"] = Chain(Dense(1,10),Dense(10,1))
NN["tscale"] = [1.0f0]
xxx = (NN["encoder"],NN["tscale"])

function trainn(xx,yy)
    prob = ODEProblem(dzdt_pitchfork_solve,[0.1],(0.0f0,10.0f0),[0.1;1.0])
    qq = [0.1]
    function lossy_(x)
        return sum(abs2,Array(solve(prob,p=[qq;x])))
    end
    function lossfinal(x,y)
        return lossy_(x) + sum(abs2,y(x))
    end
    println(lossfinal(xx,yy))
    ps = Flux.params(xx,NN["encoder"])
    loss, back = Flux.pullback(ps) do
        lossfinal(xx,yy)
    end
    grad = back(1f0)
    Flux.Optimise.update!(ADAM(0.1),ps,grad)
    println(xx)
end

train(xxx...)

## Doesn't work if you add u0 dependency