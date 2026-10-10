# ============================================================
# 两艘船舶外观模型 + 局部船体外板有限元分析
#
# 保存为 two_ships_fem.jl，运行整个文件。
#
# 自动生成：
# ship_results/
#   cargo/                 集装箱货船
#     01_ship.png          船舶外观
#     02_mesh_load.png     外板网格及压力
#     03_clouds.png        位移、Von Mises、纵向和竖向应力
#     04_deformation.png   放大变形
#     plate_results*.vtu   三维有限元结果
#     pressure*.vtu        载荷
#     mesh*.vtu            网格
#     samples.csv          采样数据
#   patrol/                沿海巡逻船，相同输出
#   summary.txt            结果及校核摘要
#
# 单位：m、N、Pa。
#
# 模型：
# 1. 两艘船为参数化示例外观，不是实际船舶型线。
# 2. 外板计算模型为两道支撑之间的局部平板。
# 3. 采用二阶三维六面体实体单元，包含真实板厚。
# 4. 四条边完全固定，模拟刚性支撑。
# 5. 载荷包含海水静压与示例稳态附加压力。
# 6. 自动检查载荷合力、能量平衡及网格加密变化。
#
# 不包含整船强度、外板曲率、支撑柔度、波浪砰击、
# 焊接、腐蚀、屈曲、塑性、疲劳或流固耦合。
# ============================================================

ENV["JULIA_NUM_PRECOMPILE_TASKS"] = "1"

import Pkg

# 优先沿用之前桥梁代码的环境
if get(ENV, "SHIP_SKIP_SETUP", "0") != "1"
    bridge_env = joinpath(@__DIR__, "bridge_environment")

    project_dir = isfile(joinpath(bridge_env, "Project.toml")) ?
                  bridge_env :
                  joinpath(@__DIR__, "ship_environment")

    Pkg.activate(project_dir)

    missing = [
        name for name in ["Gridap", "CairoMakie"]
        if !haskey(Pkg.project().dependencies, name)
    ]

    if isempty(missing)
        Pkg.instantiate()
    else
        Pkg.add(missing)
    end
end


module TwoShipsFEM

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs: get_node_coordinates, get_face_nodes
using LinearAlgebra
using Printf

import CairoMakie as CM


# ==================== 参数 ====================

const OUT = joinpath(@__DIR__, "ship_results")

const E = 210e9             # 钢材弹性模量
const NU = 0.30            # 泊松比
const RHO = 1025.0         # 海水密度
const G = 9.81

# L：船长；B：船宽；D：型深；draft：示例吃水。
#
# a：外板纵向长度
# b：外板竖向高度
# t：外板厚度
# depth：外板中心距水面的深度
# speed：示例航速，m/s
# cp：稳态附加压力系数，示例值
# fy：示例钢材屈服强度
#
# 两艘船的参数不同，结果不能只解释为板厚差异。

const CASES = [
    (
        id = "cargo",
        title = "CONTAINER VESSEL",
        L = 110.0,
        B = 18.0,
        D = 8.0,
        draft = 5.0,
        a = 1.20,
        b = 0.65,
        t = 0.014,
        depth = 2.50,
        speed = 5.0,
        cp = 0.30,
        fy = 235e6
    ),
    (
        id = "patrol",
        title = "COASTAL PATROL VESSEL",
        L = 36.0,
        B = 7.0,
        D = 4.0,
        draft = 2.0,
        a = 0.80,
        b = 0.45,
        t = 0.008,
        depth = 1.20,
        speed = 8.0,
        cp = 0.30,
        fy = 235e6
    )
]

# 自动进行两套网格计算。
# 改小可以加快计算，但挠度可能尚未收敛。
const COARSE = (16, 8, 3)
const FINE = (32, 16, 3)

