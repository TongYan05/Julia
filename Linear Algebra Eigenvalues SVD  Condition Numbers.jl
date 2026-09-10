#= 
1. Eigenvalues and Eigenvectors(特征值和特征向量)
     /ˈaɪɡənˌvæljuːz/ /ˈaɪɡənˌvektəz/

Av=λv -> foundamental equation 
A->matrix v->vector λ->Eigenvalue

A=[2 0;
   0 3]
v=[1;
   0]
Av=[2; =λv
    0]
λ[1; = [2;0]
  0]
λ=2 -> Eigenvalue
v-> [1;0] -> Eigenvector

Similarly for v=[0;1] -> Eigenvalue=3

Eigenvalue -> how much the matrix strentches partticular special directions
like A is strentches 2 times horizontally, and 3 times longitudally
=#
using LinearAlgebra
A=[1 2;
   3 4]
E=eigen(A)
println(E.values," ",E.vectors)
println(E.values[1]," ",E.values[2])
println(E.vectors[:,1]," ",E.vectors[:,2])
A*E.vectors[:,1]≈E.values[1]*E.vectors[:,1]
A*E.vectors[:,2]≈E.values[2]*E.vectors[:,2]

#=
4. Symmetric Matrices
if A=Aᵀ then A is symmetric

for a real symmatric matrix -> 1. Eigenvalues are real 2.Eigenvector can be chosen orthogonal(正交的)/ɔːrˈθɒɡənl/
In fact, for a symmetric matrix, we can write:
A=QΛQᵀ
where:
Q contains orthonormal eigenvectors
Λ is a diagonal matrix of eigenvalues


=#
A=[4 1 2;
   1 2 3;
   2 3 10]
A'
A==A'


vals, vecs = eigen(A)
println(vals)
println(vecs)
vecs' * vecs # which is QQᵀ=I

#=
SPD -> Symmetric Positive Definite
if A=Aᵀ then A is symmetric
if xᵀAx>0 && x != 0 then A is Positive Definite -> x must be (n,1), which allows to multiply with A that is the rule
For an SPD matrix, this happens for every nonzero x.
=#
A = [2 1;
     1 2]
x = [1.0, 2.0]
x' * A * x
x = [-30.0, 1.0]
x' * A * x
# for SPD if and only if all its eigenvalues are Positive
A = [2 1;
     1 2]

vals = eigvals(A)
all(vals .> 0)

#=
9. SVD — Singular Value Decomposition
SVD tells us how a matrix stretches different directions.
The singular values are always non-negative.
In short: The matrix works by rotating (F.Vt), then stretching (F.S), and finally rotating again (F.U).

=#
using LinearAlgebra

A = [3 0;
     0 2]
F = svd(A)
F.Vt
F.U
F.S

# There is also a convenient function:
A = [3 0;
     0 2]
svdvals(A)

#=
Eigenvalues answer roughly:
Which directions stay on the same line when the matrix acts on them?
Singular values answer:
How much does the matrix stretch different orthogonal directions?

=#
A = [-2 1;
     1 2]
eigvals(A)
svdvals(A)

#=
12. Condition Number ->How sensitive a numerical problem is to small errors.
Cond(A)=σₘₐₓ/σₘᵢₙ
largest singular value and smallest singular value.


=#
A = [2 0;
     0 4]
# the sigular values are 2 and 4 -> 4/2=2
cond(A) # the Condition number bigger -> the problem is more sensitive!!

A = [1.0 0.0;
     0.0 0.000001]

cond(A) # The matrix stretches one direction by 1 but another direction by only 10⁻⁶.

#=
15. The Hilbert Matrix: A Classic Ill-Conditioned Matrix



=#
function hilbert(n)
    [1.0 / (i + j - 1) for i in 1:n, j in 1:n]
end
H = hilbert(5)
cond(H)
for n in 2:10
    H = hilbert(n)
    println(n, "  ", cond(H))
end


H = hilbert(10)
x_true = ones(10)
b = H * x_true
x = H \ b
norm(x - x_true) / norm(x_true)

#=
18. Spectral Radius
Take all eigenvalues, take their absolute values, and find the largest one.

=#
A = [2 0;
     0 -5]
vals = eigvals(A)
rho = maximum(abs.(vals))



function hilbert(n)
    [1.0 / (i + j - 1) for i in 1:n, j in 1:n]
end
for n in 2:10
    H = hilbert(n)
    println("n = ", n, ", cond(H) = ", cond(H))
end