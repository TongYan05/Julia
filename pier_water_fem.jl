# ============================================================
# 桥墩水流荷载：Gridap 三维有限元分析
#
# 保存为 pier_water_fem.jl，运行整个文件。
#
# 输出目录：water_fem_results
#   01_mesh_and_load.png   三维网格及迎水面载荷
#   02_water_response.png  单独水流荷载的响应云图
#   03_combined_response.png  水流+桥面荷载+自重的云图
#   water_only*.vtu       水流荷载三维结果
#   combined*.vtu         组合荷载三维结果
#   upstream_load*.vtu    迎水面等效水流载荷
#   mesh*.vtu             网格及边界标签
#   water_samples.csv     水流工况截面采样结果
#   combined_samples.csv  组合工况截面采样结果
#   summary.txt           参数、合力及计算结果
#
# 单位：m、N、Pa。
#
# 模型说明：
# 1. 桥墩尺寸与前面的示例一致：3 × 4 × 12 m。
# 2. 水流沿 +Y 方向，迎水面为 Y=-2 m。
# 3. 水流净阻力用 0.5*rho*Cd*v^2 等效施加到迎水面。
#    这是净阻力的等效分布，不是真实绕流壁面压力。
# 4. 底部完全固定，桥墩采用混凝土三维线弹性模型。
# 5. 单独计算水流工况，以及包含桥面竖向荷载和自重的组合工况。
# 6. 不包含水流场、瞬态冲击、冲刷、开裂、钢筋或地基变形。
# 7. Von Mises 云图用于描述应力，不作为混凝土破坏判据。
#
# Gridap 官方参考：
# https://gridap.github.io/Tutorials/stable/pages/t003_elasticity/
# ============================================================

ENV["JULIA_NUM_PRECOMPILE_TASKS"] = "1"

import Pkg

environment_dir = joinpath(@__DIR__, "bridge_environment")
Pkg.activate(environment_dir)

# 已安装时不会重复添加包
required_packages = ["Gridap", "CairoMakie"]
missing_packages = [
    name for name in required_packages
    if !haskey(Pkg.project().dependencies, name)
]

if !isempty(missing_packages)
    Pkg.add(missing_packages)
else
    Pkg.instantiate()
end


# 放在模块中，避免之前 REPL 的变量影响本次计算
module PierWaterFEM

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs: get_node_coordinates, get_face_nodes
using LinearAlgebra
using Printf
import CairoMakie as CM


# ==================== 可修改参数 ====================

const WIDTH = 3.0                  # X 方向宽度
const DEPTH = 4.0                  # Y 方向厚度
const HEIGHT = 12.0                # 桥墩高度

const WATER_DEPTH = 4.0            # 水深
const FLOW_SPEED = 3.0             # 水流速度，m/s
const WATER_DENSITY = 1000.0       # kg/m³

# 示例系数，实际应按桥墩形状、流向和试验/规范确定
const DRAG_COEFFICIENT = 1.6

const YOUNG_MODULUS = 32.0e9       # 混凝土弹性模量，Pa
const POISSON_RATIO = 0.20
const CONCRETE_DENSITY = 2500.0
const GRAVITY = 9.81

# 只影响组合工况；水流单独工况不包含此项
const DECK_VERTICAL_FORCE = 12.0e6 # 顶部向下 12 MN

# 网格参数：水位必须与某一水平网格层重合
# 例如高度12、水深4、NZ=24，水位正好位于第8层
const NX = 6
const NY = 8
const NZ = 24

const OUTPUT_DIR = joinpath(@__DIR__, "water_fem_results")


# ==================== 边界标记 ====================

function tag_plane!(model, name, direction, coordinate)
    labels = get_face_labeling(model)
    nodes = get_node_coordinates(model)
    entities = Int[]

    # 同时标记面、边和顶点，确保固定底面包含边界节点
    for dimension in 0:2
        face_nodes = get_face_nodes(model, dimension)
        face_entities = get_face_entity(labels, dimension)

        for face_id in eachindex(face_entities)
            on_plane = all(
                abs(nodes[node_id][direction] - coordinate) < 1e-8
                for node_id in face_nodes[face_id]
            )

            if on_plane
                push!(entities, face_entities[face_id])
            end
        end
    end

    isempty(entities) && error("Boundary not found: $name")
    add_tag!(labels, name, unique(entities))
