
function dxdt_rhs(dx,u,par,t)
    x = u .+ args["bif_x"]
    p = par .+ args["bif_p"]
    p_pf = args["p_pf"]
    p_lp = args["p_lp"]
    x_lp = args["x_lp"]
    p_tc = p_lp - x_lp^2        
    dx[1] = 0.01f0*x[1]*(p[1]-p_pf-x[1]^2)*(p[1]-p_lp+(x[1]-x_lp)^2)
    return dx
end

function dxdt_rhs(u,par,t)
    x = u .+ args["bif_x"]
    p = par .+ args["bif_p"]
    p_pf = args["p_pf"]
    p_lp = args["p_lp"]
    x_lp = args["x_lp"]
    p_tc = p_lp - x_lp^2        
    dx = 0.01f0 .* x .* (p .- p_pf .- (x .^ 2)) .* (p .- p_lp .+ (x .- x_lp).^ 2)
    return dx
end
function dxdt_jac(u,par,t)
    x = u .+ args["bif_x"]
    p = par .+ args["bif_p"]
    dx_ = Zygote.Buffer(x,args["x_dim"],args["x_dim"])
    ind_ = args["x_dim"]
    dx_[1,1] = -1.0f0
    dx_[1,2] = x[ind_]
    dx_[1,3:ind_-2] = zeros(Float32,ind_-4)
    dx_[1,ind_-1] = - x[ind_]
    dx_[1,ind_] = x[2]
    # ------------------
    dx_[2,1] = x[3]
    dx_[2,2] = -1.0f0
    dx_[2,3] = x[1]
    dx_[2,4:ind_-1] = zeros(Float32,ind_-4)
    dx_[2,ind_] = -x[1]
    # -----------------
    for i=3:(size(dx_,1)-1)
        if i != 3
            dx_[i,1:i-3] = zeros(Float32,i-3)
        end
        dx_[i,i-2] = -x[i-1]
        dx_[i,i-1] = x[i+1]
        dx_[i,i] = -1.0f0
        dx_[i,i+1] = x[i-1]
        if i != args["x_dim"]
            dx_[i,i+2:ind_] = zeros(Float32,ind_-i-1)
        end
    end
    # ----------------
    dx_[ind_,1] = x[ind_-1]
    dx_[ind_,2:ind_-3] = zeros(Float32,ind_-4)
    dx_[ind_,ind_-2] = -x[ind_-1]
    dx_[ind_,ind_-1] = x[1]
    dx_[ind_,ind_] = -1.0f0
    return copy(dx_)
end

function dxdt_sens(u,par,t)
    x = u .+ args["bif_x"]
    p = par .+ args["bif_p"]
    dx_ = Zygote.Buffer(x,args["x_dim"],args["par_dim"])
    dx_[1:args["x_dim"],1] = zeros(Float32,args["x_dim"]) .+ 1.0f0
    return copy(dx_)
end

function dxdt_sens_rhs(x,p,t,dxda)
    return dxdt_jac(x,p,t)*dxda .+ dxdt_sens(x,p,t)
end

# ------------------------------------------------------------------------------------

# dzdt_rhs
function dzdt_trans_solve(dz,z,p,t)
    dz .= (1 ./ (p[2]^2)) .* z .* (p[1] .+ z)
end

function dzdt_trans_rhs(z,p,t,bsize::Int)
    dz = Zygote.Buffer(z,size(z))
    dz[1,:] =  (1 ./ (p[2,:].^2)) .* (z[1,:] .* (p[1,:] .+ z[1,:]))
    return copy(dz)    
end

function dzdt_lp_solve(dz,z,p,t)
    dz .= (1 ./ (p[2]^2)) .* (p[1] .+ z.^2)
    return dz
end

function dzdt_lp_rhs(z,p,t,bsize::Int)
    dz = Zygote.Buffer(z,size(z))
    dz[1,:] =  (1 ./ (p[2,:] .^ 2)) .* (p[1,:] .+ z[1,:] .^2)
    return copy(dz)    
end


function dzdt_pitchfork_solve(dz,z,p,t)
    dz .= (1/(p[2]^2)) .* (p[1] .* z .- z .^ 3)
end

function dzdt_pitchfork_rhs(z,p,t,bsize::Int)
    dz = Zygote.Buffer(z,size(z))
    dz[1,:] =  (1 ./ (p[2,:] .^ 2)) .* (p[1,:] .* z[1,:] .- z[1,:].^3)
    return copy(dz)   
end


# dzdt_jac 
function dzdt_jac(x,p,t)
    dx_ = Zygote.Buffer(x,args["z_dim"],args["z_dim"])
    dx_[1,1] = p[1]-(3.0f0*x[1]^2+x[2]^2)
    dx_[1,2] = -1.0f0-x[1]*(2.0f0*x[2])
    dx_[2,1] = 1.0f0-x[2]*(2.0f0*x[1])
    dx_[2,2] = p[1]-(x[1]^2+3.0f0*x[2]^2)
    return copy(dx_)
end

function dzdt_sens(x,p,t)
    dx_ = Zygote.Buffer(x,args["z_dim"],args["par_dim"])
    dx_[1,1] = x[1]
    dx_[2,1] = x[2]
    return copy(dx_)
end

function dzdt_sens_rhs(x,p,t,dxda)
    return dzdt_jac(x,p,t)*dxda .+ dzdt_sens(x,p,t)
end 
