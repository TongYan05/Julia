# # REPL -> read eval print loop in the terminal
# #%%
# println("hello")
# println("from")
# println("TechyTok!")
# #%%
# my_name="Yan Tong"
# my_favorite_pie=3.1415926
# my_favorite_number=55
# print(my_name)
# a=2
# b=3
# sum=a+b
# difference=a-b
# product=a*b
# quotient=b/a
# power=a^3
# modulus=b%a
# typeof(0.1)
# typeof(54)
# typeof("i do not know")
# typeof(true)
# c=2.0
# a==2
# c==convert(Float64,a)
# print(typeof(a)," ",a)# the value of did not change
# function change_number(x)
#     return x +100
# end
# change_number(a)
# a
# g(a,b,c)=a+b+c
# g(1,2,3)
# function weight(w,divider=4)
#     return w/4*divider
# end
# weight(100)
# weight(100,10)


# function myWeight(weightOnEarth, g=9.81)
#     return weightOnEarth*g/9.81
# end
# myWeight(60)
# myWeight(60, 3.72)

# #position arguments and keyword arguments(after ;)
# function sum1(x,y,z=2;m=4,n)
#     return x+y+z+m+n
# end
# sum1(1,n=20,3,2,m=4)
# sum1(1,2,n=3)
# #?sum1 in the terminal
# plus_two(x)=x+2
# x=plus_two(10)
# println(x)
# plus_one=x->x+1
# plus_one(90)# the use is general usage

# using Pkg
# Pkg.add("QuadGK")
# using QuadGK # used to numerial integration
# f(x,y,z) = (x^2 + 2y)*z
# quadgk(x->f(x,42,4), 3, 4) 
# #∫₃⁴f(x,42,4)dx -> cannot execute it in the coding area
# #∫ -> julia Unicode input  
# # %%
# x=8 
# y=9
# x+y
# # %%
# x+y # this is julia code cell, which does not means forget everythng in the file but execute seperately
# # %%
# # array contains many  vector elements
# a=[1,1,2,3,4,5,4,56,7,54,2,2,4,6,6,66,7,]
# b=[1.2,3,5, 6,4454,    63]
# c=["ja","rge","ft",  'e','Y']
# a[1]
# length(b); b[6]
# c[5]
# d=c
# d[5]
# d==c
# d==a
# append!(a,1000)
# a # after append(a,1000), the original array has changed
# append!(c,"yan") # cannot append!() a vector element with different type
# c
# d # d also changed
# append!(a,1.2)
# append!(b,2.4)
# b
# typeof(a)
# typeof(b)
# typeof(c)
# e=['w','w']
# typeof(e)
# append!(e,"gfd") # g d f appended 3 vector elements
# f1=["g","t"]
# typeof(f1)
# #f=["g","t","u"] # cannot modify after create it
# push!(f1,"u")
# f1
# a2=[1 2 3;4 5 6; 7 8 9]
# a3=[2:3,2:3]
# a4=[i for i in 1:16]
# for i in 1:19
#     print(i)
# end
# a5=[1  2;3 4]
# a6=[(i,j,k) for i in 1:10 for j in 1:10 for k in 1:10]
# a7=[i+j for i in 1:2 for j in 1:10]
# a8=(1,2,3,4)
# a9=1,2,3,3
# a10=(x="Yan Tong",y=21)
# m,j,k,we=a8 # unpacking
# m
# j
# k


mystring1="hello world"
mystring1="hello world
"
mystring1="hello world"
println(mystring1)

"Yan"*" Tong"
x,y,z="java","julia","python"
x*y*z
(x*y)^5
x*y^5
'a'
