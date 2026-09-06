# Arrays and Matrices /ˈmeɪtrɪsɪz/
# Vectors -> one-dimension array called a vector
arr=[1,2,3,4,5,6,7,8]
typeof(arr)


# Matrices -> a matrix is a two-dimension array
A=[1 2;3      4] # space means next column, semicolon means next row
B=[324 5234 734 724; 65426 5 2 42] # the elements in each row must be same


# Julia Uses 1-Based Indexing -> the index start form 1 in an array
# end -> the last index
arr[end] 
A[1,end]
A[end]
B[end,1]


# Slicing
arr[2:4]
B[1,1:end] # take elements from the first row, from 1 to end elments
B[1:2,1:end]
B[1:2,1:3] # take elements from 1 to 2 row, from 1 to 3 elements
arr1=[1,2,3,4,5,6,7,8,9,10,11,12,13]
arr[1:12:end] # 1-> start 12-> step
arr2=[1 2 3 4 5 6 7 8 9 10;1 2 3 4 5 6 7 8 9 10]
arr2[1:2,1:5]
arr2[:,1:2:end] # : means take all the rows, from column 1 to column end, step is 2
M = [
    1  2  3  4  5  6;
    7  8  9 10 11 12;
    13 14 15 16 17 18;
    19 20 21 22 23 24
]
M[2:3,2:1:5] # from row 2 to row 3, from column 2 to column 5 step 1
M[1:2]
M[1:2,1]

# Modifying Arrays
M[2,2]
M[2,2]=80
M
M[1:4,1:1:3]
M[1:4,1:3].=0 # make the elements 0 in the scope
M[1:2,1:3].+=1
M


# Creating Arrays
zeros(4)
zeros(6,3) # the first element is row the second is column
ones(10,10)
rand(7,3) # create a matrix with random value from 0 to 1


# collect
collect(1:10)
collect(1:2:10)


# range
range(1,10,length=10) # give me 10 equally spaced numbers from 1 to 10
1==1.0
1:1:2==range(1,2,length=2)


# Concatenating Arrays
# vcat -> vertical connection
vcat=([1,2],[3,4])
A = [1 2]
B = [3 4]
vcat(A,B)
# hcat -> horizontal connection
hcat([1,2],[3,4])
# cat(dims=...)
cat(A,B;dims=1)
cat(A,B;dims=2)
M
N= [
    1  2  3  4  5  6;
    7  8  9 10 11 12;
    13 14 15 16 17 18;
    19 20 21 22 23 24
]
cat(M,N,dims=1)
cat(M,N,dims=2)


# Broadcasting ⭐ Very Important arr.+1 like this
M.^=2
M


# The Dot Is More Than Just Syntax -> do this operation elements-by-elements
L=sin.(M)
L
function plus_nine(x)
    x+9
end
plus_nine.(M) # function name.(something)


# A * B vs A .* B ⭐⭐⭐
A = [1 2;
     3 4]
B = [5 6;
     7 8]
A*B
A.*B


# Transpose: A'
A = [1 2 3;
     4 5 6]
A' # adjoint, also called conjugate transpose /ˈkɒndʒəɡət//trænsˈpəʊz/ 共轭转置
transpose(A')


# Inner Product: dot
v = [1, 2, 3]
w = [4, 5, 6]
v'
v
v'*w # 1*4 + 2*5 + 3*6


# size, length, and ndims
M
size(M)
ndims(M) # number of dimensions 2 dimension so the result is 2
length(M) # the number of elements in the matrix



# reshape
A = [1, 2, 3, 4, 5, 6]
reshape(A,1,6)
reshape(M,1,24)


# Views — @view -> performance optimization.
arr9 = [10, 20, 30, 40, 50]
arr9[2:3]
@view arr9[2:4]
arr9


# Array Comprehensions
[x^2 for x in 1:2:5]
[x for x in 1:100 if x > 50]
[x%2==0 ? true : false for x in 1:100]


# map vs Comprehension
map(x->x^3,1:10)
map(x->x%2 == 0 ? true : false,1:10 )
map(x->x%2 == 0 ? true : false,1:100)



# Matrix–Vector Multiplication
A = [1 2 3;
     4 5 6;
     7 8 9]

v = [1, 2, 3]
A*v