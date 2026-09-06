# x do not have permanently fixed type
x=10
x=3.14
x="hello"


# Checking a type with typeof()
typeof(x)
typeof(3.14)
typeof(true)


# Integer types
y=10
y2=-20
y3=1000000
typeof(10)
# the maximum value can be found with typemax()
typemax(Int64)
typemax(Int64)+1 #like java, this is overflow


# Floating-point numbers
typeof(3.19)
a=1.0f0 # f0 tells julia: I want this floating-point number to be Float32
typeof(a)


# Boolean values
b=true
typeof(b)
b1=10
b2=10
b1==b2
b1>3
b2 == 8


# String vs Char
name="Yan Tong" # using double quotes
typeof(name)
'a'
typeof('a')


# nothing vs missing
c=nothing # no meaningful values
typeof(c)
# missing -> have values, but it is unknown


# Type conversion
Float64(100)
typeof(Float64(89))
Int(3.14)
string(42)


# Parsing strings into numbers
parse(Int,"2778")
typeof(parse(Int,"2778"))
parse(Float64,"27.78")
typeof(parse(Float64,"27.78"))


# Constants with const(must be uppercase->convention)
const D=2005
D+2005
const DAY=7
const SPEED=60
const NAME="YAN TONG"


# Multiple assignment
e1,e2,e3="java","julia","python"
e1
e3
e2
function getPoint()
    return 91,78
end
e4,e5=getPoint()


# The ternary operator
age=21
age > 18 ? "adult" : "minor"
if age>18
    "adult"
else
    "minor"
end
function plusOne(x)
    return x+1
end
function minusOne(x)
    return x-1
end
if age >10
    plusOne(age)
else
    minusOne(age)
end


# Unicode variable names
Δ=0.1
β=0.8
γ=0.6
α=0.5
π=3
r=5
Base.π
area=Base.π*r^2



# nothing  → no meaningful value
# missing  → value is unknown

# parse()  → String → Number
# Int()    → convert to Integer
# Float64() → convert to Float64
# string() → value → String

# const    → constant binding
# a, b = 1, 2 → multiple assignment
# ? :      → short if/else
# Unicode  → Δ, α, β, π, etc.