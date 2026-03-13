# ==================================================
# 项目：Konza草原火烧实验生态数据分析
# 数据来源：abruptdata包 - fire_konza_ratajczak
# ==================================================

library(tidyverse)
library(ggplot2)
library(abruptdata)

set.seed(42)

# 1. 加载Konza草原数据
data(fire_konza_ratajczak)
df <- fire_konza_ratajczak

# 保存原始数据备份
dir.create("data/raw/konza", recursive = TRUE, showWarnings = FALSE)
write.csv(df, "data/raw/konza/konza_fire_data.csv", row.names = FALSE)

print("Konza草原火烧实验数据加载成功！")
print(paste("数据维度:", nrow(df), "行,", ncol(df), "列"))
print("变量名称：")
print(names(df))

# 2. 数据概览
print("数据摘要：")
print(summary(df))

# 3. 计算总植被覆盖度（草+灌木）
df$Total_cover <- df$Grass_cover + df$Shrub_cover

# 4. 按流域和火烧处理分组统计
summary_stats <- df %>%
  group_by(Watershed_designation, Fire_treatment) %>%
  summarise(
    mean_grass = mean(Grass_cover, na.rm = TRUE),
    mean_shrub = mean(Shrub_cover, na.rm = TRUE),
    mean_total = mean(Total_cover, na.rm = TRUE),
    sd_grass = sd(Grass_cover, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

write.csv(summary_stats, "output/tables/konza_summary_stats.csv", row.names = FALSE)

# 5. 可视化1：不同火烧处理下的植被覆盖度箱线图
p1 <- ggplot(df, aes(x = Fire_treatment, y = Total_cover, fill = Fire_treatment)) +
  geom_boxplot() +
  geom_jitter(width = 0.2, alpha = 0.5) +
  facet_wrap(~Watershed_designation) +
  theme_minimal() +
  labs(title = "不同火烧处理下的总植被覆盖度",
       x = "火烧处理",
       y = "总覆盖度 (%)") +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("output/figures/konza_fire_effects.png", p1, width = 10, height = 8, dpi = 300)

# 6. 可视化2：时间趋势（草vs灌木）
df_long <- df %>%
  pivot_longer(cols = c(Grass_cover, Shrub_cover),
               names_to = "Vegetation_type",
               values_to = "Cover")

p2 <- ggplot(df_long, aes(x = Year, y = Cover, color = Vegetation_type)) +
  geom_smooth(method = "loess", se = TRUE) +
  facet_grid(Fire_treatment~Watershed_designation) +
  theme_minimal() +
  labs(title = "草与灌木覆盖度的时间趋势",
       x = "年份",
       y = "覆盖度 (%)") +
  scale_color_manual(values = c("Grass_cover" = "forestgreen", "Shrub_cover" = "brown"))

ggsave("output/figures/konza_temporal_trends.png", p2, width = 12, height = 10, dpi = 300)

# 7. 可视化3：草与灌木的关系
p3 <- ggplot(df, aes(x = Grass_cover, y = Shrub_cover, color = Fire_treatment)) +
  geom_point(size = 2, alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~Watershed_designation) +
  theme_minimal() +
  labs(title = "草与灌木覆盖度的关系",
       x = "草覆盖度 (%)",
       y = "灌木覆盖度 (%)")

ggsave("output/figures/konza_grass_shrub_relationship.png", p3, width = 10, height = 8, dpi = 300)

# 8. 统计分析：火烧处理对植被的影响
library(broom)

# ANOVA检验
aov_grass <- aov(Grass_cover ~ Fire_treatment * Watershed_designation, data = df)
aov_shrub <- aov(Shrub_cover ~ Fire_treatment * Watershed_designation, data = df)
aov_total <- aov(Total_cover ~ Fire_treatment * Watershed_designation, data = df)

# 保存统计结果
sink("output/tables/konza_anova_results.txt")
print("========== Grass Cover ANOVA ==========")
print(summary(aov_grass))
print("")
print("========== Shrub Cover ANOVA ==========")
print(summary(aov_shrub))
print("")
print("========== Total Cover ANOVA ==========")
print(summary(aov_total))
sink()

# 9. 检测潜在生态阈值（灌木扩张的年份）
threshold_analysis <- df %>%
  group_by(Watershed_designation, Fire_treatment) %>%
  arrange(Year) %>%
  mutate(
    shrub_diff = c(NA, diff(Shrub_cover)),
    grass_diff = c(NA, diff(Grass_cover))
  ) %>%
  ungroup()

# 找出灌木覆盖度显著增加的年份（潜在阈值点）
threshold_points <- threshold_analysis %>%
  filter(!is.na(shrub_diff)) %>%
  group_by(Watershed_designation, Fire_treatment) %>%
  mutate(threshold = mean(shrub_diff) + 2*sd(shrub_diff)) %>%
  filter(shrub_diff > threshold) %>%
  select(Watershed_designation, Fire_treatment, Year, Shrub_cover, shrub_diff)

if(nrow(threshold_points) > 0) {
  write.csv(threshold_points, "output/tables/konza_threshold_points.csv", row.names = FALSE)
  print(paste("发现", nrow(threshold_points), "个潜在生态阈值点"))
}

# 10. 保存完整分析数据
write.csv(df, "data/processed/konza_analysis_complete.csv", row.names = FALSE)

# 11. 保存会话信息
sink("output/session_info.txt")
print(sessionInfo())
sink()

print("==========================================")
print("Konza草原数据分析完成！")
print("生成的文件：")
print("- output/figures/konza_fire_effects.png")
print("- output/figures/konza_temporal_trends.png")
print("- output/figures/konza_grass_shrub_relationship.png")
print("- output/tables/konza_summary_stats.csv")
print("- output/tables/konza_anova_results.txt")
print("- output/tables/konza_threshold_points.csv (如果有阈值点)")
print("==========================================")
