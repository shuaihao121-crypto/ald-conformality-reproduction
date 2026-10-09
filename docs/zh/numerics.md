# 数值实现、运行成本与验证边界

本版本保留原始数值源文件，封装层负责运行、归档和绘图。这里解释实际算法和已经知道的局限，帮助读者判断哪些性质通过检查，哪些还需要专门研究。[发布验证记录](../validation/release-checks.md) 是本次运行的证据；文末的大尺度故障检查属于此前整理调查，不能混写为本次发布新增的验证结果。

## A：网格、初始时间与压力历史

[run_modelA_case](../../src/ModelA_Reproduction/run_modelA_case.m) 使用 `Nx=round(fp*L/H)` 和 `linspace(0,L,Nx)`。基线有 2000 个点，包含入口与末端；间隔是 L/(Nx−1)，不严格等于 H/fp。返回的 `x_dim=x/H` 用于指标提取。

默认积分起点为 `tstart=1e-3 s`，起点的覆盖率仍为零。若允许，输出时间向量含 0.05 s，但这只是输出节点，不能视为固定内部积分步长。由于压力近似在 t=0 的尺度可能退化，上游使用非零起点；代价是起始区间的吸附没有被积分。短曝光与恒剂量高压短时条件对这种选择可能更敏感。原扫描脚本保留了 `tstart=[1e-3,1e-4,1e-5]` 的敏感性计算，但本次打包没有额外启动它。

[modelA_rhs](../../src/ModelA_Reproduction/modelA_rhs.m) 用 `persistent pA` 缓存前一次 **RHS 函数评估** 的压力。它不是“上一个 ode23 已接受时间步”的严格状态：显式 Runge–Kutta 会在一个尝试步内评估多个阶段，也可能拒绝步。故同一个 `(t,theta)` 的返回值可能受之前调用次序影响。该近似继承公开 DReaM-ALD；`clear modelA_rhs` 在每个独立 case 前清空历史，避免不同条件串用缓存，但没有消除单次积分内部的路径依赖。

当前调用未传 `odeset`，因此采用 MATLAB `ode23` 默认容差。上游 DReaM-ALD v1.0.0 显式设置 `RelTol=1e-3`、`AbsTol=1e-5`；默认 `RelTol=1e-3`、`AbsTol=1e-6` 的绝对容差不同。因而“同样使用 ode23”不足以断言逐点与上游完全一致。封装没有改此调用，也没有把历史数值包装成容差收敛结果。

入口还提供了一个不依赖内部输运近似的解析核对：在 x=0，pA=pA0 恒定，令 $a=cQp_{A0}/q$，从 tstart 的零覆盖率初值出发有 $\theta(0,t)=a/(a+P_d)\,[1-\exp(-(a+P_d)(t-t_{start}))]$。基线参数仅将 c 改为 0.1 时，解析终值约为 **0.999999963655**，而历史 ode23 输出为 **0.998586**，使该条件被 0.999 判据排除。这说明筛选差异还可能包含时间积分误差，不能只归因于论文没有规定饱和容差。当前归档保留历史输出和掩码；解析核对是后续容差研究的依据，不用于替换历史数据。

## B：几何存储和 matrix-free 运算

[geometry_modelB](../../src/ModelB_Reproduction/geometry_modelB.m) 用稳定的交叉截面函数 $F(z)=1/(z+\sqrt{1+z^2})$，通过一阶差分计算入口–墙段耦合，通过二阶差分计算墙段之间的 view factors。面积互易给出反向耦合，列守恒补齐 self-view。公式与 Machball 0.2.0 的 slit/trench 实现一致。

均匀墙段间的 off-diagonal matrix 是对称 Toeplitz。代码构造长度 2Nseg 的 circulant embedding；[qmul_modelB](../../src/ModelB_Reproduction/qmul_modelB.m) 给墙向量补零，FFT 相乘再 inverse FFT，取前 Nseg 项并补回自视、入口和末端贡献。`real` 去掉浮点 FFT 的虚部残差。这个实现没有用任意距离 cutoff 丢弃远程 view factors。

小系统 Nseg≤200 仍显式生成 q，作为 dense 调试参考。大系统只存一维核和耦合向量：几何存储约 O(N)，一次 q·v 约 O(N log N)。dense reference 则需要 O(N²) 内存，线性求解通常为 O(N³)。FFT 加速的对象是 matrix–vector multiplication，不代表完整时间积分具有固定运行成本。

## B：暂态 solve 与诊断

[markov_modelB](../../src/ModelB_Reproduction/markov_modelB.m) 的大系统分支使用 BiCGSTAB 求解 `(I-q*diag(nonreact))*r=p_in`，相对容差 1e-9、最大迭代数 500，无 preconditioner。时间积分用上一步 r 作下一步初值。这种 warm start 通常降低成本，但不是可证明的收敛保证。

