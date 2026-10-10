using Gridap
# ============================================================
# 保存为 bridge_fem.jl，在 VS Code 的 Julia 环境中运行整个文件。
#
# 首次运行自动安装 Gridap 和 CairoMakie，需要联网。
# 输出保存在脚本旁边的 bridge_results 文件夹：
#   bridge_scene.png  —— 三跨拱桥与河流
#   pier_analysis.png —— 桥墩应力、位移和放大变形
#   pier_result*.vtu  —— 三维有限元结果，可选用 ParaView 打开
#   pier_samples.csv  —— 桥墩表面采样结果
#   summary.txt       —— 参数及结果摘要
#
# 单位：m、N、Pa。
# 桥梁场景用于展示；有限元计算对象为高亮的一个矩形桥墩。
# 河流仅作背景，不计算水流或流固耦合。
# 混凝土采用三维线弹性模型，不包含开裂、钢筋和地基变形。
# 尚未在本机 Julia 环境实际运行验证。
#
# Gridap 官方参考：
# https://gridap.github.io/Tutorials/stable/pages/t003_elasticity/
# ============================================================
ENV["JULIA_NUM_PRECOMPILE_TASKS"] = "1"
import Pkg

# 独立环境，避免影响其他 Julia 项目
environment_dir = joinpath(@__DIR__, "bridge_environment")
first_run = !isfile(joinpath(environment_dir, "Project.toml"))
Pkg.activate(environment_dir)

if first_run
    Pkg.add(["Gridap", "CairoMakie"])
else
    Pkg.instantiate()
end

using Gridap
using Gridap.Geometry
using CairoMakie
using LinearAlgebra
using Printf


# -------------------- 基础绘图工具 --------------------

function draw_box!(ax, x0, x1, y0, y1, z0, z1; color="#b7bdc5")
    vertices = [
        x0 y0 z0
        x1 y0 z0
        x1 y1 z0
        x0 y1 z0
        x0 y0 z1
        x1 y0 z1
        x1 y1 z1
        x0 y1 z1
    ]

    faces = [
        1 3 2
        1 4 3
        5 6 7
        5 7 8
        1 2 6
        1 6 5
        2 3 7
        2 7 6
        3 4 8
        3 8 7
        4 1 5
        4 5 8
    ]

    mesh!(ax, vertices, faces; color=color)
end


function draw_arch!(ax, center, y0, y1)
    # 拱跨 24 m，拱脚高 3 m，拱顶高 12 m
    xs = collect(range(center - 12.0, center + 12.0; length=81))
    zs = [3.0 + 9.0 * sin(pi * (x - center + 12.0) / 24.0)
          for x in xs]

    faces = [
        1 3 2
        1 4 3
        5 6 7
        5 7 8
        1 2 6
        1 6 5
        2 3 7
        2 7 6
        3 4 8
        3 8 7
        4 1 5
        4 5 8
    ]

    for i in 1:(length(xs) - 1)
        xa, xb = xs[i], xs[i + 1]
        za, zb = zs[i], zs[i + 1]

        vertices = [
            xa y0 (za - 0.8)
            xb y0 (zb - 0.8)
            xb y1 (zb - 0.8)
            xa y1 (za - 0.8)
            xa y0 za
            xb y0 zb
            xb y1 zb
            xa y1 za
        ]

        mesh!(ax, vertices, faces; color="#c8c0b2")
    end

    # 拱上立柱
    for x in (center - 9.0):3.0:(center + 9.0)
        z = 3.0 + 9.0 * sin(pi * (x - center + 12.0) / 24.0)
        draw_box!(
            ax,
            x - 0.22, x + 0.22,
            y0 + 0.08, y1 - 0.08,
            z - 0.15, 12.9;
            color="#ddd4c3"
        )
    end
end


