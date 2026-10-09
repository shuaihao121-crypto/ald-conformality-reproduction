# 两种模型的物理描述与数学结构

研究使用同一组名义工艺条件比较两种输运描述。A 通过压力场的解析近似，把输运转化为各位置的覆盖率演化；B 通过通道几何和反应概率，求出入射分子的最终吸附位置，再推进覆盖率。二者都描述前驱体曝光过程中的饱和吸附，但末端处理、输运计算和数值状态不同。

本文公式编号均来自 [Järvilehto 等，2023](https://doi.org/10.1039/D3CP01829F)。

## Model A：扩散–反应近似

论文 Eq. (1) 给出一维压力输运方程，Eq. (2) 用 Bosanquet 关系组合气相与 Knudsen 扩散：

$$
D_{\mathrm{eff}}=\left(D_A^{-1}+D_{\mathrm{Kn}}^{-1}\right)^{-1}.
$$

本工程采用论文及 DReaM-ALD 的解析压力近似，**没有直接离散和求解完整时空扩散 PDE**。压力分成入口处的线性下降区和吸附前沿的指数下降区：

$$
p_A(x,t)=
\begin{cases}
p_{A0}(1-x/x_s), & x<x_t,\\
p_t\exp[-(x-x_t)/(x_s-x_t)], & x\ge x_t,
\end{cases}
$$

其中 $x_s=\sqrt{Dt}$，$x_t$ 由 Eq. (6) 的扩散与吸附平衡长度决定，$p_t=p_{A0}(1-x_t/x_s)$。实现还计算局部碰撞频率、气相扩散系数以及 apparent longitudinal diffusion coefficient。后一计算沿用上游公式，不应把 $D$、$D_A$ 和 $D_{\mathrm{eff}}$ 混为一个参数。

覆盖率按 Langmuir 吸附与一阶脱附演化，见 Eq. (15)–(16)：

$$
\frac{d\theta}{dt}
=\frac{cQp_A}{q}(1-\theta)-P_d\theta,
\qquad
Q=\frac{N_A}{\sqrt{2\pi M_ART}}.
$$

$q$ 是饱和吸附容量，单位为 $\mathrm{m^{-2}}$；$c$ 是无量纲 sticking coefficient；$P_d$ 是 $\mathrm{s^{-1}}$。当前 $P_d=10^{-4}\ \mathrm{s^{-1}}$，其作用在基线下很小，但方程中仍然保留。

调用路径是 [run_modelA_case](../../src/ModelA_Reproduction/run_modelA_case.m) → [modelA_rhs](../../src/ModelA_Reproduction/modelA_rhs.m) → [pressure_modelA](../../src/ModelA_Reproduction/pressure_modelA.m)。`ode23` 积分的是空间网格上覆盖率组成的 ODE 向量。压力历史由 RHS 的 persistent 变量维护，其含义与适用限制详见 [数值实现](numerics.md)。

## Model B：弹道输运与吸收 Markov 链

在 Knudsen 条件下，分子主要与结构壁碰撞。B 假定立即热化和漫反射，使用几何 view factors 描述壁面之间的传输，不包含分子之间的气相碰撞。论文讨论其适用条件为 $\mathrm{Kn}\gg1$；不能直接把此模型用于任意压力或尺寸的连续流条件。

通道高度归一化为 1。入口和末端各占一个状态，每个墙段合并上下两壁：

$$
N_{\mathrm{seg}}=\operatorname{round}(ARf_s),
\quad \Delta h=AR/N_{\mathrm{seg}},
\quad S_{\mathrm{entry}}=S_{\mathrm{end}}=1,
\quad S_{\mathrm{wall}}=2\Delta h.
$$

这是 slit/trench 几何的相对面积表示。B 通过 $AR=L/H$ 使用通道尺寸，没有显式有限宽度侧壁修正。入口为退出状态；封闭末端是可以吸附和再发射的表面。

代码使用 `q(j,i)` 表示**从源 i 到目标 j**，与论文 $q_{ij}$ 的下标记法相反。每列概率和为 1，并满足面积互易关系：

$$
q_{ji}S_i=q_{ij}S_j.
$$

合并墙段的 self-view 是上下两壁同段之间的传输；几何上存在这类传输，所以对角项不是错误的“自己撞自己”。

局部不可逆反应概率为 Eq. (22)：$\beta_i=\beta_0(1-\theta_i)$。设 `sprob` 包含表面反应概率和入口的退出概率 1，则暂态传播矩阵和首次碰撞分布为：

$$
Q_{\mathrm{tr}}=q\operatorname{diag}(1-\mathrm{sprob}),
\qquad p_{\mathrm{in}}=q e_{\mathrm{entry}}.
$$

这里 $Q_{\mathrm{tr}}$ 与 A 的单位压力碰撞率 $Q$ 是不同量。当前代码把 Markov 暂态矩阵命名为 `Q`；跨模型讨论时需注明对象。

累计碰撞分布由线性系统求解：

$$
r=(I-Q_{\mathrm{tr}})^{-1}p_{\mathrm{in}}
=\sum_{m=0}^{\infty}Q_{\mathrm{tr}}^mp_{\mathrm{in}}.
$$

$r_i$ 可理解为单个入射分子在状态 i 的预期累计访问次数，或相对于入口总入射通量的段通量。$P_i=\mathrm{sprob}_i r_i$ 是最终吸收/退出概率，理想情况下满足：

$$
P_{\mathrm{exit}}+\sum_{i\in\mathrm{surface}}P_i=1.
$$

这份实现直接求解概率方程，不抽样随机轨迹、不选择随机反应事件、不使用 Gillespie 事件时钟。Markov 链刻画的是碰撞序列中的概率结构；实际计算是确定性的。

## B 的时间推进

论文 Eq. (20)–(24) 把概率结果转换为覆盖率变化：

$$
\frac{d\theta_i}{dt}
=s_0\frac{S_0}{S_i}f_0P_i,
\quad
f_0=\frac{N_Ap_{A0}}{\sqrt{2\pi M_ART}},
\quad
\tau=s_0f_0t.
$$

以 $a_i=1-\theta_i$ 表示可用位点比例，当前实现冻结一步内的 $r_i$，定义 $k_i=(S_0/S_i)\beta_0r_i$，随后：

$$
\Delta\tau=\frac{ep}{\max_i k_i},
\qquad a_i^{n+1}=\frac{a_i^n}{1+k_i\Delta\tau}.
$$

每一步重新求解反应概率随覆盖率改变的 Markov 系统。该方式沿用 Machball 0.2.0 的 `dose_ideal`；最后一步截断到曝光终点。保持 $0\le\theta\le1$ 需要非负且有效的通量和正步长；这一稳定更新形式本身并不证明时间离散误差足够小。

## 比较的共同点与差异

| 项目 | A | B |
|---|---|---|
| 表面动力学 | Langmuir 吸附＋脱附 | 不可逆 Langmuir 吸附 |
| 输运计算 | 线性/指数压力场近似 | 几何 view factors＋暂态线性系统 |
| 尺寸输入 | H、W、L 显式进入公式 | 当前只用 AR |
| 封闭末端壁 | 不作为独立碰撞/反应表面 | 独立表面状态 |
| 网格位置 | 包含 x=0 和 x=L 的点网格 | 墙段中心＋末端 |
| 数值状态 | 覆盖率和 RHS 压力历史 | 覆盖率和迭代求解初值 |

因此“参数相同”不代表每项边界处理和近似都相同。论文关注的正是这种模型选择对覆盖率分布和反推动力学的影响；本工程没有据此把任何一个模型认定为所有工艺条件下的真实答案。