end


# ==================== 水流荷载 ====================

function water_pressure(x)
    z = x[3]

    if 0.0 <= z <= WATER_DEPTH
        return 0.5 * WATER_DENSITY *
               DRAG_COEFFICIENT * FLOW_SPEED^2
    end

    return 0.0
end

water_traction(x) = VectorValue(0.0, water_pressure(x), 0.0)

# 底面中心位于迎水面后方 DEPTH/2。
# 沿 +Y 的力对底面中心产生 -X 方向弯矩。
water_moment_x(x) = -x[3] * water_pressure(x)


# ==================== 应力计算 ====================

function von_mises(s)
    return sqrt(
        0.5 * (
            (s[1, 1] - s[2, 2])^2 +
            (s[2, 2] - s[3, 3])^2 +
            (s[3, 3] - s[1, 1])^2
        ) +
        3.0 * (
            s[1, 2]^2 + s[2, 3]^2 + s[3, 1]^2
        )
    )
end


# ==================== 网格和载荷展示 ====================

function plot_mesh_and_load()
    fig = CM.Figure(size=(1450, 900), backgroundcolor="#f3f6fa")

    ax = CM.Axis3(
        fig[1, 1];
        title="3D FE mesh | fixed base | flow along +Y",
        xlabel="X / m",
        ylabel="Y / m",
        zlabel="Z / m",
        aspect=:data,
        azimuth=0.72pi,
        elevation=0.13pi
    )

    xx = collect(range(-WIDTH / 2, WIDTH / 2; length=NX + 1))
    yy = collect(range(-DEPTH / 2, DEPTH / 2; length=NY + 1))
    zz = collect(range(0.0, HEIGHT; length=NZ + 1))

    # 四个竖直外表面的网格线
    for y in (-DEPTH / 2, DEPTH / 2)
        for x in xx
            CM.lines!(
                ax, [x, x], [y, y], [0.0, HEIGHT];
                color="#536c85", linewidth=1
            )
        end

        for z in zz
            CM.lines!(
                ax, [-WIDTH / 2, WIDTH / 2], [y, y], [z, z];
                color="#536c85", linewidth=1
            )
        end
    end

    for x in (-WIDTH / 2, WIDTH / 2)
        for y in yy
            CM.lines!(
                ax, [x, x], [y, y], [0.0, HEIGHT];
                color="#536c85", linewidth=1
            )
        end

        for z in zz
            CM.lines!(
                ax, [x, x], [-DEPTH / 2, DEPTH / 2], [z, z];
                color="#536c85", linewidth=1
            )
        end
    end

    # 顶面和底面的网格线
    for z in (0.0, HEIGHT)
        for x in xx
            CM.lines!(
                ax, [x, x], [-DEPTH / 2, DEPTH / 2], [z, z];
                color="#536c85", linewidth=1
            )
        end

        for y in yy
            CM.lines!(
                ax, [-WIDTH / 2, WIDTH / 2], [y, y], [z, z];
                color="#536c85", linewidth=1
            )
        end
    end

    # 底部固定边界
    CM.lines!(
        ax,
        [-WIDTH / 2, WIDTH / 2, WIDTH / 2, -WIDTH / 2, -WIDTH / 2],
        [-DEPTH / 2, -DEPTH / 2, DEPTH / 2, DEPTH / 2, -DEPTH / 2],
        zeros(5);
        color="#d44b43", linewidth=5
    )

    # 水位线
    CM.lines!(
        ax,
        [-WIDTH / 2, WIDTH / 2, WIDTH / 2, -WIDTH / 2, -WIDTH / 2],
        [-DEPTH / 2, -DEPTH / 2, DEPTH / 2, DEPTH / 2, -DEPTH / 2],
        fill(WATER_DEPTH, 5);
        color="#159ec0", linewidth=4
    )

    # 流向箭头：由线段构成
    for z in range(0.5, WATER_DEPTH - 0.5; length=4)
        for x in (-0.9, 0.0, 0.9)
            y_start = -DEPTH / 2 - 2.0
            y_end = -DEPTH / 2 - 0.15

            CM.lines!(
                ax, [x, x], [y_start, y_end], [z, z];
                color="#188fae", linewidth=2
            )

            CM.lines!(
                ax,
                [x - 0.12, x, x + 0.12],
                [y_end - 0.3, y_end, y_end - 0.3],
                [z, z, z];
                color="#188fae", linewidth=2
            )
        end
    end

    # 迎水面等效载荷云图
    ax2 = CM.Axis(
        fig[1, 2];
        title="Equivalent net drag on upstream face",
        xlabel="X / m",
        ylabel="Z / m",
        aspect=CM.DataAspect()
    )

    x_edges = collect(range(-WIDTH / 2, WIDTH / 2; length=NX + 1))
    z_edges = collect(range(0.0, HEIGHT; length=NZ + 1))

    x_centers = (x_edges[1:end-1] .+ x_edges[2:end]) ./ 2
    z_centers = (z_edges[1:end-1] .+ z_edges[2:end]) ./ 2

    pressures = [
        water_pressure(Gridap.Point(x, -DEPTH / 2, z)) / 1000.0
        for x in x_centers, z in z_centers
    ]

    hm = CM.heatmap!(
        ax2, x_edges, z_edges, pressures;
        colormap=:Blues
    )

    CM.hlines!(
        ax2, [WATER_DEPTH];
        color="#d45737", linestyle=:dash, linewidth=2
    )

    CM.Colorbar(fig[1, 3], hm; label="Equivalent drag traction / kPa")

    CM.Label(
        fig[2, 1:3],
        @sprintf(
            "Mesh: %d × %d × %d hexahedra | water depth %.1f m | velocity %.1f m/s",
            NX, NY, NZ, WATER_DEPTH, FLOW_SPEED
        );
        fontsize=17
    )

    CM.save(joinpath(OUTPUT_DIR, "01_mesh_and_load.png"), fig)
    return fig
