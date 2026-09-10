#=
matrix -> [ ; ] the shape must be a rectangle
size(A) -> check the size return (row,column)
A[row,column] -> access the elements

matrix addition
A+B -> addition in matching position

Scalar multiplication -> a Scalar is an ordinary number like 5
in julia -> 5*A / A*5 -> that's ok!

matrix multiplication -> the column of left matrix must be equal to the row of right matrix
A*B is totally different from B*A

tanspose -> exchange the row and column
for the size befor and after transpose -> (x,y) => (y,x)
in julia -> A' that's ok!!
important transpose rule -> (AB)' == B'A'

identity matrix -> A*B==A && B*A==A B does not change A
then, B is indentity matrix
I -> it is julia's special indentity operator

Inverse Matrix -> A*A⁻¹==I && A⁻¹*A==I
in julia -> inv(A) -> that is ok!!

determinant -> is a number associated with square matrix
A=[ a b; c d]
det(A)=ad-bc, in julia -> det(A)

what does determinant means?
Answer: The determinant's absolute value measures the area or volume scaling factor, its sign indicates whether the spatial orientation is preserved or flipped, and a value of zero means the space is collapsed to a lower dimension making the matrix non-invertible.
When the matrix preserves the space's orientation, the determinant is positive; when it flips the space (like a mirror reflection), it is negative; and when it squashes the space into a lower dimension (causing overlapping rows or columns), the determinant is exactly zero.

2D → determinant tells you area scaling
3D → determinant tells you volume scaling

rank 
A=[1 2;2 4] -> rank(A)=1 -> A contains a single independent direction of information
B=[1 2; 3 4] -> rank(B)=2
C=[1;2;3;4;5] ->rank(C)=1

singular matrix -> a square matrix do not have inverse
det(A)=0 when A=[1 2 ; 2 4] -> det(A)=1*4-2*2=0

Vital Relation Map -> det(A)=0 <==> A is singular <==> A has no inverse
when size(A)=(n,n) -> rank(A)<n
A⁻¹=1/det(A)×伴随矩阵

Sparse Matrix -> particular relevant to FEM
Suppose you have a huge matrix: Most elements are zero.
We call this a sparse matrix.
If the matrix becomes extremely large, storing every zero wastes memory.
Imagine a million × million matrix where only a few million entries are non-zero.
You don't want to store:
0 0 0 0 0 0 0 0 ...
over and over again.
Instead, sparse storage remembers mostly:
(position) → value
For example:
(1,1) → 5
(1,5) → 2
(2,2) → 8
...
This can save enormous amounts of memory.

Why Is This Important for FEM?
In the Finite Element Method, you often end up with a large system such as:
Ku=f
where:
K = stiffness(刚度) matrix
u = unknown displacement/vector(位置位移向量)
f = forces/load(载荷) vector
The matrix K can become extremely large.
But most entries(the elements in matrix) are often zero because each finite element only interacts directly with nearby elements.
So you get a matrix that is: large but mostly zero
FEM → large matrices → lots of zeros → sparse matrices save memory and computation.

using SparseArrays





=#
A=[10,20]
B=[10 20;30 40]
C=[10 20;30 40;50 60]
size(C)
C[2,2]
D=[100 200;300 400;500 600]
C+D
5*D
C*D # the column of C must be equal to the row of D
D'
E=[1 2;3 4]
C*E
(C*E)'==E'*C'
F=[1 0;0 1]
F*B==B
B*F==B # then F is indentity matrix
D*I # I DO NOT KNOW HOW IT WORK
using LinearAlgebra
I
inv(E)
inv(E)*E ≈ I
E*inv(E)≈inv(E)*E # \approx -> ≈
# 8. Solving Equations with a Matrix
# suppose we have 2x+y=5 and x+3y=6, how to solve them?
K=[2 1;1 3]
R=[5;6]
X=K\R # \ is better and faster than inv(K)*R, because the latter one have to transform the matrix firstly！！
K*X ≈ R
det(B)≈-200
H=[1 2 3;20 30 40;300 400 500]
det(H) # Sarrus' Rule to calculate
det(inv(H))
A1=[1 2;2 4]
B1=[1 2; 3 4]
C1=[1;2;3;4;5]
rank(A1)
rank(B1)
rank(C1)

# 22. Let's Put Everything Together
using LinearAlgebra
A = [2.0 1.0;
     1.0 3.0]
b = [5.0, 6.0]
A*b
A.*b # they are different
det(A)
eigen(A)
rank(A)
# we wish Ax=b
x=A\b
A*x≈b
