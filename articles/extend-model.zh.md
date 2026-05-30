# 扩展一个模型

## 面向贡献者的目标

这份文档说明在 `eam` 中加入一个新的 evidence accumulation process
时，需要经过哪些接口层。这里的“新模型”特指积累过程本身不同：状态如何更新、边界如何判断、竞争或泄漏如何发生、是否需要额外参数等。它不包括新的数据管线、新的输出格式，或新的后处理协议。

因此，一个新的 backend
可以需要新的输入参数，也可以在结果中补充自己有用的额外列；但它应该遵守最小输出惯例。只要这些惯例列存在，现有
plot、summary、ABC/ABI
等数据管线就应当继续工作。贡献者的目标是把新的积累过程接入现有
simulation config、R wrapper、Rcpp backend
和后续分析管线，而不是让用户为了基本工作流学习另一套数据格式。

在现有工作流里，用户通常只写一份 simulation config：

``` r

config <- new_simulation_config(
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  n_conditions = 500,
  n_trials_per_condition = 100,
  n_items = n_items,
  max_reached = n_items,
  max_t = 100,
  dt = 0.01,
  noise_mechanism = "add",
  noise_factory = noise_factory,
  model = "ddm"
)

sim_output <- run_simulation(config)
```

`demo/demo_abc.R` 展示了这个调用链在完整 ABC 工作流里的位置：先通过
[`new_simulation_config()`](https://y-guang.github.io/eam/reference/new_simulation_config.md)
定义模型、参数公式、噪声机制和模拟规模；再用
[`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md)
生成模拟数据；随后把输出整理成 summary statistics 并交给 ABC 或
posterior predictive check。扩展新积累过程时，最重要的原则是：新 backend
应该能被这个调用链自然使用，而不是要求用户绕过现有配置系统。

## 当前调用链

扩展模型前，建议先沿着下面的路径读一遍代码：

``` text
new_simulation_config()
  -> route_model_to_backend()
  -> run_simulation()
  -> run_condition()
  -> run_trial_*()
  -> accumulate_evidence_*()
```

各层的责任如下：

[`new_simulation_config()`](https://y-guang.github.io/eam/reference/new_simulation_config.md)
负责收集用户给出的公式、模拟规模、噪声设置和 `model` 名称。它会调用
router，把用户级模型名称解析成内部 backend 名称。

[`route_model_to_backend()`](https://y-guang.github.io/eam/reference/route_model_to_backend.md)
位于 `R/simulation_router.R`。它通过 detector 列表决定某个 config
应该交给哪个 backend。现有 backend 包括 `"ddm"`、`"ddm-2b"` 和
`"lca-gi"`。

[`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md)
负责分块、串行或并行执行、写出结果，并返回 simulation output
对象。贡献者通常不需要改变高层输出对象。

[`run_condition()`](https://y-guang.github.io/eam/reference/run_condition.md)
位于 `R/simulation.R`。它把一个 condition 展开为多个 trial，然后根据
`config$backend` 调用对应的 `run_trial_*()`。

`run_trial_*()` 位于 `R/simulation_models.R`。这一层是 R 侧模型描述与
C++ 积累过程之间的连接层。每个 backend 都应该有自己的
`run_trial_*()`，用于把 formula system 评估出的参数整理成 C++ backend
需要的参数向量，并负责处理默认值，例如没有提供 `Z` 时使用零向量。

`accumulate_evidence_*()` 是 Rcpp 导出的核心模拟函数，定义在
`src/*.cpp`。每个真正不同的积累过程都应该有自己的
`accumulate_evidence_*()`。它只负责单个 trial 内部的 evidence
accumulation：初始化状态、按 `dt`
更新证据、调用噪声函数、判断边界、返回结果。Rcpp 绑定由
[`Rcpp::compileAttributes()`](https://rdrr.io/pkg/Rcpp/man/compileAttributes.html)
生成到 `R/RcppExports.R` 和 `src/RcppExports.cpp`。

## 最小输出惯例

新增 evidence accumulation process 时，data pipe
部分通常不应改动。也就是说，贡献者不应为了新 backend 修改
flatten、simulation output、ABC input、ABI input 或 plotting
的基本数据读取方式。更稳妥的做法是让新 backend
返回一组最小惯例列，并在此基础上附加额外列。

目前 flatten 逻辑会从每个 trial 返回的 named list
中动态读取列名，并自动附加：

- `condition_idx`
- `trial_idx`
- `rank_idx`
- trial result columns
- condition parameter columns

这里的关键约定是：同一个 backend 的 trial result columns
必须稳定；每个返回列必须是同长度向量；第一列通常是
`item_idx`，其长度会被用于计算该 trial
产生多少行。现有下游工作流默认使用 `item_idx` 和 `rt`。如果 backend
属于现有 two-boundary response 语义，并且需要 accuracy 逻辑，应复用现有
`choice` 约定。

换句话说，新积累过程可以改变“如何产生反应”，也可以记录更多模型内部信息；但它至少应该用既有列名记录基本反应。额外列可以保留给贡献者自己的
summary statistics、diagnostics
或后续分析使用，只要它们不替代最小惯例列。

## 后续处理的依赖点

当前多数后续处理函数不依赖模型名，而是依赖输出列：

- [`plot_rt()`](https://y-guang.github.io/eam/reference/plot_rt.md) 选择
  `rt` 以及用户给出的 facet columns。
- [`build_abc_input()`](https://y-guang.github.io/eam/reference/build_abc_input.md)
  使用用户自己准备的 summary statistics，不直接判断 backend。
- [`build_abi_input()`](https://y-guang.github.io/eam/reference/build_abi_input.md)
  使用用户传入的 `Z` 列名，并依赖
  `condition_idx`、`trial_idx`、`rank_idx` 来补齐矩阵。
- [`flatten_simulation_results()`](https://y-guang.github.io/eam/reference/flatten_simulation_results.md)
  动态读取 trial 返回的列名，但要求每个 trial 的结果结构一致。
- `posterior_predictive_check.resolve_plot_columns()`
  只检查模拟数据和观测数据的共享列。

需要特别注意的是
[`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)。它目前读取
`simulated_output$simulation_config$backend`，并按 backend 分派：

- `"ddm"` 使用
  [`plot_accuracy_ddm()`](https://y-guang.github.io/eam/reference/plot_accuracy_ddm.md)，基于
  `rt` 是否缺失计算 hit rate。
- `"ddm-2b"` 使用
  [`plot_accuracy_ddm_2b()`](https://y-guang.github.io/eam/reference/plot_accuracy_ddm_2b.md)，基于
  `choice == 1` 计算 accuracy。

因此，如果新 backend 需要支持
[`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
或 posterior predictive check 中的 accuracy
plot，贡献者需要确认它应该复用哪一种现有 accuracy 语义，并在
[`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
中显式把新 backend 接到对应 helper。额外输出列可以存在，但基本 accuracy
逻辑仍应优先依赖既有惯例列。

## 推荐扩展计划

### 1. 明确积累过程契约

在写代码前，先决定新积累过程的最小公共契约：

- backend 名称，例如 `"my-model"`。
- 用户可以在 `model` 中写哪些别名，例如 `"my"`、`"my-model"`。
- `item_formulas` 必须提供哪些 item-level 参数。
- 哪些参数可以有默认值，例如现有模型中的 `Z`。
- `noise_factory` 的输出如何进入模型。
- 最小输出应复用哪一种现有结果约定。

不要把新 backend
的设计从输出列开始。应该先确定它与现有输出语义的关系：是返回 `item_idx`
和 `rt` 的单边界过程，还是返回 `item_idx`、`rt` 和 `choice` 的
two-boundary 过程。在满足这些最小惯例之后，可以加入额外的 trial result
columns，例如内部状态、边界类型或诊断量。

### 2. 在 `src/` 中实现 C++ 积累过程

在 `src/` 下新增或扩展一个 C++
文件，提供一个核心函数，命名建议遵循现有模式：

``` cpp
// [[Rcpp::export]]
Rcpp::List accumulate_evidence_my_model(
  Rcpp::NumericVector A,
  Rcpp::NumericVector V,
  Rcpp::NumericVector Z,
  Rcpp::NumericVector ndt,
  double max_t,
  double dt,
  int max_reached,
  Rcpp::Function noise_func
);
```

这里的签名只是示意。真实参数应由积累过程契约决定。更重要的是保持几个约定：

- 输入参数来自 R 层 wrapper 已经评估好的向量。
- 对长度、正值、边界等基本条件做清晰检查。
- 通过 `Rcpp::stop()` 抛出用户可理解的错误。
- 返回一个 named `Rcpp::List`，并至少包含现有结果列惯例。
- 使用 `// [[Rcpp::export]]`，让 Rcpp 生成 R 层绑定。

完成 C++ 函数后，运行：

``` r

Rcpp::compileAttributes()
```

这会更新 `R/RcppExports.R` 和
`src/RcppExports.cpp`。不要手动编辑这些生成文件。

`accumulate_evidence_*()` 是模型行为真正发生的地方。它应该只关心单个
trial 内部的机制，而不关心 condition chunk、Arrow dataset、ABC summary
或 plotting。这种边界很重要：只要最小输出惯例保持不变，后面的 data pipe
就不需要知道内部积累过程发生了什么；额外列会随 flatten
结果一起进入数据集，供需要它们的分析使用。

### 3. 增加 R 层 trial wrapper

在 `R/simulation_models.R` 中增加一个 `run_trial_*()` wrapper。每个
backend 都应该有一个专属 wrapper。它的职责不是重新实现模型，而是把
config 中的 formula system 与 C++ backend 接起来：

``` r

run_trial_my_model <- function(
    trial_setting,
    item_formulas,
    n_items,
    max_reached,
    max_t,
    dt,
    noise_mechanism,
    noise_factory,
    trajectories = FALSE) {
  item_params <- evaluate_with_dt(
    item_formulas,
    data = trial_setting,
    n = n_items
  )
  noise_fun <- noise_factory(trial_setting)

  Z <- if (is.null(item_params$Z)) rep(0, n_items) else item_params$Z

  sim_result <- accumulate_evidence_my_model(
    item_params$A,
    item_params$V,
    Z,
    item_params$ndt,
    max_t,
    dt,
    max_reached,
    noise_fun
  )

  if (trajectories) {
    sim_result$.item_params <- item_params
  }

  sim_result
}
```

这个 wrapper 是贡献者最应该保持稳定的一层。它决定了用户在
`item_formulas` 里写的参数名如何映射到 C++
函数的参数位置，也决定哪些参数有默认值、哪些参数必须由用户提供。

在现有代码中：

- [`run_trial_ddm()`](https://y-guang.github.io/eam/reference/run_trial_ddm.md)
  评估 `A`、`V`、`ndt`，默认 `Z = 0`，再调用
  [`accumulate_evidence_ddm()`](https://y-guang.github.io/eam/reference/accumulate_evidence_ddm.md)。
- [`run_trial_ddm_2b()`](https://y-guang.github.io/eam/reference/run_trial_ddm_2b.md)
  评估 `A_upper`、`A_lower`、`V`、`ndt`，默认 `Z = 0`，再调用
  [`accumulate_evidence_ddm_2b()`](https://y-guang.github.io/eam/reference/accumulate_evidence_ddm_2b.md)。
- [`run_trial_lca_gi()`](https://y-guang.github.io/eam/reference/run_trial_lca_gi.md)
  评估 `A`、`V`、`ndt`、`beta`、`k`，默认 `Z = 0`，再调用
  [`accumulate_evidence_lca_gi()`](https://y-guang.github.io/eam/reference/accumulate_evidence_lca_gi.md)。

新 backend 应该遵循同样结构：R wrapper 负责“把模型参数准备好”，C++
backend 负责“运行积累过程”。不要把 formula evaluation 搬到 C++，也不要在
C++ 中读取 config。

### 4. 在 router 中注册 backend

在 `R/simulation_router.R` 中新增 detector，并把它加入
[`get_backend_detectors()`](https://y-guang.github.io/eam/reference/get_backend_detectors.md)：

``` r

detect_backend_my_model <- function(model_lower, config) {
  switch(model_lower,
    "my" = "my-model",
    "my-model" = "my-model",
    NULL
  )
}
```

如果模型可以通过参数结构自动识别，可以使用
`get_config_env_names(config)` 检查 formula 左侧变量。例如现有 `"ddm"`
会根据 `A` 或 `A_upper` 的存在区分不同 backend。

注册时要避免让多个 detector 同时匹配同一份 config。router 已经会在
ambiguous backend 时停止，所以新增 detector
后应当特别检查常见别名是否与现有模型冲突。

### 5. 接入 `run_condition()`

在 `R/simulation.R` 的 backend 校验和 `switch(backend, ...)` 中加入新
backend：

``` r

if (!backend %in% c("ddm", "ddm-2b", "lca-gi", "my-model")) {
  stop("backend must be one of the registered backend names")
}

switch(backend,
  "my-model" = run_trial_my_model(...)
)
```

如果并行路径使用
[`parallel::clusterExport()`](https://rdrr.io/r/parallel/clusterApply.html)，也要把新的
`run_trial_*()` 和 `accumulate_evidence_*()`
加入导出列表。否则串行模拟可能正常，而并行模拟会找不到函数。

如果新 backend 的 accuracy 语义与已有 backend 相同，也要检查
[`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
是否需要新增一个分支。例如，一个返回 `choice` 且语义等同于 `"ddm-2b"` 的
backend，可以在
[`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
中复用
[`plot_accuracy_ddm_2b()`](https://y-guang.github.io/eam/reference/plot_accuracy_ddm_2b.md)；一个只用
`rt` 缺失表示未命中的 backend，可以复用
[`plot_accuracy_ddm()`](https://y-guang.github.io/eam/reference/plot_accuracy_ddm.md)。

### 6. 验证用户级工作流

新增 backend 后，至少用一份很小的 config 验证完整调用链：

``` r

config <- new_simulation_config(
  prior_formulas = list(
    V ~ distributional::dist_uniform(0.1, 1),
    ndt ~ 0.3,
    noise_coef ~ 1
  ),
  between_trial_formulas = list(),
  item_formulas = list(
    A ~ 1,
    V ~ V
  ),
  n_conditions = 2,
  n_trials_per_condition = 3,
  n_items = 4,
  max_reached = 4,
  max_t = 5,
  dt = 0.01,
  noise_factory = noise_factory,
  model = "my-model",
  parallel = FALSE
)

sim_output <- run_simulation(config)
sim_output$open_dataset()
```

重点不是生成大量数据，而是确认：

- [`new_simulation_config()`](https://y-guang.github.io/eam/reference/new_simulation_config.md)
  能正确识别 backend。
- [`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md)
  能完成一个最小模拟。
- 输出列能被 `open_dataset()` 读取，并至少包含既有最小惯例列。
- 同一 config 在 `parallel = TRUE` 时也能运行。
- 错误信息对缺失参数、错误长度和非法取值足够清楚。
- 如果支持 accuracy
  plot，[`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
  和 posterior predictive check 能找到对应 backend 分支。

### 7. 补测试和文档

测试应覆盖两类风险：

- router 是否把别名和参数结构解析到正确 backend。
- 一个最小 config 是否能串行、必要时并行地跑通。
- 下游函数是否仍能按既有最小惯例列读取结果。
- 如果新增了
  [`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
  分支，accuracy 逻辑是否与该 backend 的输出语义一致。

如果新模型引入了新的用户可见参数名或限制，应更新
[`new_simulation_config()`](https://y-guang.github.io/eam/reference/new_simulation_config.md)
的模型说明、相关 examples，以及面向用户的 model vignette。若只是内部
backend 变化，也应在开发者文档或 NEWS 中说明。

## 贡献前检查清单

- C++ backend 位于 `src/`，并通过
  [`Rcpp::compileAttributes()`](https://rdrr.io/pkg/Rcpp/man/compileAttributes.html)
  生成绑定。
- R wrapper 位于 `R/simulation_models.R`，只负责参数评估、默认值和调用
  backend。
- Router detector 位于 `R/simulation_router.R`，并已加入
  [`get_backend_detectors()`](https://y-guang.github.io/eam/reference/get_backend_detectors.md)。
- [`run_condition()`](https://y-guang.github.io/eam/reference/run_condition.md)
  的 backend 校验和 switch 已更新。
- 并行执行需要的函数已加入
  [`parallel::clusterExport()`](https://rdrr.io/r/parallel/clusterApply.html)。
- 最小 config 能通过
  [`new_simulation_config()`](https://y-guang.github.io/eam/reference/new_simulation_config.md)、[`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md)
  和 `open_dataset()`。
- 输出结构至少包含现有最小惯例列，不要求 data pipe
  为基本工作流做新分支。
- 如需 accuracy
  plot，[`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
  已把新 backend 接到合适的现有 accuracy helper。
- 新增或更新了 testthat 测试。
- 没有手动编辑 `man/` 文件或 Rcpp 生成文件之外的生成内容。

## 何时不需要新 backend

并不是所有模型变化都需要新增 C++
backend。如果只是改变参数的先验、条件层级、trial-level
variability、item-level covariate，或改变噪声函数，通常可以直接通过
`prior_formulas`、`between_trial_formulas`、`item_formulas` 和
`noise_factory` 完成。

只有当 evidence accumulation 的核心状态更新、边界判断、竞争机制或 trial
输出结构发生变化时，才建议新增
backend。这样可以保持包的公共接口稳定，也能让贡献集中在真正需要扩展的地方。
