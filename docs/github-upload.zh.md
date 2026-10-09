# GitHub 上传与首版发布

仓库名：`ald-conformality-reproduction`。版本：`v0.1.0`。

这份指南对应已经整理的发布包。上传目录中的源码、数据、文档和检查程序；新运行产生的 `results/` 保留在本地。初版用现有历史数据展示成果，并清楚说明模型与数据边界。

## 推荐的仓库信息

**Description**（可直接复制）：

```text
MATLAB reproduction of diffusion–reaction and ballistic transport–reaction models for ALD conformality in lateral high-aspect-ratio channels, with traceable historical data and numerical checks.
```

**Topics**：

```text
atomic-layer-deposition
ald
matlab
scientific-computing
reproducible-research
markov-chain
reaction-diffusion
ballistic-transport
high-aspect-ratio
```

使用公开仓库可以让首页、源码、数据及许可说明被其他研究者查看。维护者信息为白子豪 / Zihao Bai；原模型作者和上游实现的贡献单独保留在引用及第三方声明中。

## 路径一：Git 推送（推荐）

1. 在 GitHub 创建一个名为 `ald-conformality-reproduction` 的空仓库。创建时不自动添加 README、`.gitignore` 或许可证，这些文件已在发布包里。
2. 解压 ZIP，在包含 `README.md` 和 `ald_repro.m` 的项目根目录打开 PowerShell。
3. 用下面命令初始化和检查本地仓库：

```powershell
git init -b main
git add .
git diff --cached --stat
git status --short
git commit -m "Release v0.1.0: archive ALD conformality reproduction"
```

`.gitattributes` 会保留 21 个历史 MATLAB 源文件的原始字节，避免 Windows 换行转换破坏已记录的哈希。若首次提交提示缺少 Git 姓名或邮箱，用你自己的身份完成 Git 配置后再提交。

4. 从你刚创建的 GitHub 仓库页面复制 HTTPS 地址，在下列命令中替换示例地址：

```powershell
git remote add origin https://github.com/YOUR_USERNAME/ald-conformality-reproduction.git
git push -u origin main
```

认证使用 GitHub 自己的登录流程。无需把访问令牌写入工程、README 或聊天记录。

5. 首次推送后打开 **Actions**，查看 `Archive checks` 工作流结果。该工作流检查归档完整性、统计一致性和本地文档链接，不运行 MATLAB。
6. 检查 README 的 Mermaid 流程图、三面板图片、中文文档链接和引用是否正常显示。你实际看到 Actions 成功后，才可以把相应的动态状态徽章加入首页。

## 路径二：网页上传

在空仓库页面选择 **Add file → Upload files**，上传项目根目录下的内容。为确保 `.github`、`.gitattributes`、`.gitignore` 等以点开头的文件一起上传，Git 推送更可靠。

网页单次上传有文件数量和大小限制。若页面要求分批上传，保持目录结构；不要把整个项目额外包在第二层同名目录中。ZIP 应作为 Release 附件上传，而不是作为唯一的仓库文件。

上传后核对 `.github/workflows/archive-checks.yml` 是否存在，以及 Actions 是否执行。

## 创建 v0.1.0 Release

代码和归档检查正常后，可以建立版本标签：

```powershell
git tag -a v0.1.0 -m "ALD conformality archival reproduction v0.1.0"
git push origin v0.1.0
```

在 GitHub 的 **Releases → Draft a new release** 中选择 `v0.1.0`，标题为：

```text
v0.1.0 — Traceable MATLAB reproduction of ALD conformality models
```

以下 Release 正文可直接使用：

```markdown
This first release organizes an independent MATLAB reproduction of the
diffusion–reaction and ballistic transport–reaction models compared by
Järvilehto et al., PCCP (2023), DOI: 10.1039/D3CP01829F.

Included:
- 21 byte-preserved original MATLAB source files with SHA-256 provenance;
- a portable task runner, structured run records and figure exports;
- recoverable historical metrics with explicit missingness and screening;
- a regenerable Cases I–VII parity figure (26/26/24 paired conditions);
- small-system checks and detailed Chinese technical documentation;
- upstream citations, license texts and known numerical limitations.

This is an archival and packaging release. The original scientific solver
settings are preserved. Reported eight-case aggregates remain separate
from statistics independently recomputed from available point data.
Full-scale scans were not rerun for this release.
```

Release 附件建议上传项目 ZIP 和其 `.sha256` 文件。GitHub 自动生成的源码 ZIP 属于 Git 仓库快照；本次交付的 ZIP 是经过检查的发布目录。

## 本地校验与运行

解压后在项目根目录执行：

```powershell
python checks/validate_repository.py
matlab -batch "addpath(pwd); ald_repro('smoke'); ald_repro('replot-historical');"
```

MATLAB R2025b 是已核查环境。其他版本的兼容性和完整扫描收敛性见技术文档。公开归档中没有私人聊天原文、导师沟通文件、MATLAB 安装文件或认证信息。

## 发布后的维护建议

首版保持现有模型和历史数据可追溯。后续修正压力历史、迭代求解失败处理或时间步设置时，建立新的版本和清楚的数值对比记录。新增实验或模型验证结果应带完整配置和运行清单，以便读者区分历史成果与新结果。
