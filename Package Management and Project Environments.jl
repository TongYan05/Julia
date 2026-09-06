#=
julia package is not something that you import
julia has a project/environment system that controls which
packages and versions your progeam uses

julia's  REPL has different mode
julia> is the most common one
] -> press ] make it (@v1.12) pkg>, which means
I am in Pkg mode (julia's built-in package manager)

(@v1.12) pkg> add Plots  -> install Plots
(@v1.12) pkg> rm Plots  -> remove a package
(@v1.12) pkg> update Plots -> update packages
(@v1.12) pkg> status  -> see the package in your current environment

what is a project environment?
A controlled package environment associated
with a particular project

Project.toml -> describe the project's dependencies
It looks like 
[deps]
Plots = "91a5bcdd-0dac-4021-8356-623f3037d0c1"
QuadGK = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
Revise = "295af30f-e4ad-537b-8983-00126c2a3abe"
how to update the Project.toml?
(@v1.12) pkg> add + the name of dependencies you need

Manifest.toml -> Record the exact dependencies(like version)

(@v1.12) pkg> activate . -> activate the environment in this project
add Plots
add CSV
add dependencies according to your requires
status -> check the dependencies you have downloaded in the project environment

Reproducing someone else's project -> instantiate
magine your professor gives you a research repository:
ResearchProject/
├── Project.toml
├── Manifest.toml
├── src/
└── data/
work flow:
git clone
cd ResearchProject
julia
(@v1.12) pkg>
(@v1.12) pkg> activate .
(@v1.12) pkg> instantiate -> strictly download the dependencies according to the Manifest.toml


A realistic research example
Imagine your professor has a numerical simulation project.
The repository contains:
NeuralFEM/
├── Project.toml
├── Manifest.toml
├── src/
│   ├── model.jl
│   ├── solver.jl
│   └── training.jl
└── README.md
The Project.toml might specify:
LinearAlgebra
Statistics
IterativeSolvers
Plots
You clone it.
Then:
cd NeuralFEM
julia
Inside Julia:
] activate .
] instantiate
Then:
include("src/model.jl") -> execute all the code in the file
The important thing is:
You don't need to manually install every package.
The environment describes what the project needs.

Common scientific-computing packages
LinearAlgebra:
It provides linear algebra functionality such as:
- vectors
- matrices
- norms
- matrix decompositions
- eigenvalues
- factorizations

Statistics:
std(...)
var(...)
median(...)


Plots: Visualization:

CSV: Reading/writing CSV data: data = CSV.read("data.csv", DataFrame)

JSON: Useful when exchanging structured data between systems.



IterativeSolvers 

Version Fix and Reproducibility
Suppose today you run:
using SomePackage
and your code works.
Six months later, the package releases:
v2.0
and changes some behavior.
You run your old research code again.
It might fail.
Or worse:
It runs, but produces different results.

That's much more dangerous.
16. pin
Julia's package manager allows you to pin a package.
Conceptually:
] pin SomePackage
This tells Julia:
Don't freely update this package.

You might encounter syntax such as:
] pin SomePackage@1.5.2
The important idea isn't memorizing the exact syntax.
The important idea is:
normal dependency
      ↓
can move within compatible versions

pinned dependency
      ↓
hold this package at a particular version



19. The complete workflow you should know
For your level, I would memorize this workflow.
Starting a new Julia project
mkdir MyProject
cd MyProject
julia
Then:
] activate .
Add dependencies:
] add Plots CSV
Check them:
] status
Your project now contains:
MyProject/
├── Project.toml
└── Manifest.toml
Then your Julia code can simply do:
using Plots
using CSV
Working on someone else's Julia project
cd TheirProject
julia
Then:
] activate .
] instantiate
Now you have the environment required by that project.

=#
using Plots
plot([1,2,3],[4,-1,3])
import LinearAlgebra
LinearAlgebra.norm([3,4])
x=1:0.01:3
y=x.^2
plot(x,y)
z=sin.(x)
plot(x,z)

scatter(x,y)
