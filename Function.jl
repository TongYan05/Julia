# Defining a Function
function add(a,b)
    a+b
end # the last expression automatically return
a=add(3,56)
a


# One-Line Function Definition
add_shorter(x,y)=x + y
b=add_shorter(16,82)
square(x)=x^2
square(8)


# Multiple Return Values
function get_coordination(x,y)
    return x^2,y^3
end
c,d=get_coordination(2,3)# this called tuple unpacking
c
d
a1,_=get_coordination(7,9)
a1


# Default Arguments
function greet(name="World") # world is default value
    println("Hello, ", name)
end
greet()
name="java"
greet(name)
greet("julia")
function power(x,n=4)
    x^n
end
power(2)
power(7,1)


# Keyword Arguments
function plot(x; color="blue") # x is postional argument and color is keyword argument
    println("color = ", color)
end
plot(3)
plot(3,color="balck") # keyword arguent must be declared by name


# Anonymous Functions(without a name)
f=g->g^2+5
f(6)
m->m^7


# map -> apply this function to every element
arr=[5,46,488,5,1,6,1,5,6,1,61,6,5,563,5]
arr1=map(x->x-1000,arr)
arr
arr1
arr2=map(square,arr) # also use a name of function
arr2


# filter(map transform elements, filter select elements)
arr3=filter(x->x%2==0,arr)
arr3
arr
arr4=filter(x->x>100,arr)


# do Block Syntax("a"->append,"w"-> rewrite all)
open("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt","a") do io
    println(io,"julia, java")
end
open("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt","w") do io
    println(io,"YanTong")
end


# Variable-Length Arguments: ...
arr5=[5,9,4,3,7,9]
function add1(a,b,c,d,e,f)
    return a+b+c+d+e+f
end
add1(arr5...) # this called splatting(...)


# The opposite: collecting arguments
function add_all(x...)
    sum(x)
end
add_all(arr5...)
add_all(1, 2, 3, 4)
add_all([1, 2, 3, 4]...)
sum([5,1,96,1,48,46,4,16,4,6,16,]) # sum() is built-in function can only accept a collection


# Multiple Dispatch(:: -> means convert and assert)
function greet(x::String)
    println("Hello, ", x)
end
function greet(x::Int)
    println("The number is ", x)
end
greet("Alice")
greet(42)
function combine(x::Int, y::String)
    print(y," is ",x," years old")
end
function combine(x::Int, y::Int)
    print(y," and ",x," are Int")
end
combine(21,"Yan Tong")
combine(21,53)


# Type Annotations ::
function area(r::Float64)
    π * r^2
end
area(2.5)
area(2) # error because r must be Float64
function area(r::Int64)
    π * r^2
end
area(2)


# Recursion
function fib(x)
    if x == 0
        0
    else 
        x + fib(x-1)
    end
end
fib(10)


# Quadratic Equation Exercise 2*a==2a they are the same
# Suppose we want to solve: ax^2 + bx + c = 0
# The discriminant is: Δ = b^2 - 4ac
function quadratic_formula(a,b,c) # 求根公式
    println("the quadratic formula is: ",a,"x^2 + ",b,"x + ",c," = 0")
    Δ=b^2-4*a*c
    x1=(-b+√Δ)/(2a)
    x2=(-b-√Δ)/(2a)
    x3=-b/(2*a)
    if Δ>0
        println("the two roots are ",x1," ",x2)
    elseif Δ==0
        println("the root is ",x3)
    else
        println("there is no real root")
    end
end
quadratic_formula(1,-5,6)