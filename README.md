# Konza草原火烧实验生态数据分析

## 📋 项目描述
本项目复现并分析了Konza草原长期火烧实验的生态数据，评估不同火烧频率对草和灌木覆盖度的影响，并检测潜在的生态阈值点。

## 🔬 研究背景
Konza草原是美国最大的长期生态研究站之一，自1970年代以来持续进行不同频率的火烧实验，研究火对草原生态系统的影响。

## 📊 数据集
- **数据来源**: `abruptdata` R包 (`fire_konza_ratajczak`)
  data(fire_konza_ratajczak)
- **数据获取代码**:
  ```r
  install.packages("devtools")
  devtools::install_github("regime-shifts/abruptdata")
  library(abruptdata)
  data(fire_konza_ratajczak)
- **原始研究**: Ratajczak et al., Konza LTER
- **变量说明**:
  - `Watershed_designation`: 流域编号
  - `Fire_treatment`: 火烧处理频率
  - `Year`: 观测年份
  - `Grass_cover`: 草覆盖度(%)
  - `Shrub_cover`: 灌木覆盖度(%)

## 🔧 环境可重复性
本项目使用 `renv` 进行R包管理，确保环境完全可重复。

### 恢复环境
```r
renv::restore()
