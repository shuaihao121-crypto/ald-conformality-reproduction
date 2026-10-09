# 公式、代码与论文图的对应关系

所有论文公式编号来自 [主论文 DOI 10.1039/D3CP01829F](https://doi.org/10.1039/D3CP01829F)。仓库同时保留 [源代码哈希清单](../../data/source_manifest.json)，方便核对工程整理前后的数值实现。这里的“对应”表示实现来源和变量关系，不代表所有图已在本次发布中重新计算。

## Model A 的公式链

| 论文位置 | 含义 | 代码位置与核对项 |
|---|---|---|
| Eq. (1) | 一维扩散–反应压力方程 | 理论起点；本工程没有直接离散求解完整 PDE |
| Eq. (2) | Bosanquet 有效扩散系数 | [pressure_modelA](../../src/ModelA_Reproduction/pressure_modelA.m)：`Deff=1/(1/DA+1/DKn)` |
| Eq. (3)–(4) | 近入口线性压力近似 | 同文件 `x(i)<xt` 分支 |
| Eq. (5) | 气体前沿特征位置 | 同文件 `xs=sqrt(D*t)` |
| Eq. (6) | 线性与指数区的连接点 | 同文件 `aux/xt`；若 xs≤aux，xt=0 |
| Eq. (7) | 单位压力碰撞率 | 同文件及 [modelA_rhs](../../src/ModelA_Reproduction/modelA_rhs.m)：`Q=NA/sqrt(2*pi*MA*R*T)` |
| Eq. (8)–(9) | 指数压力尾部 | `pt` 与 `exp(-(x-xt)/(xs-xt))` |
| Eq. (10)–(14) | 容量与吸附/脱附定义 | [parameters_modelA](../../src/ModelA_Reproduction/parameters_modelA.m) 直接输入 q；当前未用 Eq. (11) 重新反推容量 |
| Eq. (15)–(16) | 覆盖率 ODE | `modelA_rhs` 返回 `c*Q*pA/q*(1-theta)-Pd*theta` |
| §2.1 的数值说明 | ode23 积分 | [run_modelA_case](../../src/ModelA_Reproduction/run_modelA_case.m) 中的 `ode23` 调用 |

`pressure_modelA` 中的碰撞频率 zA、DA、K 与 apparent D 还沿用 DReaM-ALD / Ylilammi 模型的公式。主论文没有对每一个中间量重新编号，不能为了让映射表完整而杜撰额外方程编号。[references.bib](../../references.bib) 中的 Ylilammi 2018、Yim 2022 和 DReaM-ALD v1.0.0 给出了相应来源。

## Model B 的公式链

| 论文位置 | 含义 | 代码位置与核对项 |
|---|---|---|
| Eq. (17) | 段间通量平衡 | [markov_modelB](../../src/ModelB_Reproduction/markov_modelB.m) 的 frozen-surface system |
| Eq. (18)–(19) | 传输、退出、反应概率与 Markov 传播 | `sprob`、`nonreact`、`Q=q.*nonreact'` 与 `(I-Q)r=p_in` |
| Eq. (20) | incident flux 对覆盖率的贡献 | [run_modelB_case](../../src/ModelB_Reproduction/run_modelB_case.m) 的 `k` 与 available-site update |
| Eq. (21) | s₀=1/q | 两模型参数文件；Case VII 的倒数配对 |
| Eq. (22) | βᵢ=β₀(1−θᵢ) | `markov_modelB` 的 `beta=beta0.*(1-theta)` |
| Eq. (23) | 吸附概率与段通量的换算 | `P_ads=beta.*r_surface`；入口和段面积比 |
| Eq. (24) | 覆盖率变化率 | `k=(entry_area/area_surface)*beta0*r_surface`，时间单位 τ=s₀f₀t |
| §2.2 的几何定义 | 入口、合并墙段、末端 | [geometry_modelB](../../src/ModelB_Reproduction/geometry_modelB.m) 的索引、面积与坐标 |
| 上游 Machball `dose_ideal` | 自适应隐式步进的具体实现 | `dtau=ep/max(k)`、末步截断、`av/(1+k*dtau)` |
| 本地性能实现 | Toeplitz/FFT 与迭代 solve | [qmul_modelB](../../src/ModelB_Reproduction/qmul_modelB.m) 和 `markov_modelB` 的 matrix-free branch |

论文 $q_{ij}$ 表示从 i 到 j，代码 `q(j,i)` 表示同一事件。核对时应先统一记号，不能仅凭矩阵下标判定转移方向有误。入口的 `sprob=1` 表示退出吸收，重新进入的入口通量只由 `p_in` 提供。

## 提取指标与有效性规则

| 指标 | 论文定义 | 两个 run_case 的实现 |
|---|---|---|
| 半覆盖渗透深度 | 第一处 θ≤0.5 与前一点线性插值 | 搜索 `idx05`，计算 `x_half` |
| 半覆盖绝对斜率 | 上述两点的局部割线绝对值 | `abs((th2-th1)/(x2-x1))` |
| 前沿 broadness | 第一处 θ<0.1 减第一处 θ<0.9 的离散位置 | 搜索 `idx01/idx09`，取坐标差；没有插值 |
| Fig. 4 有效性 | 入口饱和、全通道未饱和且可提取 half | 扫描中的 `valid4`，并检查有限值 |
| Fig. 5 有效性 | 入口饱和、其余至少一处 θ<0.1 | 扫描中的 `valid5` |

论文没有规定“等于 1”的数值容差。A 的 0.999 与 B 的 0.995 是本地筛选，实际采样位置也不同。历史表保留筛选信息，不把已排除条件的缺失指标擅自解释为不存在 crossing。

## 图形与任务

| 论文图 | 工程入口 | 当前证据 |
|---|---|---|
| Fig. 1 | 无独立复绘任务 | 理论示意；由 [models](models.md) 解释 |
| Fig. 2 | B 的 `scan_modelB_resolution` 及 A 的历史调试 | 部分分辨率检查；不覆盖论文全部两种长度、五种分辨率 |
| Fig. 3 | `ald_repro('scan-a')` / `scan-b` | 八组 profile 脚本与历史报告图；本次没有重新跑完整扫描 |
| Fig. 4 | 同上 | half/slope 扫描；保留各模型筛选规则 |
| Fig. 5 | 同上 | 离散 broadness 扫描 |
| Fig. 6 | `compare-historical` / `replot-historical` | 前者新算 A＋历史 B；后者从已留存 I–VII 指标重绘 |
| Fig. 7 | 无独立全图任务 | resolution、geometry 与末端效应的物理解释 |

## 已保存的图像

这些截图来自历史汇报中的科学结果图；它们没有被当成新的数字数据源：

| 模型 | Profile 图 | Half / slope 图 | Broadness 图 | Parity 图 |
|---|---|---|---|---|
| A | [Figure 3](../assets/historical/model-a-figure3.png) | [Figure 4](../assets/historical/model-a-figure4.png) | [Figure 5](../assets/historical/model-a-figure5.png) | 由 B 汇报保存 |
| B | [Figure 3](../assets/historical/model-b-figure3.png) | [Figure 4](../assets/historical/model-b-figure4.png) | [Figure 5](../assets/historical/model-b-figure5.png) | [Figure 6](../assets/historical/model-b-figure6.png) |

新绘制的 [historical parity](../assets/historical_parity.png) 使用历史数值表而非截图取点，输出还有 [PDF](../assets/historical_parity.pdf) 与 [SVG](../assets/historical_parity.svg)。数据精度受原输出的小数位限制；图形质量提高不会增加历史数字的有效位数。

## 引用层级

主论文规定本次比较的参数、指标和结论；DReaM-ALD v1.0.0 与 Machball 0.2.0 提供公开实现的来源；当前仓库提供独立复现代码的保存、封装和结果归档。引用时保留这三个层级，避免把封装维护者写成原始模型作者，或把历史重新绘图写成一次新的完整复现实验。
