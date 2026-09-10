A=[1,2,3,4,5]
B=[1;2;3;4;5]
C=[1 2 3 4 5]
D=[46 64 75; 63 12 75; 25 53 25]
3==A[3]
5==B[end]
4==C[1,4]
25==D[end]
12==D[2,2]
A[1:end]
C[1:end]
D[1:3,1:2]
D[1:3,1:2:end]
D[2,2]=100
D
zeros(10,5)
ones(10,5)
rand(10,5)
collect(1:10)
collect(1:3:10)
E=[1 2 3;4 5 6]
F=[7 8 9;10 11 12]
hcat(E,F)
vcat(E,F)
cat(E,F,dims=1)
cat(E,F,dims=2)
sin.(F)
function sqrt_elements(x)
    sqrt(x)
end
sqrt_elements.(F)
[1 2;3 4]*[5 6;7 8] # 1*5+2*7=19
[1 2;3 4].*[5 6;7 8]
F'
transpose(F')==F
[1 2 3 4].*([5 6 7 8]')
[1,2,3,4].*([5,6,7,8]')
size(F)
ndims(F)
ndims([1,2,3])
ndims([1 2 3])
reshape(F,1,6)
G=[1 2 3;4 5 6;7 8 9]
size(F*G)==(2,3)
# use for loop to create a matrix
H=zeros(12,6)
x=0
for i in 1:12
    for j in 1:2:6
        H[i,j]=x+j
    end
    x=x+6
end
H
I=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
for (x,y) in enumerate(I) #enumerate() produce a pair (index,value)
    println("index: ",x," ","value: ",y)
end
# continue and break have the same use like java in julia
#=
differentiation rule like power rule xⁿ and exponential rule eˣ
product rule (ab)'=a'b+ab', chain rule f(g(x))=f'(g(x))g'(x)

Partial derivative: ∂f(x,y)/∂x

gradient(vector): ∇⋅f(x,y) the slope in a certain point, get the derivative and use the value of the point, the result is gradient
y=x²  derivative : 2x when x=2 then gradient=4

divergence(scalar) : ∇⋅f(x,y)

curl(vector) : get the Partial derivative such kind of things
∇×F(Fx,Fy,Fz)= [∂Fz/∂y - ∂Fy/∂z, ∂Fx/∂z - ∂Fz/∂x, ∂Fy/∂x - ∂Fx/∂y]

laplacian : ΔF->∇²F->∇⋅(∇F) -> calculate gradient and calculate divergence
divergence of gradient
f(x,y)=x²+y²
∇f(x,y)=(∂f(x,y)/∂x,∂f(x,y)/∂y)=(2x,2y)
∇⋅∇f(x,y)=∂f(x,y)/∂x+∂f(x,y)/∂y=4

∫xdy=xy-∫ydx

integration by part : ∫uv'dx=uv-∫u'vdx

格林第一恒等式（Green's First Identity)
∫_Ω u∇²v dΩ = ∫_∂Ω v(∂u/∂n) dS - ∫_Ω ∇u⋅∇v dΩ

Poisson equation: -∇²u=f

=#
using ForwardDiff
f(x)=x^4
ForwardDiff.derivative(f,2)
f1(x,y)=3x+4y-xy
x=10
Y=9
f2(x,y) = x^2 + x*y + y^2
ForwardDiff.gradient(f2,x)

x=[1.0,2.0]
k(x)=x[1]^2+3x[1]*x[2]+x[2]^2
ForwardDiff.gradient(k,x)

using Plots
plot(x->x^2-2x+1,-10,10)
x=1:100:1000
plot(x,sin.(x))
x1=range(1,100,length=1000)
plot!(x1,cos.(x1))
scatter!(x1,sin.(x1))

f3(x)=x^4-x^3*56+853*x^2-7425x
x=-1000:1:1000
plot(x,f3.(x),title="jiba",xlabel="x"
,ylabel="f3",legend=:topright,label="what")

x=rand(10,10)
gap=0
for i in 1:10
    for j in 1:10
        x[i,j]=j+gap
    end
    gap=gap+10
end
x
heatmap(x)


x=1:2:100
p1=plot(x->x^2-2x+5)
p2=plot(y->-y^2+2y-6,1,100)
plot(p1,p2,layout=(1,2))
savefig(p1,"absolute path..")

using LinearAlgebra
A=[1 2 3;4 5 6;7 8 9]
E=eigen(A)
println("Eigenvalue: ",E.values," 
","Eigenvector: ",E.vectors)
# 检验第 1 个特征值和特征向量
A * E.vectors[:, 1] ≈ E.values[1] * E.vectors[:, 1] 
# 检验第 2 个特征值和特征向量
A * E.vectors[:, 2] ≈ E.values[2] * E.vectors[:, 2] 
# 检验第 3 个特征值和特征向量
A * E.vectors[:, 3] ≈ E.values[3] * E.vectors[:, 3] 