应分别观察：线性残差、solver flag、r 的非负性和最终概率和。即使 residual 满足阈值，概率闭合误差也未必同量级；累积访问次数和弱吸收状态会放大某些误差。当前原始代码在 flag≠0 时 warning 后仍返回结果，主积分继续使用近似 r。封装保留日志中的 warning，没有修改失败处理，也没有自动把“脚本无 exception”升级为科学验证通过。

当前结果结构体没有保存整个时间过程的 solver diagnostics。原始传输函数返回 flag/residual/iteration，但 `run_modelB_case` 只保留最终 profile 和指标。需要检查运行 transcript，而不能从最后三个指标反推每一步都已收敛。

## B：步长和高反应概率运行

普通 `ep=0.05` 沿用 Machball 0.2.0。每一步最大 k 决定 `dtau=ep/max(k)`，覆盖率随后隐式更新，最后一步截断到 `tau_end`。对于 $k\Delta\tau=ep$ 的最快段，可用位点比例在单步后乘以 $1/(1+ep)$；因此 ep 的数值大小可以直接影响一次更新幅度。

原始 Case VI 扫描为节省成本设置：

| β₀ | ep |
|---:|---:|
| 1 | 2 |
| 0.1 | 0.2 |
| 0.01 及更小值 | 0.05 |

`ep=2` 可以让最快段在一次更新后仅保留三分之一的可用位点。覆盖率仍可保持有界，但大步长对演化轨迹、前沿位置和斜率的误差不能由有界性排除。现有 [test_modelB_beta1_ep](../../src/ModelB_Reproduction/test_modelB_beta1_ep.m) 仅比较 ep=5 与 2；不是向精细步长极限收敛的研究。

原扫描代码注释保留两组历史结果：ep=5 时 xhalf=370.569331、slope=0.073463、broadness=70.75；ep=2 时分别为 373.402663、0.070074、70.00。差异约为 0.76%、4.84%、1.07%，足以说明指标对数值设置存在可见敏感性，不能据此宣称 ep=2 已收敛。

## 指标筛选与边界值

A 以 θ(0)≥0.999 判入口饱和；B 以第一墙段中心覆盖率≥0.995 判入口附近饱和。B 该中心在 `x/H=dh/2`，入口状态本身是退出状态，没有表面覆盖率。两个不同阈值与不同位置都会影响纳入比较的条件，属于应公开的实施选择。

Half-depth 在没有下降穿越 0.5 时返回 NaN。Broadness 按离散 threshold 点差计算，具有网格量化：B fs=4 的墙段间隔为 0.25 个 x/H 单位；A 基线间隔约为 0.50025。纯零覆盖率 profile 的两个 threshold 搜索都落到首点，所以 raw broadness 可为 0，而不是有效前沿。筛选掩码应排除此类条件。B 末端 trunk 可使 profile 非单调，算法始终选择从入口遇到的第一次下降阈值，不能改成末端最后一次 crossing。

原始函数没有完整输入校验或迭代护栏，例如 ep=0 会使时间不能推进，过小 AR·fs 可 round 为零，负曝光时间可能静默绕过积分。封装接口的 options 校验不等于科学参数域已被全部校验。本版本示例只采用已有有效参数；未来改动应单独建立行为测试。

## 运行成本与发布检查

B 时间积分成本大致为时间步数乘以每步 Krylov 次数，再乘以 O(N log N)。高 β₀、长曝光、弱吸收/高覆盖率和大 AR 均可能增加成本。完整 `scan-b` 包含 41 个条件；`scan-a` 还附加起始时间敏感性试验。不能把小几何 smoke 时间或一次 frozen-surface solve 时间当成整套扫描的预计耗时。

本次发布只执行 [发布记录](../validation/release-checks.md) 中列出的有限检查。运行环境记录为 R2025b；其他 MATLAB 版本没有实际验证。模型本身是确定性计算，没有需要配置的随机采样 seed；不同 MATLAB/线性代数环境仍可能产生浮点与迭代差异。

### 整理调查中已观察到的大尺度局限

此前只读核查曾在 AR=4000、fs=4、N=16002 的**完全覆盖** profile 上，从默认初值单独求解 Markov 系统。理论上吸附为零、Pexit=1。实际 flag=1、relative residual=1.505e-4、Pexit=0.99568142023，概率闭合误差 4.319e-3。这是一项此前调查记录，**没有作为本次发布重新通过的测试**，也不是实际 warm-start 时间轨迹必然失败的证明。

它说明当前 maxit=500 对极端长通道弱吸收状态不足以提供无条件可靠性。未来可考虑显式保存每步诊断、拒绝失败解、配置求解上限、建立 preconditioner，并对 decreasing-ep 和分辨率做独立收敛研究。这些工作没有在本次保留实现的发布中实施。
