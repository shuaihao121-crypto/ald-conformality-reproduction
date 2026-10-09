# ALD 微通道共形性复现：中文技术文档

本工程复现 Järvilehto 等在 *Physical Chemistry Chemical Physics* 2023 年发表的双模型比较研究：[DOI 10.1039/D3CP01829F](https://doi.org/10.1039/D3CP01829F)。研究对象是横向高深宽比微通道内，一次前驱体曝光后的表面覆盖率分布。核心问题是：在名义工艺参数一致时，扩散–反应描述与弹道输运–反应描述，会如何改变渗透深度和吸附前沿？

这个版本整理已有研究工程，保留原始数值代码，补充可移植运行入口、数据来源、图形导出和验证记录。原始扫描定义论文 Table 2 的八组参数；周报记录了八组扫描及比较的完成情况。可独立核对的逐点数据、报告汇总和本次小规模验证各有覆盖范围，阅读结果时需要保留这一区别。

## 阅读路径

| 文档 | 要解决的问题 |
|---|---|
| [模型与假设](models.md) | A、B 分别求解什么；哪些物理假设导致模型差异？ |
| [参数、单位与八组扫描](parameters.md) | Table 2 如何落到 SI 单位和参数结构体；哪些值是数值设置？ |
| [公式、代码与论文图的对应](traceability.md) | 一个公式、指标或图形应该到哪里核对？ |
| [数值实现与验证边界](numerics.md) | 压力历史、ODE、Markov、FFT 和步长实际如何实现？ |
| [已有结果与差异解释](results.md) | 哪些结果有逐点证据，哪些仅有汇总；统计口径为何不同？ |
| [物理过程与工艺解读](physics.md) | 共形性、剂量、末端 trunk 和动力学参数应怎样理解？ |

建议先读模型和参数，再沿公式映射查源代码。评估结果可信度时，结合 [历史覆盖记录](../validation/history-coverage.md) 与 [发布验证记录](../validation/release-checks.md)。

## 最短运行路径

在 MATLAB 中把当前目录设为仓库根目录：

```matlab
addpath(pwd);
ald_repro;                       % 查看任务；默认不运行模拟
ald_repro('smoke');              % 小规模一致性检查
ald_repro('replot-historical');  % 从历史逐点表重画 I–VII 的 parity 图
```

`replot-historical` 读取历史指标，不重新求解 A 或 B。`baseline-a`、`baseline-b` 调用原始单例函数；`scan-a`、`scan-b` 启动原始八组扫描。`scan-a` 还会运行原脚本末尾的起始时间敏感性计算。`compare-historical` 重新计算 A，但 B 使用原脚本里的历史硬编码指标，因此属于混合证据比较。

```matlab
options = struct('OutputDir', fullfile(pwd, 'results', 'example'), ...
                 'ExportFigures', true, 'FigureVisible', 'off');
ald_repro('replot-historical', options);
```

三项 options 只控制输出与显示，不改变原始物理参数或数值方法。输出目录记录 manifest、日志、workspace 和适用的 CSV/图形。完整扫描，尤其 B 的高反应概率条件，可能耗时很长；本版本没有为打包重新执行全尺度扫描。

发布检查使用 MATLAB **R2025b**。封装目标为 R2020a 及以后版本，其他版本未实测；不能把目标版本范围理解为兼容性已验证。

## 数据与证据

- [历史逐点指标](../../data/historical/metrics.csv)：包含八组、两个模型的 82 个条件记录及缺失状态。缺失字段不补零，也不由截图拟合生成。
- [历史统计汇总](../../data/historical/historical_summary.json)：分开列出可从逐点记录复算的 I–VII 结果与八组报告汇总。
- [历史来源说明](../../data/historical/sources.json)：说明数值来自聊天中的运行输出、源代码数组或报告。
- [原始源代码清单](../../data/source_manifest.json)：21 个 `.m` 文件的来源和哈希，支撑源代码保留策略。
- [论文与软件文献](../../references.bib)、[软件引用信息](../../CITATION.cff) 和 [第三方声明](../../THIRD_PARTY_NOTICES.md)：提供模型、实现与许可的出处。

原报告截图属于历史结果证据；重新绘制的 parity 图来自已留存数值。历史完整覆盖率数组没有留存，因此本工程没有用图像像素伪造新的数值曲线。

## 当前结论的范围

已有逐点结果支持：B 的半覆盖渗透一般更深，A 的半覆盖斜率一般更大，B 的吸附前沿一般更宽。B 还包含封闭末端壁，可出现覆盖率在末端回升的 trunk。数值实现继承了 A 的压力历史近似、非零起始时间，以及 B 的部分高反应概率加速设置和失败解处理方式；这些因素均在 [数值文档](numerics.md) 中说明。

输出是特定曝光条件下的分数表面覆盖率。它没有自动成为多周期膜厚预测、实验校准模型或多组分氧化物生长模型。后续方法改进应独立于这份保留历史工程的发布版本，并重新建立数值比较证据。
