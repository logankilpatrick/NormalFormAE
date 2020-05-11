function rhs(dx,x,p,t)
    dx[1] = p[3]*(x[1]-x[1]^3/3+x[2])
    dx[2] = -1/p[3]*(x[1]-p[1]+p[2]*x[2])
end

function rhs_FhN(x,t,p)
    dx = zeros(2,1)
    rhs(dx,x,p,t)
    return dx
end


function rhs(t,x::Array{T,2},p) where {T<:Number}
    return hcat([rhs_FhN(x[:,i],t[i],p) for i in 1:size(x)[2]]...)
    #return [x[3,:]'.*x[1,:]'.-x[2,:]'.+x[1,:]'.*(x[1,:]'.^2 .+x[2,:]'.^2); x[1,:]'.+x[3,:]'.*x[2,:]'.+x[2,:]'.*(x[1,:]'.^2 .+ x[2,:]'.^2); zeros(size(x)[2])']
end

function rhs(x,p)
    return (1/parsed_args["normalize"]).*[(parsed_args["p_normalize"].*p[3,:]').*((parsed_args["normalize"].*x[1,:]')-(parsed_args["normalize"].*x[1,:]').^ (3.0f0) ./ 3.0f0+(parsed_args["normalize"].*x[2,:]'));-1.0f0 ./ (parsed_args["normalize"].*p[3,:]') .* ((parsed_args["normalize"].*x[1,:]')-(parsed_args["p_normalize"].*p[1,:]')+(parsed_args["p_normalize"].*p[2,:]').*(parsed_args["normalize"].*x[2,:]'))]
end
