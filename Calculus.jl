#=
Derivative(导数) -> describe instantaneous rate of change of a function
f'(x) -> the slope of the tangent line(切线)

Basic Differentiation Rules(基本求导公式)
power rule -> dxⁿ/dx = nxⁿ⁻¹
exponential /ˌekspəˈnenʃl/ function -> deˣ/dx = eˣ
dsinx/dx = cosx
dcosx/dx = -sinx
natraul logarithm dlnˣ/dx = 1/x (x > 0)

Product Rule(乘积法则)
f(x) = v(x)u(x) -> f'(x) = v'(x)u(x) + v(x)u'(x)
differentiate the first factor while keep the second, then differentiate the second factor while keep the first

Chain Rule(链式法则)
y = f(g(x)) -> y' = f'(g(x))g'(x)

Partial Derivative(偏导数)
f(x,y) = x² + 3xy + y² -> ∂f(x,y)/∂x = 2x + 3y -> treat all variable as constant except x

Gradient(梯度) /ˈɡreɪdiənt/
u(x,k) -> ∇u = [uₓ,uₖ] -> ∇u is the length of gradiant
the direction of gradiant is the direction of maximum slope of the function, while its value is the value of the maximum slope

Divergence(散度)
F=(F₁,F₂,F₃) -> Divergence: ∇⋅F=∂F₂/∂1 + ∂F₁/∂2 +∂F₃/∂3
∇F is a scalar(标量) without direction

Curl(旋度)
∇×F(Fx,Fy,Fz)= [∂Fz/∂y - ∂Fy/∂z, ∂Fx/∂z - ∂Fz/∂x, ∂Fy/∂x - ∂Fx/∂y]
∇×F is a vector(向量)

Laplacian(拉普拉斯算子 /ləˈplɑːsiən/) -> it will appear in Poisson equation（泊松方程)
∇²u = ∇⋅(∇u) -> laplacian is the divergence of the gradiant
EXAMPLE:
设 u(x, y, z) = x^2y + y^2z + z^2x

第一步：求梯度 ∇u
∇u = (∂u/∂x, ∂u/∂y, ∂u/∂z)
∂u/∂x = 2xy + z^2
∂u/∂y = x^2 + 2yz
∂u/∂z = y^2 + 2zx
∇u = (2xy + z^2, x^2 + 2yz, y^2 + 2zx)

第二步：求散度 ∇⋅(∇u)
∇⋅(∇u) = ∂/∂x(2xy + z^2) + ∂/∂y(x^2 + 2yz) + ∂/∂z(y^2 + 2zx)
∂/∂x(2xy + z^2) = 2y
∂/∂y(x^2 + 2yz) = 2z
∂/∂z(y^2 + 2zx) = 2x

第三步：相加得出 ∇²u
∇²u = 2y + 2z + 2x



Gauss's theorem（高斯定理）

Green's First Identity 格林第一恒等式/ɡriːnz fɜːrst aɪˈdentəti/
​【格林第一恒等式与分部积分公式解释】

1. 一维分部积分公式 Integration by Parts
公式：∫ u · v' dx = [u · v] - ∫ u' · v dx

2. 格林第一恒等式（Green's First Identity）
公式：∫_Ω (∇u · ∇v) dΩ = ∫_∂Ω v (∂u/∂n) dΓ - ∫_Ω v (∇²u) dΩ
核心本质：多维版本的分部积分。当计算空间从一维线段升级到三维立体空间时，普通的导数变成了梯度（∇）和拉普拉斯算子（∇²），一维的端点边界变成了立体的表面边界（∂Ω）。

3. 物理与工程意义
格林第一恒等式本质上是一个“超级翻译官”。在现实物理问题（如热传导、电磁场）中，我们往往只知道边界条件（如外壳表面的温度或电势），而内部变化极其复杂。该公式允许我们将“内部极难计算的体积积分”，巧妙地转化为“外壳表面的边界积分”，从而大幅简化偏微分方程的求解过程。

Poisson equation（泊松方程） -> -∇²u=f
/ˈpwɑːsɒn ɪˈkweɪʒən/

Indefinite Integral(不定积分)
∫x²dx = x³/3 + C 

Definite Integral(定积分)
∫₀¹ x²dx = ∫₀¹ x³/3 = 1/3

Multiple Integral(重积分)
∫_Ω f(x,y)dA
EXAMPLE:
∫∫_Ω (x + y) dA = ∫₀¹ ∫₀² (x + y) dy dx

内层积分（对 y，x 视为常数）：
∫₀² (x + y) dy = [xy + y²/2]₀² = (2x + 2) - 0 = 2x + 2

外层积分（对 x）：
∫₀¹ (2x + 2) dx = [x² + 2x]₀¹ = (1 + 2) - 0 = 3

最终结果：3

=#



using Pkg
Pkg.add("ForwardDiff")
using ForwardDiff



f(x) = x^3 - 2x +1
ForwardDiff.derivative(f,2)
g(x,y)=x^2+3x*y+y^5
x=1
y=1
dg_dx=ForwardDiff.derivative(m->g(m,y),x)
dg_dy=ForwardDiff.derivative(m->g(x,m),y)


x=[1.0,2.0]
k(x)=x[1]^2+3x[1]*x[2]+x[2]^2
ForwardDiff.gradient(k,x)

x1=[3.6;4.9;5.0]
B(x)=[x[1]^2*x[3];3*x[1]*x[2];x[3]^4]
ForwardDiff.jacobian(B,x1)
tr(ForwardDiff.jacobian(B,x1))
# tr -> trace(迹) -> the sum of diagonal elements(对角元素)

 # ∫x²dx
using QuadGK
f(x) = x^2
result, error = quadgk(f, 0, 1)
println(result) # Integral value
println(error) # error estimate
1/3==result


using Cubature
t(v)=3v[1]^3+2v[1]^2*v[2]^4-7v[2]^3*v[1]^2+11v[2]^2
hcubature(t,[0,2],[10,8])

m(n)=n[1]^2+n[2]^2+n[3]^2
hcubature(m,[0,0,0],[1,1,1])