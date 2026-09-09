#=
A vector is basically an arrow
it tells us:
1. which direction?
2. how far?

For example: v=(2,3) -> move two steps right and three steps up
        ↑
        |
        |       •(2,3)
        |      /
        |     /
        |    /
        |   / v
        |  /
        | /
--------+----------------→
 something like v=(2,3) is called 2D Vector due to two numbers
 three dimensions v=(1,2,3)

now imagine take two movements:
1. v=(3,2)
2. w=(1,4)
combine them -> v+w = (3+1,2+4)=(4,6)
so it is basically x direction+x direction and y direnction + y direction

Scalar multiplication(数乘)/ˈskælə ˌmʌltɪplɪˈkeɪʃn/
Scalar multiplication -> number * vector
like 3v=3(3,2)=(9,6)

Linear combinations -> combine Scalar multiplication and vector plus
v1=(1,2)
v2=(3,4)
2v1+3v2 -> this is linear combinations
general form: a₁v₁+a₂v₂+........+aₙvₙ

Dot product(点乘) dot(_,_) in julia
v1 ⋅ v2=1*3+2*4=11
In julia -> using LinearAlgebra
dot product also has a very important formula:
🤣v⋅w=||v|| ||w|| cosθ -> when θ == 90°, it is 0
thus: perpendicular vectors have dot product 0

Euclidean norm /juːˈklɪdiən nɔːrm/ (欧几里得范数)
||v1||₂= √(1²+2²)=√5 -> in julia is norm(v1)

Manhattan Norm (曼哈顿距离)
v3=(1,2,-3)
||v3||₁= ∑ᵢ|v₃ᵢ| =|1|+|2|+|-3|=0

Infinity norm -> find the biggest absolute value
v=(3,-8,2)
||v||∞ = 8

normalization -> making a vector has a length 1
v=(3,4)
||v||=5
v/||v||
in julia -> v/norm(v)

Cross product(叉乘) -> mainly used in 3D vector
v=(1,2,3) w=(4,5,6)
v × w =(2*6-3*5,3*4-1*6,1*5-2*4) = ||v|| ||w|| sinθ
in julia -> cross(A,B)

11. Outer product
Cauchy–Schwarz inequality(柯西不等式)/ˈkɔːʃi ˈʃwɑːts ɪnˈɛkwɒləti/
|v ⋅ w| <= ||v||||w||
the absolute length of dot product can never be bigger than
the product of the two vector lengths

Vector space
a collection of vectors where we can add them and multiply them by numbers in a sensible way.

Basis
(1,0) and (0,1) is called standard basis vector
standard basis vector can be combined to bulid every
2D vector in the sapce

Dimension -> means how many independent directions do we need?

Linear independence
Independent vectors give us new directions.
Dependent vectors contain information we already have.




=#
v = [3, 2]
w = [1, 4]
v + w
3v
v.*3+w.*4==[13,22]
using LinearAlgebra
dot(v,w)==11
# length of vector
norm(v)
norm([3,4])
v/norm(v)
norm(v/norm(v)) #normalization
m=[1,2,3]
n=[4,5,6]
cross(m,n)==[-3,6,-3]

# 17. Julia practice
using  LinearAlgebra
j=[3,4,5,7]
k=[9,1,2,8]
j+k==[12,5,7,15]
(j+k).*2
dot(j,k)==27+4+10+56
norm(j)
norm(j,1) # puls all the absolute value in the collection
norm(j,Inf)
k/norm(k)
cross(j,k) # cross product only defined for 3D vector
a = [1, 0, 0]
b = [0, 1, 0]
cross(a, b)

# 18. Drawing a 2D vector in Julia
using Plots
i=[1,9]
o=[1,9]
plot(i,o,arrow=true,xlabel="x",ylabel="y",
        legend=:topright,
        xlims=(0,15), # the scope of x coordinate
        ylims=(0,12)
)