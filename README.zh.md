# sensfamily — 敏感性分析（jamovi 模块）

回答"未观测混杂变量要多强才会改变回归估计"：线性回归后的两个事后工具。 英文完整说明见 [README.md](README.md)。

## 分析（jamovi 菜单：Sensitivity > Regression）

| 分析 | 内容 |
|---|---|
| **遗漏变量偏误** | Cinelli 与 Hazlett (2020)：稳健值、以观测协变量为基准的界、等高线图 |
| **系数稳定性** | Oster (2019)：δ、偏误调整后的系数与界 |

每个分析的输出部分都有"方法说明"和"数据与设置指南"。

引擎为基础 R 编写，与 R 包 `sensemakr`、`robomit` 及 Stata 命令 `sensemakr`、`psacalc` 对照一致。匹配与加权估计的 E 值和 Rosenbaum 界在 `matchfamily`。示例数据：`darfur.csv`。

## 安装
- **jamovi 模块库**：在 jamovi 右上角打开模块按钮，进入 *jamovi library*，搜索并安装（模块上架后）。
- **侧载**：下载 `.jmo` 文件，在同一菜单选 *Install from file*。`.jmo` 只适用于构建它的操作系统、处理器类型和 jamovi 版本。
- **从源码**：需要 R 和 `jmvtools`：`jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")`（路径按本机 jamovi 修改）。

## 引用与许可
引用：Sun, M. *sensfamily* (jamovi module). https://github.com/mingchao-sun/sensfamily 。请同时引用所用方法的原始文献（输出中列出）。

许可：见 `DESCRIPTION`（GPL）；第三方代码与数据见 `NOTICE`。问题与建议：https://github.com/mingchao-sun/sensfamily/issues