function draw_bridge_scene(output_dir)
    fig = Figure(size=(1600, 1000), backgroundcolor="#edf3f7")

    ax = Axis3(
        fig[1, 1];
        title="RIVER ARCH BRIDGE  |  highlighted pier analysed with Gridap",
        xlabel="Bridge direction / m",
        ylabel="River direction / m",
        zlabel="Elevation / m",
        aspect=:data,
        azimuth=0.72pi,
        elevation=0.16pi,
        perspectiveness=0.35
    )

    # 河床
    draw_box!(ax, -30, 30, -32, 32, -1.0, -0.4; color="#b4a78f")

    # 河岸
    draw_box!(ax, -48, -30, -32, 32, -0.5, 2.0; color="#76996a")
    draw_box!(ax, 30, 48, -32, 32, -0.5, 2.0; color="#76996a")

    # 河面：小幅波纹仅用于展示
    river_x = collect(range(-29.8, 29.8; length=100))
    river_y = collect(range(-32.0, 32.0; length=100))

    water = [
        2.2 + 0.035 * sin(0.8x + 0.55y) +
        0.018 * cos(1.7y - 0.3x)
        for x in river_x, y in river_y
    ]

    surface!(ax, river_x, river_y, water; color="#49a8c5")

    # 水面亮色流线
    for x0 in -27.0:4.5:27.0
        ys = collect(range(-30.0, 30.0; length=140))
        xs = [x0 + 0.25 * sin(0.35y) for y in ys]
        zs = [
            2.2 + 0.035 * sin(0.8x + 0.55y) +
            0.018 * cos(1.7y - 0.3x) + 0.04
            for (x, y) in zip(xs, ys)
        ]
        lines!(ax, xs, ys, zs; color="#9edcea", linewidth=1)
    end

    # 基础与桥墩：分析对象为 x=12 m 处桥墩
    for x in (-36.0, -12.0, 12.0, 36.0)
        draw_box!(
            ax, x - 3.0, x + 3.0, -3.5, 3.5, -0.4, 0.0;
            color="#8c939c"
        )

        pier_color = x == 12.0 ? "#e79647" : "#b6bdc7"
        draw_box!(
            ax, x - 1.5, x + 1.5, -2.0, 2.0, 0.0, 12.0;
            color=pier_color
        )

        # 盖梁
        draw_box!(
            ax, x - 2.4, x + 2.4, -5.2, 5.2, 12.0, 12.8;
            color="#aab3bf"
        )
    end

    # 三跨、双拱肋
    for center in (-24.0, 0.0, 24.0)
        draw_arch!(ax, center, -4.6, -3.8)
        draw_arch!(ax, center, 3.8, 4.6)
    end

    # 桥面与路面
    draw_box!(ax, -40, 40, -5, 5, 12.8, 13.6; color="#dadde2")
    draw_box!(ax, -40, 40, -4.2, 4.2, 13.6, 13.68; color="#485563")

    # 人行道
    for (y0, y1) in ((-5.0, -4.2), (4.2, 5.0))
        draw_box!(ax, -40, 40, y0, y1, 13.6, 13.83; color="#cfc9bc")
    end

    # 道路中心虚线
    for x in -38.0:5.0:37.0
        draw_box!(
            ax, x, x + 2.5, -0.07, 0.07, 13.685, 13.70;
            color="#f2e6a5"
        )
    end

    # 护栏
    for y in (-4.85, 4.85)
        for x in -40.0:2.0:40.0
            draw_box!(
                ax, x - 0.055, x + 0.055, y - 0.055, y + 0.055,
                13.8, 15.0;
                color="#344b61"
            )
        end
        for z in (14.35, 14.95)
            draw_box!(
                ax, -40, 40, y - 0.07, y + 0.07, z, z + 0.10;
                color="#344b61"
            )
        end
    end

    # 分析对象说明
    text!(
        ax, 12.0, -7.0, 8.0;
        text="FE ANALYSIS PIER",
        color="#9c4d15",
        fontsize=17,
        align=(:center, :center)
    )

    save(joinpath(output_dir, "bridge_scene.png"), fig)
    return fig