end


# ==================== 云图及数据输出 ====================

function export_response(Ω, uh, stress_function, name, figure_name)
    strain_h = ε(uh)
    stress_h = stress_function ∘ strain_h

    writevtk(
        Ω, joinpath(OUTPUT_DIR, name);
        cellfields=[
            "displacement_m" => uh,
            "displacement_magnitude_m" => norm ∘ uh,
            "strain" => strain_h,
            "stress_Pa" => stress_h,
            "sigma_zz_Pa" => (s -> s[3, 3]) ∘ stress_h,
            "von_mises_Pa" => von_mises ∘ stress_h
        ]
    )

    # Y-Z 中间截面，可以观察水流方向弯曲。
    # 稍微偏离 X=0 和网格边界，避免点定位歧义。
    ys = collect(range(-DEPTH / 2 + 1e-6, DEPTH / 2 - 1e-6;
                       length=41))
    zs = collect(range(1e-6, HEIGHT - 1e-6; length=91))

    sample_points = [
        Gridap.Point(1e-6, y, z)
        for y in ys, z in zs
    ]

    us = uh.(vec(sample_points))
    ss = stress_h.(vec(sample_points))

    ny, nz = length(ys), length(zs)

    displacement_mm = reshape(
        [1000.0 * norm(u) for u in us], ny, nz
    )
    flow_displacement_mm = reshape(
        [1000.0 * u[2] for u in us], ny, nz
    )
    sigma_zz_mpa = reshape(
        [s[3, 3] / 1e6 for s in ss], ny, nz
    )
    vm_mpa = reshape(
        [von_mises(s) / 1e6 for s in ss], ny, nz
    )

    uy = reshape([u[2] for u in us], ny, nz)
    uz = reshape([u[3] for u in us], ny, nz)

    open(joinpath(OUTPUT_DIR, name * "_samples.csv"), "w") do io
        println(
            io,
            "x_m,y_m,z_m,ux_m,uy_m,uz_m,displacement_mm,sigma_zz_MPa,von_mises_MPa"
        )

        for (p, u, s) in zip(vec(sample_points), us, ss)
            @printf(
                io,
                "%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e\n",
                p[1], p[2], p[3],
                u[1], u[2], u[3],
                1000.0 * norm(u),
                s[3, 3] / 1e6,
                von_mises(s) / 1e6
            )
        end
    end

    fig = CM.Figure(size=(1600, 1100), backgroundcolor="#f5f7fa")

    CM.Label(
        fig[0, 1:4],
        name == "water_only" ?
        "WATER LOAD ONLY | 3D PIER RESPONSE" :
        "WATER + DECK LOAD + SELF-WEIGHT | 3D PIER RESPONSE";
        fontsize=24
    )

    ax1 = CM.Axis(
        fig[1, 1];
        title="Displacement magnitude",
        xlabel="Y / m", ylabel="Z / m",
        aspect=CM.DataAspect()
    )
    h1 = CM.heatmap!(
        ax1, ys, zs, displacement_mm; colormap=:viridis
    )
    CM.Colorbar(fig[1, 2], h1; label="Displacement / mm")

    ax2 = CM.Axis(
        fig[1, 3];
        title="Vertical stress: negative = compression",
        xlabel="Y / m", ylabel="Z / m",
        aspect=CM.DataAspect()
    )

    stress_range = maximum(abs.(sigma_zz_mpa))
    stress_range = max(stress_range, 1e-9)

    h2 = CM.heatmap!(
        ax2, ys, zs, sigma_zz_mpa;
        colormap=:balance,
        colorrange=(-stress_range, stress_range)
    )
    CM.Colorbar(fig[1, 4], h2; label="sigma_zz / MPa")

    ax3 = CM.Axis(
        fig[2, 1];
        title="Von Mises stress",
        xlabel="Y / m", ylabel="Z / m",
        aspect=CM.DataAspect()
    )
    h3 = CM.heatmap!(ax3, ys, zs, vm_mpa; colormap=:inferno)
    CM.Colorbar(fig[2, 2], h3; label="Von Mises / MPa")

    maximum_sampled_displacement = maximum(displacement_mm)
    scale = maximum_sampled_displacement > 0 ?
            700.0 / maximum_sampled_displacement : 1.0

    ax4 = CM.Axis(
        fig[2, 3:4];
        title=@sprintf("Y-Z deformation × %.0f", scale),
        xlabel="Y / m", ylabel="Z / m",
        aspect=CM.DataAspect()
    )

    # 未变形轮廓
    CM.lines!(
        ax4,
        [-DEPTH / 2, DEPTH / 2, DEPTH / 2, -DEPTH / 2, -DEPTH / 2],
        [0.0, 0.0, HEIGHT, HEIGHT, 0.0];
        color="#8392a5", linestyle=:dash, linewidth=2
    )

    # 放大后的截面网格
    for i in 1:5:ny
        CM.lines!(
            ax4,
            ys[i] .+ scale .* uy[i, :],
            zs .+ scale .* uz[i, :];
            color="#d37835", linewidth=1.5
        )
    end

    for j in 1:9:nz
        CM.lines!(
            ax4,
            ys .+ scale .* uy[:, j],
            zs[j] .+ scale .* uz[:, j];
            color="#d37835", linewidth=1.5
        )
    end

    CM.hlines!(
        ax4, [WATER_DEPTH];
        color="#159ec0", linestyle=:dot
    )

    CM.Label(
        fig[3, 1:4],
        "Mid-section samples, without stress smoothing. Deformation is exaggerated.\n" *
        "Fixed-base stress peaks may be mesh-sensitive; Von Mises is not a concrete failure criterion.";
        fontsize=15
    )

    CM.save(joinpath(OUTPUT_DIR, figure_name), fig)

    return (
        figure=fig,
        max_sampled_displacement_mm=maximum_sampled_displacement,
        max_sampled_flow_displacement_mm=maximum(abs.(flow_displacement_mm)),
        min_sampled_sigma_zz_mpa=minimum(sigma_zz_mpa),
        max_sampled_sigma_zz_mpa=maximum(sigma_zz_mpa),
        max_sampled_vm_mpa=maximum(vm_mpa)
    )
