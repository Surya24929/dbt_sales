-- models/data_mart/mart_delivery_performance.sql

{{
    config(
        materialized = 'view',
        schema = 'gold'
    )
}}

with filtered_feedback as (
    select
        order_id,
        rating,
        feedback_category
    from {{ ref('stg_customer_feedback') }}
    where feedback_category = 'Delivery'
) , cte2 as (

select
    dp.customer_id, 
    count(dp.order_id) as total_orders,
    sum(dp.is_late_delivery) as total_late_orders,
    round((sum(dp.is_late_delivery) * 100.0) / count(dp.order_id),2) as late_delivery_percentage,
    round((100 - (sum(dp.is_late_delivery) * 100.0) / count(dp.order_id)),2) as on_time_delivery_percentage,
    
    round(avg(ff.rating),2) as avg_satisfaction_score,
    avg(case when dp.is_late_delivery = 1 then ff.rating else null end) as avg_satisfaction_late_orders,
    avg(case when dp.is_late_delivery = 0 then ff.rating else null end) as avg_satisfaction_on_time_orders, feedback_category

from {{ ref('inter_delivery_stats') }} dp
join filtered_feedback ff
    on dp.order_id = ff.order_id

group by dp.customer_id ,feedback_category)
select * , total_orders - total_late_orders as on_time_delivery
from cte2
