# 0. What is Plots.jl?
# Plots.jl is a julia plotting package
# plot(....) -> create a plot , while scatter(....) -> create scatter plot
# heatmap(....) -> create heatmap
# the most basic pattern plot(x_data,y_data)

# 1. Install and import Plots.jl
using Plots # after using Plots, we can directly write plot(), scatter(), heatmap(), savefig(), without a module prefix

# 2. Plot a mathematical function
# x is collection of 500 coordinate points evenly distributed from 0 to 2π
x=range(0,2π,length=500)
plot(x,sin.(x))
plot(x1->sin(x1),0,4π)
plot(x2->x2^2,0,100)
f(a, b, c) = x -> a*x^2 + b*x + c
plot(f(24,52,13),-10,10)

# 3. Plot existing data
x3=1:2:100
typeof(x3)
# . means apply this operation element by element
y=x3.^2
plot(x3,y)

# 4. Scatter plots
scatter(x3,y)
a=1:0.1:10
b=ifelse.(a.>5 , a.-100 , a.^2)
scatter(a,b)

# 5. Adding another curve with plot! -> modify the current existing plot istead of creating a new one
a1 = 1:10
b1 = a1.^2
b2 = a1.^3
b3 = sqrt.(a1)
plot(a1,b1)
plot!(a1,b2)
plot!(a1,b3)


# 6. Plot multiple curves at once
m=0:0.1:2π
n1=50sin.(m)
n2=50cos.(m)
n3=tan.(m)
plot(m,[n1 n2 n3],label=["sin" "cos" "tan"])

# 7. Titles, axis labels, and legends
f1(x)=28x^2-54x-46
m1=1:100
plot(
    m1,
    f1.(m1),
    title="binary quadratic function",
    xlabel="X",
    ylabel="F(X)",
    label="F(X)=28X^2+54X-46"
)
plot!(
    m1,
    m1.^50,
    title="My Plot",
    xlabel="x",
    ylabel="y",
    label="y = x^50"
)
plot(
    m1,
    f1.(m1),
    title="binary quadratic function",
    xlabel="X",
    ylabel="F(X)",
    legend=:topleft, # the position of label
    label="F(X)=28X^2+54X-46"
)
plot(
    m1,
    f1.(m1),
    title="binary quadratic function",
    xlabel="X",
    ylabel="F(X)",
    legend=false, # can also disable legend
    label="F(X)=28X^2+54X-46"
)

# 8. Log-log plots — very important for your future work
h = [0.1, 0.05, 0.025, 0.0125]
err = [0.01, 0.0025, 0.000625, 0.00015625]
plot(h, err, xaxis=:log10, yaxis=:log10)
# xaxis=:log10 -> means set the x-aixs sacle to logarithmic base 10

# 9. Why log-log plots matter for convergence
#=
Suppose your numerical error behaves like:

E(h) = C h^p
where:
- E = error
- h = mesh size / step size
- C = some constant
- p = convergence order
Take log10 of both sides:
log_{10}E=log_{10}C+plog_{10}h
This transforms the power law(幂率) into a straight line.
So on a log-log plot:
plot(h, err, xaxis=:log10, yaxis=:log10)
the slope of the line corresponds to the convergence order p.
这条直线的斜率即代表收敛阶p
=#

# 10. Heatmaps
A=rand(10,10)
heatmap(A)
D=zeros(200,1000)
for i in 1:1000
    D[:, i]=rand(200)
end
heatmap(D)


# 11. Subplots
x=[z.^2 for z in 1:10]
p1=plot(x.^2,1:10)
p2=plot(x.*2,1:10)
plot(p1,p2,layout=(1,2))
# layout=(1,2) -> there are two plots, arrange them in 1 row 2 column

# 12. Saving a figure(pdf or png)
savefig(heatmap(D),"C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/D_heatmap.pdf")


# 13. Your required exercise
using Plots
x=0:0.05:5
y=x.^2
y1=x.^3
plot(y,title="comparison",xlabel="x",ylabel="f(x)",legend=:topleft)
plot!(y1)
savefig("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/comparison.pdf")