const FACES = [
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


# ==================== 绘图工具 ====================

function box!(ax, x0, x1, y0, y1, z0, z1, color)
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

    CM.mesh!(ax, vertices, FACES; color=color)
end


function breadth(s)
    stern = 0.78 + 0.22 * min(s / 0.15, 1.0)

    bow = s < 0.72 ?
          1.0 :
          max(0.008, cos((s - 0.72) / 0.28 * pi / 2))

    return stern * bow
end


# ==================== 船体外观 ====================

function hull!(ax, c)
    ns, nt = 100, 40

    ss = range(0.0, 1.0; length=ns)
    tt = range(-pi / 2, pi / 2; length=nt)

    vertices = zeros(ns * nt, 3)

    for j in 1:nt, i in 1:ns
        s = ss[i]
        theta = tt[j]
        w = breadth(s)
        k = i + (j - 1) * ns

        vertices[k, :] = [
            c.L * s,
            0.5 * c.B * w * sin(theta),
            c.D * (1 - (0.65 + 0.35 * w) * cos(theta))
        ]
    end

    faces = zeros(Int, 2 * (ns - 1) * (nt - 1), 3)

    k = 1
    for j in 1:(nt - 1), i in 1:(ns - 1)
        p = i + (j - 1) * ns

        faces[k, :] = [p, p + 1, p + ns + 1]
        faces[k + 1, :] = [p, p + ns + 1, p + ns]

        k += 2
    end

    hull_color = c.id == "cargo" ? "#264b69" : "#cbd3dc"
    CM.mesh!(ax, vertices, faces; color=hull_color)

    # 甲板
    deck_vertices = zeros(2 * ns, 3)

    for i in 1:ns
        half_width = 0.5 * c.B * breadth(ss[i])

        deck_vertices[i, :] = [
            c.L * ss[i], -half_width, c.D
        ]
        deck_vertices[ns + i, :] = [
            c.L * ss[i], half_width, c.D
        ]
    end

    deck_faces = zeros(Int, 2 * (ns - 1), 3)

    for i in 1:(ns - 1)
        deck_faces[2i - 1, :] = [i, i + 1, ns + i + 1]
        deck_faces[2i, :] = [i, ns + i + 1, ns + i]
    end

    CM.mesh!(
        ax, deck_vertices, deck_faces;
        color="#7b8791"
    )

    # 船尾横截面
    tail = vcat(
        reshape([0.0, 0.0, c.D * 0.5], 1, 3),
        vertices[1:ns:end, :]
    )

    tail_faces = zeros(Int, nt, 3)

    for j in 1:(nt - 1)
        tail_faces[j, :] = [1, j + 2, j + 1]
    end

    tail_faces[end, :] = [1, 2, nt + 1]

    CM.mesh!(ax, tail, tail_faces; color=hull_color)

    # 两侧护栏
    for side in (-1.0, 1.0)
        x = collect(range(0.0, c.L; length=150))
        y = [
            side * c.B / 2 * breadth(xx / c.L)
            for xx in x
        ]

        CM.lines!(
            ax, x, y, fill(c.D + 0.65, length(x));
            color="#e3e6e8",
            linewidth=1.5
        )

        for xx in range(0.0, c.L; length=45)
            yy = side * c.B / 2 * breadth(xx / c.L)

            CM.lines!(
                ax,
                [xx, xx],
                [yy, yy],
                [c.D, c.D + 0.65];
                color="#e3e6e8"
            )
        end
    end
end


function ship_scene(c, dir)
    fig = CM.Figure(
        size=(1600, 720),
        backgroundcolor="#eaf2f7"
    )

    ax = CM.Axis3(
        fig[1, 1];
        title=c.title * " | parametric demonstration hull",
        xlabel="Length / m",
        ylabel="Beam / m",
        zlabel="Elevation / m",
        aspect=:data,
        azimuth=0.69pi,
        elevation=0.16pi,
        perspectiveness=0.35
    )

    # 海面
    x = collect(range(-c.L * 0.08, c.L * 1.08; length=80))
    y = collect(range(-c.B, c.B; length=50))

    water = [
        c.draft + 0.03 * sin(0.5xx + yy)
        for xx in x, yy in y
    ]

    CM.surface!(ax, x, y, water; color="#68b3cc")

    hull!(ax, c)

    if c.id == "cargo"
        # 集装箱货船
        palette = [
            "#d77847", "#b84042", "#447e98",
            "#d0b75f", "#4f8980"
        ]

        for ix in 0:6, iy in 0:4, iz in 0:1
            x0 = 23.0 + ix * 9.0
            y0 = -6.5 + iy * 2.6
            z0 = c.D + iz * 2.45

            color = palette[mod(ix + 2iy + iz, 5) + 1]

            box!(
                ax,
                x0, x0 + 8.4,
                y0, y0 + 2.35,
                z0, z0 + 2.3,
                color
            )

            # 集装箱表面加强筋装饰
            for stripe in 1:8
                xx = x0 + stripe * 0.9

                CM.lines!(
                    ax,
                    [xx, xx],
                    [y0 + 2.36, y0 + 2.36],
                    [z0 + 0.1, z0 + 2.2];
                    color="#243747",
                    linewidth=0.6
                )
            end
        end

        # 船楼及驾驶台
        box!(
            ax, 3.0, 17.0, -5.0, 5.0,
            c.D, c.D + 6.0, "#e7e4d9"
        )
        box!(
            ax, 4.0, 16.0, -5.4, 5.4,
            c.D + 6.0, c.D + 8.0, "#edf0f1"
        )

        for xx in 4.8:1.5:14.8
            box!(
                ax, xx, xx + 1.0, 5.41, 5.46,
                c.D + 6.6, c.D + 7.4, "#29495e"
            )
        end

        # 烟囱
        box!(
            ax, 7.0, 11.0, -1.8, 1.8,
            c.D + 8.0, c.D + 11.0, "#d1a049"
        )
        box!(
            ax, 8.0, 10.0, -1.4, 1.4,
            c.D + 11.0, c.D + 11.8, "#273b4c"
        )
    else
        # 巡逻船船楼
        box!(
            ax, 8.0, 22.0, -2.1, 2.1,
            c.D, c.D + 1.8, "#e8edf0"
        )
        box!(
            ax, 12.0, 20.0, -1.8, 1.8,
            c.D + 1.8, c.D + 3.4, "#edf1f2"
        )

        for xx in 12.4:1.2:18.8
            box!(
                ax, xx, xx + 0.85, 1.81, 1.86,
                c.D + 2.3, c.D + 3.0, "#284f65"
            )
        end

        # 桅杆和雷达
        box!(
            ax, 15.0, 15.25, -0.12, 0.12,
            c.D + 3.4, c.D + 6.8, "#495c6b"
        )
        box!(
            ax, 13.8, 16.5, -0.18, 0.18,
            c.D + 6.2, c.D + 6.4, "#d9e1e8"
        )

        # 艏部设备
        box!(
            ax, 26.0, 29.0, -1.0, 1.0,
            c.D, c.D + 0.8, "#596c7a"
        )
    end

        description = @sprintf(
        "L %.0f m | B %.0f m | D %.0f m | local plate %.2f x %.2f m, thickness %.0f mm\nAppearance model only; the FE model is a separate flat panel between frames.",
        c.L, c.B, c.D, c.a, c.b, 1000 * c.t
    )

    CM.Label(fig[2, 1], description; fontsize=17)

    CM.save(joinpath(dir, "01_ship.png"), fig)
    display(fig)
end


# ==================== 有限元边界识别 ====================

function tag_plane!(model, name, direction, value)
    labels = get_face_labeling(model)
    nodes = get_node_coordinates(model)

    entities = Int[]

    # 包含面、边、顶点，保证四边固定完整
    for dimension in 0:2
        connectivity = get_face_nodes(model, dimension)
        ids = get_face_entity(labels, dimension)

        for face_id in eachindex(ids)
            on_plane = all(
                abs(nodes[node_id][direction] - value) < 1e-9
                for node_id in connectivity[face_id]
            )

            if on_plane
                push!(entities, ids[face_id])
            end
        end
    end

    isempty(entities) && error("Boundary missing: $name")
    add_tag!(labels, name, unique(entities))
end


# ==================== 载荷及材料 ====================

function pressure(c, x)
    # 局部 y 轴从外板下边缘向上
    local_depth = c.depth + c.b / 2 - x[2]
    hydrostatic = RHO * G * local_depth

    # 示例稳态附加压力，不是波浪砰击或 CFD 壁面压力
    dynamic = 0.5 * RHO * c.cp * c.speed^2

    return hydrostatic + dynamic
end


function vm(s)
    return sqrt(
        0.5 * (
            (s[1, 1] - s[2, 2])^2 +
            (s[2, 2] - s[3, 3])^2 +
            (s[3, 3] - s[1, 1])^2
        ) +
        3.0 * (
            s[1, 2]^2 +
            s[2, 3]^2 +
            s[3, 1]^2
        )
    )
end


# ==================== 外板有限元求解 ====================

function solve_panel(c, partition)
    model = CartesianDiscreteModel(
        (0.0, c.a, 0.0, c.b, 0.0, c.t),
        partition
    )

    boundaries = (
        ("left", 1, 0.0),
        ("right", 1, c.a),
        ("lower", 2, 0.0),
        ("upper", 2, c.b),
        ("wet", 3, c.t)
    )

    for (name, direction, value) in boundaries
        tag_plane!(model, name, direction, value)
    end

    add_tag_from_tags!(
        get_face_labeling(model),
        "clamped",
        ["left", "right", "lower", "upper"]
    )

    # 二阶三维位移单元
    reffe = ReferenceFE(
        lagrangian, VectorValue{3, Float64}, 2
    )

    V = TestFESpace(
        model, reffe;
        conformity=:H1,
        dirichlet_tags="clamped"
    )

    U = TrialFESpace(V, VectorValue(0.0, 0.0, 0.0))

    Ω = Triangulation(model)
    Γ = BoundaryTriangulation(model; tags="wet")

    dΩ = Measure(Ω, 4)
    dΓ = Measure(Γ, 4)

    λ = E * NU / ((1 + NU) * (1 - 2NU))
    μ = E / (2 * (1 + NU))

    sigma(strain) = λ * tr(strain) * one(strain) + 2μ * strain

    # 压力沿 -z 方向作用于外表面
    traction = CellField(
        x -> VectorValue(0.0, 0.0, -pressure(c, x)),
        Γ
    )

    p = CellField(x -> pressure(c, x), Γ)

    a(u, v) = ∫(ε(v) ⊙ (sigma ∘ ε(u))) * dΩ
    l(v) = ∫(v ⋅ traction) * dΓ

    operator = AffineFEOperator(a, l, U, V)
    uh = solve(operator)

    stress_h = sigma ∘ ε(uh)

    # 校核一：应变能 = 外载荷功的一半
    internal = 0.5 * sum(∫(ε(uh) ⊙ stress_h) * dΩ)
    external = 0.5 * sum(∫(uh ⋅ traction) * dΓ)

    energy_error = abs(internal - external) /
                   max(abs(external), 1e-20)

    # 校核二：数值积分合力 = 解析合力
    force = sum(∫(p) * dΓ)

    expected_force = (
        RHO * G * c.depth +
        0.5 * RHO * c.cp * c.speed^2
    ) * c.a * c.b

    @assert isapprox(force, expected_force; rtol=1e-8)
    @assert energy_error < 1e-6 "Energy balance failed"

    center_u = uh(
        Gridap.Point(c.a / 2, c.b / 2, c.t / 2)
    )

    return (
        model=model,
        Ω=Ω,
        Γ=Γ,
        uh=uh,
        sh=stress_h,
        p=p,
        force=force,
        internal=internal,
        external=external,
        energy_error=energy_error,
        center_mm=abs(center_u[3]) * 1000,
        partition=partition
    )
end


# ==================== 网格与载荷图 ====================

function plate_mesh_plot(c, result, dir)
    fig = CM.Figure(size=(1300, 750))

    ax = CM.Axis(
        fig[1, 1];
        title="Q2 solid-element surface grid | all four edges clamped",
        xlabel="Longitudinal x / m",
        ylabel="Vertical y / m",
        aspect=CM.DataAspect()
    )

    nx, ny, nz = result.partition

    for x in range(0.0, c.a; length=nx + 1)
        CM.lines!(
            ax, [x, x], [0.0, c.b];
            color="#4e6b85"
        )
    end

    for y in range(0.0, c.b; length=ny + 1)
        CM.lines!(
            ax, [0.0, c.a], [y, y];
            color="#4e6b85"
        )
    end

    CM.lines!(
        ax,
        [0.0, c.a, c.a, 0.0, 0.0],
        [0.0, 0.0, c.b, c.b, 0.0];
        color="#d45e42",
        linewidth=3
    )

    ax2 = CM.Axis(
        fig[1, 2];
        title="Seawater pressure + assumed steady increment",
        xlabel="x / m",
        ylabel="y / m",
        aspect=CM.DataAspect()
    )

    xs = collect(range(0.0, c.a; length=41))
    ys = collect(range(0.0, c.b; length=31))

    pressures = [
        pressure(c, Gridap.Point(x, y, c.t)) / 1000
        for x in xs, y in ys
    ]

    h = CM.heatmap!(
        ax2, xs, ys, pressures;
        colormap=:Blues
    )

    CM.Colorbar(fig[1, 3], h; label="Pressure / kPa")

        description = @sprintf(
        "%d x %d x %d quadratic hexahedra | %.0f mm thick | total applied force %.3f kN\nSolid thickness included; plotted grid is the loaded face.",
        nx, ny, nz, 1000 * c.t, result.force / 1000
    )

    CM.Label(fig[2, 1:3], description; fontsize=17)

    CM.save(joinpath(dir, "02_mesh_load.png"), fig)
    display(fig)
end


# ==================== 云图、变形及数据 ====================

function results_plot(c, result, dir)
    xs = collect(range(1e-7, c.a - 1e-7; length=49))
    ys = collect(range(1e-7, c.b - 1e-7; length=33))

    # 在外表面略向内部采样，避免边界定位歧义。
    # 应力没有做节点平均；采样最大值不是全局最大值。
    points = [
        Gridap.Point(x, y, c.t - 1e-8)
        for x in xs, y in ys
    ]

    displacements = result.uh.(vec(points))
    stresses = result.sh.(vec(points))

    dimensions = (length(xs), length(ys))

    normal_displacement_mm = reshape(
        [abs(u[3]) * 1000 for u in displacements],
        dimensions
    )

    von_mises_mpa = reshape(
        [vm(s) / 1e6 for s in stresses],
        dimensions
    )

    sigma_xx_mpa = reshape(
        [s[1, 1] / 1e6 for s in stresses],
        dimensions
    )

    sigma_yy_mpa = reshape(
        [s[2, 2] / 1e6 for s in stresses],
        dimensions
    )

    fig = CM.Figure(
        size=(1500, 1100),
        backgroundcolor="#f5f7fa"
    )

    CM.Label(
        fig[0, 1:4],
        c.title * " | LOCAL OUTER PLATE FE RESULTS";
        fontsize=24
    )

    plot_items = (
        (
            1, 1, normal_displacement_mm,
            "Normal displacement magnitude", "mm", :viridis
        ),
        (
            1, 3, von_mises_mpa,
            "Von Mises stress", "MPa", :inferno
        ),
        (
            2, 1, sigma_xx_mpa,
            "Longitudinal stress sigma_xx", "MPa", :balance
        ),
        (
            2, 3, sigma_yy_mpa,
            "Vertical stress sigma_yy", "MPa", :balance
        )
    )

    for (row, col, data, title, label, color_map) in plot_items
        ax = CM.Axis(
            fig[row, col];
            title=title,
            xlabel="x / m",
            ylabel="y / m",
            aspect=CM.DataAspect()
        )

        h = CM.heatmap!(
            ax, xs, ys, data;
            colormap=color_map
        )

        CM.Colorbar(fig[row, col + 1], h; label=label)
    end

    CM.Label(
        fig[3, 1:4],
        "Loaded-face interior samples, without stress smoothing. Corner stress peaks are mesh-sensitive.\n" *
        "This local clamped flat-panel model does not compute global hull strength, buckling or slamming.";
        fontsize=15
    )

    CM.save(joinpath(dir, "03_clouds.png"), fig)
    display(fig)

    # 三维放大变形
    normal_displacement_m = reshape(
        [u[3] for u in displacements],
        dimensions
    )

    scale = 0.12 * c.b /
            max(maximum(abs.(normal_displacement_m)), 1e-15)

    deformation_fig = CM.Figure(size=(1200, 800))

    ax = CM.Axis3(
        deformation_fig[1, 1];
        title=@sprintf("Deformation amplified %.0f times", scale),
        xlabel="x / m",
        ylabel="y / m",
        zlabel="amplified deflection / m",
        aspect=:data
    )

    h = CM.surface!(
        ax,
        xs,
        ys,
        scale .* normal_displacement_m;
        color=normal_displacement_mm,
        colormap=:viridis
    )

    CM.Colorbar(
        deformation_fig[1, 2], h;
        label="Actual displacement / mm"
    )

    CM.save(joinpath(dir, "04_deformation.png"), deformation_fig)
    display(deformation_fig)

    # 三维结果文件
    writevtk(
        result.Ω,
        joinpath(dir, "plate_results");
        cellfields=[
            "u_m" => result.uh,
            "sigma_Pa" => result.sh,
            "von_mises_Pa" => vm ∘ result.sh
        ]
    )

    writevtk(
        result.Γ,
        joinpath(dir, "pressure");
        cellfields=["pressure_Pa" => result.p]
    )

    writevtk(result.model, joinpath(dir, "mesh"))

    # CSV 采样数据
    open(joinpath(dir, "samples.csv"), "w") do io
        println(
            io,
            "x_m,y_m,z_m,ux_m,uy_m,uz_m,von_mises_MPa,sigma_xx_MPa,sigma_yy_MPa"
        )

        for (p, u, s) in zip(
            vec(points), displacements, stresses
        )
            @printf(
                io,
                "%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e,%.8e\n",
                p[1], p[2], p[3],
                u[1], u[2], u[3],
                vm(s) / 1e6,
                s[1, 1] / 1e6,
                s[2, 2] / 1e6
            )
        end
    end

    return (
        max_w_mm=maximum(normal_displacement_mm),
        sample_vm_mpa=maximum(von_mises_mpa),
        yield_ratio=maximum(von_mises_mpa) * 1e6 / c.fy
    )
end


# ==================== 主程序 ====================

function main()
    mkpath(OUT)
    CM.activate!()

    summaries = []

    for c in CASES
        @assert c.depth > c.b / 2
        @assert c.t > 0

        dir = joinpath(OUT, c.id)
        mkpath(dir)

        println("\nDrawing ", c.id, " ...")
        ship_scene(c, dir)

        println("Solving coarse mesh ", COARSE, " ...")
        coarse = solve_panel(c, COARSE)

        println("Solving fine mesh ", FINE, " ...")
        fine = solve_panel(c, FINE)

        # 中心挠度的网格加密变化
        change = abs(fine.center_mm - coarse.center_mm) /
                 max(fine.center_mm, 1e-15)

        println("Exporting mesh and pressure plots ...")
        plate_mesh_plot(c, fine, dir)

        println("Exporting stress and displacement clouds ...")
        result = results_plot(c, fine, dir)

        push!(
            summaries,
            (
                c=c,
                coarse=coarse,
                fine=fine,
                change=change,
                result=result
            )
        )

        @printf(
            "%s: center %.6f mm, mesh change %.2f%%, force %.3f kN\n",
            c.id,
            fine.center_mm,
            100change,
            fine.force / 1000
        )

        if change >= 0.05
            println(
                "Mesh change exceeds 5%; refine further before interpreting the deflection."
            )
        end
    end

    # 结果摘要
    open(joinpath(OUT, "summary.txt"), "w") do io
        println(
            io,
            "TWO DEMONSTRATION SHIPS: LOCAL CLAMPED OUTER PLATES"
        )
        println(
            io,
            "Units m/N/Pa. E=210 GPa, nu=0.30, seawater density=1025 kg/m3."
        )
        println(
            io,
            "Q2 three-dimensional solid elements; all four panel edges fixed."
        )

        for item in summaries
            c = item.c
            fine = item.fine
            result = item.result

            println(io, "\n", c.title)

            println(
                io,
                "Appearance L/B/D: ",
                (c.L, c.B, c.D),
                " m (illustrative hull)"
            )

            println(io, "Panel a/b/t: ", (c.a, c.b, c.t), " m")

            println(
                io,
                "Centre depth: ", c.depth,
                " m; speed: ", c.speed,
                " m/s; assumed Cp: ", c.cp
            )

            println(
                io,
                "Integrated force: ", fine.force,
                " N; analytic force check passed"
            )

            println(
                io,
                "Coarse/fine centre deflection: ",
                item.coarse.center_mm, " / ",
                fine.center_mm, " mm"
            )

            println(
                io,
                "Relative mesh change: ", 100item.change, " %"
            )

            println(
                io,
                "Energy-balance relative error: ",
                fine.energy_error
            )

            println(
                io,
                "Strain energy: ", fine.internal,
                " J; half load-work: ", fine.external, " J"
            )

            println(
                io,
                "Max sampled loaded-face deflection: ",
                result.max_w_mm, " mm"
            )

            println(
                io,
                "Max sampled loaded-face von Mises: ",
                result.sample_vm_mpa, " MPa"
            )

            println(
                io,
                "Sample stress / assumed yield strength: ",
                result.yield_ratio
            )

            println(
                io,
                "Deflection / thickness: ",
                result.max_w_mm / (1000c.t)
            )

            convergence_message = item.change < 0.05 ?
                "PASS for centre deflection only" :
                "REFINE further"

            println(
                io,
                "Mesh-change <5% screening: ",
                convergence_message
            )
        end

        println(
            io,
            "\nLimits: no actual lines plan, curved plating, stiffener flexibility, corrosion, welding, fatigue, buckling, plasticity, wave slamming or fluid coupling."
        )
        println(
            io,
            "Pressure=hydrostatic+assumed steady increment; not a classification-rule load."
        )
        println(
            io,
            "Sample stress maxima are not certified global extrema. No engineering approval implied."
        )
    end

    println("\nFinished. Results:")
    println(OUT)

    return nothing
end

end # module

Base.invokelatest(() -> TwoShipsFEM.main())