end


# ==================== 主程序 ====================

function main()
    @assert WIDTH > 0 && DEPTH > 0 && HEIGHT > 0
    @assert 0 < WATER_DEPTH < HEIGHT
    @assert FLOW_SPEED > 0
    @assert DRAG_COEFFICIENT > 0
    @assert YOUNG_MODULUS > 0
    @assert -1 < POISSON_RATIO < 0.5

    water_layer = WATER_DEPTH / HEIGHT * NZ
    @assert isapprox(water_layer, round(water_layer); atol=1e-8) """
    水位必须与水平网格层重合。
    请调整 WATER_DEPTH 或 NZ，使 WATER_DEPTH/HEIGHT*NZ 为整数。
    """

    mkpath(OUTPUT_DIR)
    CM.activate!()

    println("1/5 Creating mesh and boundary conditions ...")

    model = CartesianDiscreteModel(
        (-WIDTH / 2, WIDTH / 2,
         -DEPTH / 2, DEPTH / 2,
         0.0, HEIGHT),
        (NX, NY, NZ)
    )

    tag_plane!(model, "fixed_base", 3, 0.0)
    tag_plane!(model, "deck_top", 3, HEIGHT)
    tag_plane!(model, "upstream", 2, -DEPTH / 2)

    writevtk(model, joinpath(OUTPUT_DIR, "mesh"))

    reffe = ReferenceFE(lagrangian, VectorValue{3, Float64}, 1)

    V = TestFESpace(
        model, reffe;
        conformity=:H1,
        dirichlet_tags="fixed_base"
    )
    U = TrialFESpace(V, VectorValue(0.0, 0.0, 0.0))

    Ω = Triangulation(model)
    Γwater = BoundaryTriangulation(model; tags="upstream")
    Γtop = BoundaryTriangulation(model; tags="deck_top")
    Γbase = BoundaryTriangulation(model; tags="fixed_base")

    dΩ = Measure(Ω, 2)
    dΓwater = Measure(Γwater, 2)
    dΓtop = Measure(Γtop, 2)
    dΓbase = Measure(Γbase, 2)

    @assert isapprox(
        sum(∫(1.0) * dΓwater), WIDTH * HEIGHT; rtol=1e-8
    )
    @assert isapprox(
        sum(∫(1.0) * dΓtop), WIDTH * DEPTH; rtol=1e-8
    )
    @assert isapprox(
        sum(∫(1.0) * dΓbase), WIDTH * DEPTH; rtol=1e-8
    )

    # 将空间函数转换为边界上的有限元场
    pwater = CellField(water_pressure, Γwater)
    twater = CellField(water_traction, Γwater)
    mxwater = CellField(water_moment_x, Γwater)

    writevtk(
        Γwater, joinpath(OUTPUT_DIR, "upstream_load");
        cellfields=[
            "equivalent_drag_Pa" => pwater,
            "traction_N_per_m2" => twater
        ]
    )

    # 数值积分检查：合力及对底部中心的弯矩
    water_force = sum(∫(pwater) * dΓwater)
    water_moment = sum(∫(mxwater) * dΓwater)

    expected_pressure = 0.5 * WATER_DENSITY *
                        DRAG_COEFFICIENT * FLOW_SPEED^2
    expected_force = expected_pressure * WIDTH * WATER_DEPTH
    expected_moment = -expected_force * WATER_DEPTH / 2

    @assert isapprox(water_force, expected_force; rtol=1e-8)
    @assert isapprox(water_moment, expected_moment; rtol=1e-8)

    λ = YOUNG_MODULUS * POISSON_RATIO /
        ((1 + POISSON_RATIO) * (1 - 2POISSON_RATIO))
    μ = YOUNG_MODULUS / (2 * (1 + POISSON_RATIO))

    stress(strain) = λ * tr(strain) * one(strain) + 2μ * strain

    a(u, v) = ∫(ε(v) ⊙ (stress ∘ ε(u))) * dΩ

    body_force = VectorValue(
        0.0, 0.0, -CONCRETE_DENSITY * GRAVITY
    )
    deck_traction = VectorValue(
        0.0, 0.0, -DECK_VERTICAL_FORCE / (WIDTH * DEPTH)
    )

    l_water(v) = ∫(v ⋅ twater) * dΓwater

    l_combined(v) = ∫(v ⋅ twater) * dΓwater +
                    ∫(v ⋅ body_force) * dΩ +
                    ∫(v ⋅ deck_traction) * dΓtop

    println("2/5 Solving water-only load case ...")
    uh_water = solve(AffineFEOperator(a, l_water, U, V))

    println("3/5 Solving combined load case ...")
    uh_combined = solve(AffineFEOperator(a, l_combined, U, V))

    mean_top_water = sum(∫(uh_water) * dΓtop) / (WIDTH * DEPTH)
    mean_top_combined = sum(∫(uh_combined) * dΓtop) / (WIDTH * DEPTH)

    println("4/5 Exporting mesh, load and response plots ...")

    mesh_figure = plot_mesh_and_load()

    water_result = export_response(
        Ω, uh_water, stress,
        "water_only", "02_water_response.png"
    )

    combined_result = export_response(
        Ω, uh_combined, stress,
        "combined", "03_combined_response.png"
    )

    println("5/5 Writing summary ...")

    self_weight = CONCRETE_DENSITY * GRAVITY *
                  WIDTH * DEPTH * HEIGHT

    open(joinpath(OUTPUT_DIR, "summary.txt"), "w") do io
        println(io, "Bridge pier under equivalent steady water drag")
        println(io, "Units: m, N, Pa")
        println(io, "Geometry: ", (WIDTH, DEPTH, HEIGHT), " m")
        println(io, "Mesh partition: ", (NX, NY, NZ))
        println(io, "Hexahedral elements: ", NX * NY * NZ)
        println(io, "Water depth: ", WATER_DEPTH, " m")
        println(io, "Flow speed: ", FLOW_SPEED, " m/s")
        println(io, "Drag coefficient: ", DRAG_COEFFICIENT)
        println(io, "Equivalent net drag traction: ", expected_pressure, " Pa")
        println(io, "Integrated water force along +Y: ", water_force, " N")
        println(io, "Integrated water moment about base X: ", water_moment, " N*m")
        println(io, "Combined-case deck force: ", DECK_VERTICAL_FORCE, " N")
        println(io, "Combined-case self-weight: ", self_weight, " N")
        println(io)

        println(io, "WATER ONLY")
        println(io, "Mean top displacement vector: ", mean_top_water, " m")
        println(io, "Max sampled displacement: ",
                water_result.max_sampled_displacement_mm, " mm")
        println(io, "Max sampled flow-direction displacement: ",
                water_result.max_sampled_flow_displacement_mm, " mm")
        println(io, "Sampled sigma_zz range: ",
                water_result.min_sampled_sigma_zz_mpa, " to ",
                water_result.max_sampled_sigma_zz_mpa, " MPa")
        println(io, "Max sampled Von Mises: ",
                water_result.max_sampled_vm_mpa, " MPa")
        println(io)

        println(io, "COMBINED")
        println(io, "Mean top displacement vector: ", mean_top_combined, " m")
        println(io, "Max sampled displacement: ",
                combined_result.max_sampled_displacement_mm, " mm")
        println(io, "Sampled sigma_zz range: ",
                combined_result.min_sampled_sigma_zz_mpa, " to ",
                combined_result.max_sampled_sigma_zz_mpa, " MPa")
        println(io, "Max sampled Von Mises: ",
                combined_result.max_sampled_vm_mpa, " MPa")
        println(io)

        println(io, "The water load is an equivalent NET drag distribution.")
        println(io, "It is not a computed CFD wall-pressure distribution.")
        println(io, "Static linear elasticity; no transient or fluid coupling.")
        println(io, "No hydrostatic pressure, scour, soil or concrete cracking.")
        println(io, "Cloud plots show sampled Y-Z middle-section values.")
        println(io, "Reported sample maxima are not global extrema.")
        println(io, "Refine the mesh to assess convergence.")
        println(io, "Fixed-base local stress peaks may be mesh-sensitive.")
        println(io, "Von Mises is not used as a concrete failure criterion.")
    end

    @printf("\nEquivalent water traction: %.3f kPa\n",
            expected_pressure / 1000)
    @printf("Water resultant: %.3f kN\n", water_force / 1000)
    @printf("Base water moment magnitude: %.3f kN*m\n",
            abs(water_moment) / 1000)
    @printf("Water-only mean top Y displacement: %.6f mm\n",
            mean_top_water[2] * 1000)

    println("\nResults saved to:")
    println(OUTPUT_DIR)

    display(mesh_figure)
    display(water_result.figure)
    display(combined_result.figure)

    return nothing
end

end # module

Base.invokelatest(() -> PierWaterFEM.main())