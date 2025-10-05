USE olist_brazil_ecommerce;

-- 1. 创建订单表
CREATE TABLE orders (
    order_id VARCHAR(100) PRIMARY KEY,
    customer_id VARCHAR(100),
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP NULL,
    order_approved_at TIMESTAMP NULL,
    order_delivered_carrier_date TIMESTAMP NULL,
    order_delivered_customer_date TIMESTAMP NULL,
    order_estimated_delivery_date TIMESTAMP NULL
);

-- 2. 创建客户表
CREATE TABLE customers (
    customer_id VARCHAR(100) PRIMARY KEY,
    customer_unique_id VARCHAR(100), -- 真正唯一的用户ID
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

-- 3. 创建订单商品表
CREATE TABLE order_items (
    order_id VARCHAR(100),
    order_item_id INT,
    product_id VARCHAR(100),
    seller_id VARCHAR(100),
    shipping_limit_date TIMESTAMP NULL,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2)
);

-- 4. 创建订单支付表
CREATE TABLE order_payments (
    order_id VARCHAR(100),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10, 2)
);

-- 5. 创建商品表
CREATE TABLE products (
    product_id VARCHAR(100),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
-- 6. 创建订单评论表
CREATE TABLE order_reviews (
    review_id VARCHAR(100),
    order_id VARCHAR(100),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP NULL,
    review_answer_timestamp TIMESTAMP NULL
);

-- 7. 创建卖家表 (可选，但数据集里有，建议导入)
CREATE TABLE sellers (
    seller_id VARCHAR(100) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

-- 8. 创建地理位置表 (可选)
CREATE TABLE geolocation (
    zip_code_prefix INT,
    geolocation_lat DECIMAL(10, 8),
    geolocation_lng DECIMAL(11, 8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);
-- 创建产品类别翻译表
CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

-- 验证表结构
DESCRIBE product_category_translation;

-- DROP TABLE IF EXISTS olist_customers_dataset;

-- 删除已存在的表（如果存在）
-- DROP TABLE IF EXISTS order_reviews;

-- 验证所有表的行数
SELECT 
    'customers' AS table_name, 
    COUNT(*) AS row_count 
FROM customers
UNION ALL
SELECT 
    'products', 
    COUNT(*) 
FROM products
UNION ALL
SELECT 
    'orders', 
    COUNT(*) 
FROM orders
UNION ALL
SELECT 
    'order_items', 
    COUNT(*) 
FROM order_items
UNION ALL
SELECT 
    'order_payments', 
    COUNT(*) 
FROM order_payments
UNION ALL
SELECT 
    'order_reviews', 
    COUNT(*) 
FROM order_reviews
UNION ALL
SELECT 
    'geolocation', 
    COUNT(*) 
FROM geolocation
UNION ALL
SELECT 
    'product_category_translation', 
    COUNT(*) 
FROM product_category_translation;

-- 创建核心分析视图
-- 首先删除已存在的视图（如果存在）
DROP VIEW IF EXISTS optimized_sales_analysis;
DROP VIEW IF EXISTS sales_analysis_view;

CREATE VIEW optimized_sales_analysis AS
SELECT 
    -- 订单核心信息
    o.order_id,
    o.order_purchase_timestamp,
    o.order_status,
    
    -- 客户信息（去敏感化）
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    
    -- 商品信息
    oi.product_id,
    oi.price AS item_price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_item_value,
    
    -- 商品品类（使用英文翻译）
    COALESCE(pt.product_category_name_english, p.product_category_name) AS product_category,
    
    -- 支付信息
    pay.payment_type,
    pay.payment_value,
    pay.payment_installments,
    
    -- 评价信息
    r.review_score,
    
    -- 计算字段
    CASE 
        WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date <= o.order_estimated_delivery_date 
        THEN 'on_time'
        WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'delayed'
        ELSE 'other'
    END AS delivery_status,
    
    -- 时间衍生字段
    DATE(o.order_purchase_timestamp) AS order_date,
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    DAYOFWEEK(o.order_purchase_timestamp) AS order_day_of_week

FROM orders o

-- 关联表
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pt ON p.product_category_name = pt.product_category_name
LEFT JOIN order_payments pay ON o.order_id = pay.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id

-- 筛选条件
WHERE o.order_status IN ('delivered', 'shipped', 'approved');

-- 查看MySQL允许导出文件的目录
SHOW VARIABLES LIKE 'secure_file_priv';

-- 创建核心分析视图
-- 首先删除已存在的视图（如果存在）
DROP VIEW IF EXISTS optimized_sales_analysis;
DROP VIEW IF EXISTS cleaned_sales_analysis;

CREATE VIEW optimized_sales_analysis AS
SELECT 
    -- 订单核心信息
    o.order_id,
    o.order_purchase_timestamp,
    o.order_status,
    
    -- 客户信息（去敏感化）
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    
    -- 商品信息
    oi.product_id,
    oi.price AS item_price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_item_value,
    
    -- 商品品类（使用英文翻译）
    COALESCE(pt.product_category_name_english, p.product_category_name) AS product_category,
    
    -- 支付信息
    pay.payment_type,
    pay.payment_value,
    pay.payment_installments,
    
    -- 评价信息
    r.review_score,
    
    -- 计算字段
    CASE 
        WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date <= o.order_estimated_delivery_date 
        THEN 'on_time'
        WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'delayed'
        ELSE 'other'
    END AS delivery_status,
    
    -- 时间衍生字段
    DATE(o.order_purchase_timestamp) AS order_date,
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    DAYOFWEEK(o.order_purchase_timestamp) AS order_day_of_week

FROM orders o

-- 关联表
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pt ON p.product_category_name = pt.product_category_name
LEFT JOIN order_payments pay ON o.order_id = pay.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id

-- 筛选条件
WHERE 
    o.order_status IN ('delivered', 'shipped', 'approved') AND
    oi.price >= 0 AND  -- 删除负值的商品价格
    oi.freight_value >= 0 AND  -- 删除负值的运费
    o.order_purchase_timestamp IS NOT NULL AND  -- 确保时间不为空
    o.order_purchase_timestamp BETWEEN '2016-01-01' AND '2018-12-31'  -- 时间范围限制
GROUP BY 
    o.order_id, 
    o.order_purchase_timestamp, 
    o.order_status,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    oi.product_id,
    oi.price,
    oi.freight_value,
    product_category,
    pay.payment_type,
    pay.payment_value,
    pay.payment_installments,
    r.review_score,
    delivery_status,
    order_date,
    order_year,
    order_month,
    order_day_of_week;

-- 验证行数和关键指标
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products,
    SUM(payment_value) AS total_sales,
    AVG(review_score) AS avg_rating,
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM optimized_sales_analysis;

-- 检查空值和数据完整性
SELECT 
    '空值检查' AS check_type,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_orders,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN product_category IS NULL THEN 1 ELSE 0 END) AS null_categories,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_payments,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_reviews
FROM optimized_sales_analysis;

-- 检查订单状态分布
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM optimized_sales_analysis), 2) AS percentage
FROM optimized_sales_analysis
GROUP BY order_status
ORDER BY order_count DESC;

-- 检查配送状态
SELECT 
    delivery_status,
    COUNT(*) AS status_count,
    AVG(review_score) AS avg_rating
FROM optimized_sales_analysis
WHERE delivery_status != 'other'
GROUP BY delivery_status;

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
