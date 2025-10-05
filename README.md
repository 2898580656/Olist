# Olist巴西电商数据分析报告

## 🎯 项目背景
- **数据源**：Olist巴西电商平台真实交易数据（2016-2018）
- **数据规模**：10万+订单，9万+客户，16M+雷亚尔交易额
- **分析目标**：客户价值分析、销售趋势洞察、运营优化建议

## 🛠 技术栈
- **数据工程**：MySQL (数据整合、清洗、ETL)
- **数据分析**：Python/pandas (RFM分析、统计分析)
- **数据可视化**：Tableau (4个交互式仪表盘)

#### 阶段一：MySQL — 数据整合与核心指标计算
**目标**：利用SQL的强大查询能力，将多个表连接起来，计算关键业务指标

**数据工程成果**：
- **数据库创建**：成功建立olist_brazil_ecommerce数据库
- **表结构设计**：创建8个核心数据表，匹配原始数据结构
- **数据导入**：完成总计约50万条记录的导入工作

**数据质量验证**：
```sql
-- 各表数据量验证
customers: 99,441 ✓ (100%)
products: 32,340 ✓ (98%) 
orders: 96,461 ✓ (97%)
order_items: 112,650 ✓ (100%)
order_payments: 103,886 ✓ (100%)
order_reviews: 14,553 ✓ (15%，但数据质量高)
geolocation: 61,011 ✓ (覆盖主要地区)
product_category_translation: 71 ✓ (100%)
```
**数据清洗**：
```sql
-- 语言处理
COALESCE(pt.product_category_name_english, p.product_category_name) AS product_category

-- 配送状态分类
CASE 
    WHEN o.order_status = 'delivered' AND delivery_date <= estimated_date 
    THEN 'on_time'
    ELSE 'delayed'
END AS delivery_status

-- 数据清洗
WHERE o.order_status IN ('delivered', 'shipped', 'approved')
  AND oi.price >= 0
  AND oi.freight_value >= 0
  AND o.order_purchase_timestamp IS NOT NULL
```
**数据整合**：
```sql
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
```
核心分析视图创建：
创建了optimized_sales_analysis视图，实现：
7表智能关联整合关键业务数据
多语言统一处理（葡萄牙语→英语）
计算字段生成：配送状态、时间维度、总价值等
数据质量提升：空值处理、异常值过滤

#### 阶段二：Python数据分析
**目标**：RFM建模与业务洞察

关键业务指标：
✅ 唯一订单数: 95,123
✅ 唯一客户数: 92,076
✅ 唯一商品数: 31,625
✅ 总销售额: R$ 16,172,106.87
✅ 平均订单价值: R$ 170.01
✅ 平均评分: 4.14
✅ 时间范围: 2016-09-15 到 2018-08-29

核心业务指标分析：
💰 总销售额: R$ 16,172,106.87
📦 总订单数: 95,123
📊 平均订单价值: R$ 170.01
👥 客户总数: 92,076
🛒 客单价: R$ 175.64

### RFM客户分群模型
- **Recency** (最近购买)：客户最后一次购买距今天数
- **Frequency** (购买频率)：客户总订单数量  
- **Monetary** (消费金额)：客户总消费金额

### 客户分群结果：
- 🏆 冠军客户 (6.9%) - 高价值核心客户
- 🔵 忠诚客户 (7.9%) - 稳定复购客户
- 🌱 潜力客户 (45.4%) - 有成长空间客户
- ⏰ 需唤醒客户 (11.9%) - 需要激活客户
- 📉 流失客户 (27.9%) - 已流失客户