end


# -------------------- 自动识别边界 --------------------

function tag_horizontal_plane!(model, name, height)
    labels = get_face_labeling(model)
    coordinates = get_node_coordinates(model)
    entities = Int[]

    # 同时标记面、边、顶点，确保整个底面完全固定
    for dimension in 0:2
        face_nodes = get_face_nodes(model, dimension)
        face_entities = get_face_entity(labels, dimension)

        for face_id in eachindex(face_entities)
            nodes = face_nodes[face_id]
            on_plane = all(
                abs(coordinates[node_id][3] - height) < 1.0e-8
                for node_id in nodes
            )

            if on_plane
                push!(entities, face_entities[face_id])
            end
        end
    end

    isempty(entities) && error("Cannot identify boundary: $name")
    add_tag!(labels, name, unique(entities))
end


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


# -------------------- 桥墩有限元分析 --------------------

function analyse_pier(output_dir)
    # 几何：3 m × 4 m × 12 m
    width = 3.0
    depth = 4.0
    height = 12.0

    # 混凝土线弹性参数
    young_modulus = 32.0e9
    poisson_ratio = 0.20
    density = 2500.0
    gravity = 9.81

    # 桥面及上部结构传递到该桥墩顶部的等效荷载
    vertical_force = 12.0e6       # 向下 12 MN
    horizontal_force = 0.30e6    # 沿桥方向 0.30 MN

    top_area = width * depth
    pressure = vertical_force / top_area

    # 改大此参数可以细化网格，但计算会更慢
    partition = (6, 8, 24)

    model = CartesianDiscreteModel(
        (-width / 2, width / 2,
         -depth / 2, depth / 2,
         0.0, height),
        partition
    )

    tag_horizontal_plane!(model, "fixed_bottom", 0.0)
    tag_horizontal_plane!(model, "loaded_top", height)

    # 三维一阶位移单元
    reference_element = ReferenceFE(
        lagrangian, VectorValue{3, Float64}, 1
    )

    V = TestFESpace(
        model, reference_element;
        conformity=:H1,
        dirichlet_tags="fixed_bottom"
    )

    U = TrialFESpace(V, VectorValue(0.0, 0.0, 0.0))

    Ω = Triangulation(model)
    Γtop = BoundaryTriangulation(model; tags="loaded_top")
    Γbottom = BoundaryTriangulation(model; tags="fixed_bottom")

    dΩ = Measure(Ω, 2)
    dΓtop = Measure(Γtop, 2)
    dΓbottom = Measure(Γbottom, 2)

    # 校验顶部和底部边界面积，避免错误加载或约束
    measured_top_area = sum(∫(1.0) * dΓtop)
    measured_bottom_area = sum(∫(1.0) * dΓbottom)

    @assert isapprox(measured_top_area, top_area; rtol=1e-8)
    @assert isapprox(measured_bottom_area, top_area; rtol=1e-8)

    λ = young_modulus * poisson_ratio /
        ((1 + poisson_ratio) * (1 - 2poisson_ratio))
    μ = young_modulus / (2 * (1 + poisson_ratio))

    stress(strain) = λ * tr(strain) * one(strain) + 2μ * strain

    # 体力：桥墩自重
    body_force = VectorValue(0.0, 0.0, -density * gravity)

    # 顶部均布面力：水平荷载和向下压强
    traction = VectorValue(
        horizontal_force / top_area,
        0.0,
        -pressure
    )

    a(u, v) = ∫(ε(v) ⊙ (stress ∘ ε(u))) * dΩ
    l(v) = ∫(v ⋅ body_force) * dΩ +
           ∫(v ⋅ traction) * dΓtop

    println("Solving 3D pier elasticity problem ...")
    operator = AffineFEOperator(a, l, U, V)
    uh = solve(operator)

    strain_h = ε(uh)
    stress_h = stress ∘ strain_h
    vm_h = von_mises ∘ stress_h
    displacement_h = norm ∘ uh

    writevtk(
        Ω,
        joinpath(output_dir, "pier_result");
        cellfields=[
            "displacement_m" => uh,
            "displacement_magnitude_m" => displacement_h,
            "strain" => strain_h,
            "stress_Pa" => stress_h,
            "von_mises_Pa" => vm_h
        ]
    )

    # 在桥墩前表面略向内部采样，避免边界点定位歧义。
    # 采样应力为单元内结果，没有做节点平均或光滑处理。
    xs = collect(range(-width / 2 + 1e-6, width / 2 - 1e-6;
                       length=31))
    zs = collect(range(1e-6, height - 1e-6; length=81))
    y_sample = -depth / 2 + 1e-6

    points = [
        Gridap.Point(x, y_sample, z)
        for x in xs, z in zs
    ]

    println("Sampling displacement and stress ...")
    displacements = uh.(vec(points))
    stresses = stress_h.(vec(points))

    nx, nz = length(xs), length(zs)
    ux = reshape([u[1] for u in displacements], nx, nz)
    uz = reshape([u[3] for u in displacements], nx, nz)

    displacement_mm = reshape(
        [1000.0 * norm(u) for u in displacements],
        nx, nz
    )

    sigma_zz_mpa = reshape(
        [s[3, 3] / 1.0e6 for s in stresses],
        nx, nz
    )

    vm_mpa = reshape(
        [von_mises(s) / 1.0e6 for s in stresses],
        nx, nz
    )

    # 表面采样数据
    open(joinpath(output_dir, "pier_samples.csv"), "w") do io
        println(
            io,
            "x_m,y_m,z_m,ux_m,uy_m,uz_m,displacement_mm,sigma_zz_MPa,von_mises_MPa"
        )

        for (point, u, s) in zip(vec(points), displacements, stresses)
            @printf(
                io,
                "%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e\n",
                point[1], point[2], point[3],
                u[1], u[2], u[3],
                1000.0 * norm(u),
                s[3, 3] / 1.0e6,
                von_mises(s) / 1.0e6
            )
        end
    end

    # -------------------- 结果图 --------------------
    fig = Figure(size=(1600, 1000), backgroundcolor="#f5f7fa")

    Label(
        fig[0, 1:4],
        "GRIDAP  |  3D BRIDGE PIER ANALYSIS";
        fontsize=25
    )

    ax1 = Axis(
        fig[1, 1];
        title="Vertical stress: compression is negative",
        xlabel="x / m", ylabel="z / m",
        aspect=DataAspect()
    )
    h1 = heatmap!(ax1, xs, zs, sigma_zz_mpa; colormap=:balance)
    Colorbar(fig[1, 2], h1; label="sigma_zz / MPa")

    ax2 = Axis(
        fig[1, 3];
        title="Displacement magnitude",
        xlabel="x / m", ylabel="z / m",
        aspect=DataAspect()
    )
    h2 = heatmap!(ax2, xs, zs, displacement_mm; colormap=:viridis)
    Colorbar(fig[1, 4], h2; label="Displacement / mm")

    ax3 = Axis(
        fig[2, 1];
        title="Von Mises stress",
        xlabel="x / m", ylabel="z / m",
        aspect=DataAspect()
    )
    h3 = heatmap!(ax3, xs, zs, vm_mpa; colormap=:inferno)
    Colorbar(fig[2, 2], h3; label="Von Mises / MPa")

    # 自适应放大变形，最大展示位移约为 0.7 m
    sampled_max_m = maximum(displacement_mm) / 1000.0
    deformation_scale = sampled_max_m > 0 ?
                        0.7 / sampled_max_m : 1.0

    ax4 = Axis(
        fig[2, 3:4];
        title=@sprintf("Front-face deformation × %.0f", deformation_scale),
        xlabel="x / m", ylabel="z / m",
        aspect=DataAspect()
    )

    lines!(
        ax4,
        [-width / 2, width / 2, width / 2, -width / 2, -width / 2],
        [0.0, 0.0, height, height, 0.0];
        color="#8c99a8", linestyle=:dash, linewidth=2
    )

    # 变形后的表面网格
    for i in 1:5:nx
        lines!(
            ax4,
            xs[i] .+ deformation_scale .* ux[i, :],
            zs .+ deformation_scale .* uz[i, :];
            color="#dc7d32", linewidth=1.5
        )
    end

    for j in 1:8:nz
        lines!(
            ax4,
            xs .+ deformation_scale .* ux[:, j],
            zs[j] .+ deformation_scale .* uz[:, j];
            color="#dc7d32", linewidth=1.5
        )
    end

    Label(
        fig[3, 1:4],
        "Fixed base | Top load: 12 MN vertical + 0.30 MN horizontal | Self-weight included\n" *
        "Surface samples shown; fixed-base stress peaks may be mesh-sensitive.";
        fontsize=15
    )

    save(joinpath(output_dir, "pier_analysis.png"), fig)

    top_average_u = sum(∫(uh) * dΓtop) / measured_top_area

    # 一维自由侧向压缩参考值；不等同于底部固定的三维结果
    axial_reference_mm = 1000.0 * (
        pressure * height / young_modulus +
        density * gravity * height^2 / (2young_modulus)
    )

    open(joinpath(output_dir, "summary.txt"), "w") do io
        println(io, "Gridap bridge pier: 3D linear elasticity")
        println(io, "Units: m, N, Pa")
        println(io, "Pier: 3 m x 4 m x 12 m")
        println(io, "Mesh partition: ", partition)
        println(io, "Young's modulus: ", young_modulus, " Pa")
        println(io, "Poisson ratio: ", poisson_ratio)
        println(io, "Density: ", density, " kg/m^3")
        println(io, "Top vertical force: ", vertical_force, " N")
        println(io, "Top horizontal force: ", horizontal_force, " N")
        println(io, "Top pressure: ", pressure, " Pa")
        println(io, "Self-weight: ", density * gravity * top_area * height, " N")
        println(io, "Measured top area: ", measured_top_area, " m^2")
        println(io, "Mean top displacement: ", top_average_u, " m")
        println(io, "Maximum sampled front-face displacement: ",
                maximum(displacement_mm), " mm")
        println(io, "Maximum sampled front-face von Mises stress: ",
                maximum(vm_mpa), " MPa")
        println(io, "1D axial-shortening reference: ", axial_reference_mm, " mm")
        println(io, "Displayed deformation scale: ", deformation_scale)
        println(io)
        println(io, "Only the highlighted rectangular pier is solved.")
        println(io, "Upper-structure forces are prescribed equivalent loads.")
        println(io, "The bridge and river image is a presentation scene.")
        println(io, "No cracking, reinforcement, soil or fluid coupling.")
        println(io, "Von Mises stress is descriptive, not a concrete failure criterion.")
        println(io, "Reported maxima are surface-sample maxima, not global extrema.")
        println(io, "Repeat with a finer mesh before interpreting local stress peaks.")
    end

    @printf("Mean top vertical displacement: %.4f mm\n",
            1000.0 * top_average_u[3])
    @printf("Maximum sampled displacement: %.4f mm\n",
            maximum(displacement_mm))

    return fig
end


# -------------------- 主程序 --------------------

function main()
    output_dir = joinpath(@__DIR__, "bridge_results")
    mkpath(output_dir)

    CairoMakie.activate!()

    println("Drawing bridge and river ...")
    bridge_figure = draw_bridge_scene(output_dir)

    result_figure = analyse_pier(output_dir)

    # VS Code 支持时显示到绘图窗口；PNG 文件始终保存。
    display(bridge_figure)
    display(result_figure)

    println("\nFinished. Results saved to:")
    println(output_dir)
end

main()