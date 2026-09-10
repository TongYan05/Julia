# Basic arithmetic
10.0/3
typeof(7/2)

# Integer division: div
div(25,5)
div(25,4)
div(10,3)


# Remainder / modulo: %
17%5


# Power: ^
2^10
'a'^4
"java"^6
"java"^2*"python"^3


# Comparison operators
# == != <= >= < >


# Chained comparisons — a nice Julia feature
x=10
1<x<100
1<x && x > 4
c=10
d=98
3<=x==c<98<100


# Floating-point comparison — this is important
0.1+0.2==0.3
#for approximate numerical comparison
isapprox(0.1+0.2,0.3)
0.1+0.2≈0.3# \approx -> =, which means approximate equal
isapprox(1.00001, 1.0; atol=0.001)# absolute tolerance -> the maximum varies
isapprox(10,3;atol=5)
isapprox(10,3;atol=7)


# Logical operators
# && || !
k=100
k<90 || k >=100
!(k<1)


# Short-circuit evaluation
10>90&&1
10<90||10<1
10<90|10<1


# Compound assignment
o=10
o+=1
o-=1
o*=2
o/=2
10/2 #/ can automatically convert it into Float64


# Special floating-point values
typeof(1.0/0.0)
typeof(-1.0/0.0)
typeof(0.0/0.0)
0.0/0.0 # not a number
1.0/0.0 # positive infinity
-1.0/0.0 # negative infinity


# Checking for these values
isfinite(10.0)
10/3
isfinite(10/3)
isfinite(10.0/3)
isfinite(Inf)
isinf(10.0) # is infinite?
isnan(NaN) # Not a number


# A subtle thing about NaN
NaN==NaN
x=NaN
isnan(x)


# Putting the ideas together: circle area
r = 5.0
area=π*r^2
isfinite(area)


# Sphere volume
volume=4*π*r^3/3
isfinite(volume)


# Operator precedence
# simple


# One Julia-specific thing worth knowing: broadcasting
x.+1 # . means broadcast this operation element-by-element
y=[2,5,8,0]
y=y.+2
y=y.^2
y[1]