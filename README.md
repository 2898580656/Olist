# Olist巴西电商数据分析报告

## 🎯 项目背景
- **数据源**：Olist巴西电商平台真实交易数据（2016-2018）
- **数据规模**：10万+订单，9万+客户，16M+雷亚尔交易额
- **分析目标**：客户价值分析、销售趋势洞察、运营优化建议

## 🛠 技术栈
- **数据工程**：MySQL (数据整合、清洗、ETL)
- **数据分析**：Python/pandas (RFM分析、统计分析)
- **数据可视化**：Tableau (4个交互式仪表盘)






-- 创建新的视图，用于数据分析
CREATE OR REPLACE VIEW cleaned_sales_analysis AS
SELECT 
    DISTINCT order_id,  -- 唯一订单 ID
    STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') AS order_purchase_timestamp,  -- 确保时间格式正确
    order_status,
    customer_unique_id,
    customer_state,
    customer_city,
    product_id,
    item_price,
    freight_value,
    total_item_value,
    product_category,
    payment_type,
    payment_value,
    payment_installments,
    review_score,
    delivery_status,
    STR_TO_DATE(order_date, '%Y-%m-%d') AS order_date,  -- 确保日期格式正确
    YEAR(STR_TO_DATE(order_date, '%Y-%m-%d')) AS order_year,  -- 从日期中提取年份
    MONTH(STR_TO_DATE(order_date, '%Y-%m-%d')) AS order_month,  -- 从日期中提取月份
    DAYOFWEEK(STR_TO_DATE(order_date, '%Y-%m-%d')) AS order_day_of_week  -- 从日期中提取星期几
FROM 
    optimized_sales_analysis  -- 使用现有视图作为数据源
WHERE 
    item_price >= 0 AND  -- 删除负值的商品价格
    freight_value >= 0 AND  -- 删除负值的运费
    total_item_value >= 0 AND  -- 删除负值的总商品价值
    review_score BETWEEN 1 AND 5;  -- 删除不在评分范围内的记录
