use prajwalsqlproject01;

-- note: names of tables are changed for making queries as below.
-- 'order table'->'flipkart_orders', 'routes table'-> 'flipkart_routes', 'warehouses table'-> 'flipkart_wrhs', 'delivery agent table'->'flipkart_da'
-- 'shipment tracking table'->'flipkart_sptk' and used 'prajwalsqlproject01' as database name for all query operations.
-- 1.date cleaning and prepration
-- task: to check if duplicate order id exists
select order_id, count(*) as duplicate_count
from flipkart_orders
group by Order_ID
having COUNT(*) > 1;
-- checked for duplicate order ID

-- task: to check if any 'traffic_delay_min' is null
select*from flipkart_routes where Traffic_Delay_Min is null;

-- task to check all dates are in 'YYYY-MM-DD' format in 'flipkart_orders' and 'flipkart_sptk' tables (since only those contain Date/Date parts)
select*from flipkart_orders 
where str_to_date(order_date, '%Y-%m-%d') is not null
  and order_date = date_format(STR_TO_DATE(order_date, '%Y-%m-%d'), '%Y-%m-%d');    
select*from flipkart_orders 
where str_to_date(expected_delivery_date, '%Y-%m-%d') is not null
  and expected_delivery_date = date_format(STR_TO_DATE(expected_delivery_date, '%Y-%m-%d'), '%Y-%m-%d');
select*from flipkart_orders 
where str_to_date(Actual_Delivery_Date, '%Y-%m-%d') is not null
  and Actual_Delivery_Date = date_format(STR_TO_DATE(Actual_Delivery_Date, '%Y-%m-%d'), '%Y-%m-%d');
-- checked and corrected date format for 'flipkart_orders'.  
 
-- to check and flag no 'actual_delivery_date' is before 'order date' and flag them.
select *,
case
when actual_delivery_date<order_date then 'wrong delivery date'
else 'right delivery date'
end as fix_delivery_date
from flipkart_orders;

-- 2.delivery delay analysis
-- task : to calculate delivery delay in days of 'flipkart_orders'
select *, datediff(actual_delivery_date,expected_delivery_date)as date_difference from flipkart_orders; 
 
-- task: to find top 10 delayed routes based on avg delay days
select route_id, round(avg(datediff(actual_delivery_date,expected_delivery_date)),2) as delay_in_days
from flipkart_orders group by Route_ID order by delay_in_days desc limit 10;
   
-- task: use window functions to rank all orders by delay within each warehouse   
create temporary table order_rnker_per_warehouse2 as
select  fo.Order_ID,fo.Warehouse_ID,fw.Average_Processing_Time_min
from flipkart_orders fo
inner join flipkart_wrhs fw on fo.Warehouse_ID=fw.Warehouse_ID order by fw.Average_Processing_Time_min;
select *, rank() over(order by Average_Processing_Time_min)as rank_of_orders from order_rnker_per_warehouse2;

-- route optimisation insites
-- task: for each route calculate (a) average_delivery_time(in days)
select
    route_id,
    avg(datediff(actual_delivery_date,expected_delivery_date)) as avg_delivery_time_in_days
from flipkart_orders
group by route_id order by route_id; 

-- task: for each route calculate (b) averge traffic delay
create temporary table td_in_sptk2
select Order_ID, avg(Delay_minutes) as dt from flipkart_sptk where Delay_Reason='Traffic' group by Order_ID;
select*from td_in_sptk2;
create temporary table avg_dly2
select fo.Route_ID,t.Order_ID,round(t.dt,2) as ndt
from flipkart_orders fo
left join td_in_sptk2 t 
on fo.Order_ID=t.Order_ID order by Route_ID; 
select route_id,round(avg(ndt),2) as average_traffic_delay from avg_dly2 group by route_id; 

-- task: for each route calculate (c)Distance-to-time efficiency ratio: Distance_KM / Average_Travel_Time_Min
select *, Distance_KM/Average_Travel_Time_Min as Distance_to_time_efficiency_ratio from flipkart_routes;

-- task: Identify 3 routes with the worst efficiency ratio
select *, Distance_KM/Average_Travel_Time_Min as Distance_to_time_efficiency_ratio 
from flipkart_routes order by Distance_to_time_efficiency_ratio desc limit 3;

-- task: Find routes with >20% delayed shipments
select
    fo.route_id,
    count(*) AS total_shipments,
    sum(case 
        when fo.actual_delivery_date > fo.expected_delivery_date then 1 
        else 0 
    end) as delayed_shipments,
    (sum(case 
        when fo.actual_delivery_date > fo.expected_delivery_date then 1 
        else 0 
    end) * 100.0 / COUNT(*)) AS delay_percentage
from 
    flipkart_orders fo
inner join
    flipkart_sptk fs on fo.order_id = fs.order_id
group by 
    fo.route_id
having 
    (sum(case
        when fo.actual_delivery_date > fo.expected_delivery_date then 1 
        else 0 
    end) * 100.0 / count(*)) > 20 order by Route_ID;       

-- 4.Warehouse performence
-- task: Find the top 3 warehouses with the highest average processing time
select warehouse_id,average_processing_time_min from flipkart_wrhs order by Average_Processing_Time_Min desc limit 3;

-- task: Calculate total vs. delayed shipments for each warehouse
select warehouse_id,
	count(*) as total_shipments,
(sum(case 
        when delay_minutes>0 then 1 
        else 0 
    end) ) as delayed_shipments
from flipkart_orders fo
join flipkart_sptk fs 
on fo.Order_ID=fs.Order_ID group by Warehouse_ID order by Warehouse_ID;

-- task: Use CTEs to find bottleneck warehouses where processing time > global average
with global_avg as (
  select avg(average_processing_time_min) as global_avg_time
  from flipkart_wrhs
)
select 
  w.*
from
  flipkart_wrhs w
  cross Join global_avg ga
where 
  w.average_processing_time_min > ga.global_avg_time;  
  
 -- task: Rank warehouses based on on-time delivery percentage
 with delivery_status as (
    select 
        fo.order_id,
        fo.warehouse_id,
        case 
            when fo.actual_delivery_date <= fo.expected_delivery_date then 'On-Time'
            else 'Late'
        end as delivery_status
    from flipkart_orders fo
    inner join flipkart_sptk fs on fo.order_id = fs.order_id
),
warehouse_performance as (
    select
        warehouse_id,
        count(*) as total_deliveries,
        sum(case when delivery_status = 'On-Time' then 1 else 0 end) as on_time_deliveries,
        round(
            (sum(case when delivery_status = 'On-Time' then 1 else 0 end) * 100.0) / count(*),
            2
        ) as on_time_percentage
    from delivery_status
    group by warehouse_id
)
select 
    warehouse_id,
    on_time_percentage,
    rank() over (order by on_time_percentage desc) as ranked
from warehouse_performance
order by on_time_percentage desc;   
  
-- 5.delivery agent performance
-- task: Rank agents (per route) by on-time delivery percentage
select 
    agent_id,route_id,on_time_delivery_percentage,
    rank() over (partition by route_id order by on_time_delivery_percentage desc) as ranked
from
    flipkart_da order by Route_ID;
    
 -- task: Find agents with on-time % < 80%.
select agent_id,Agent_Name,On_Time_Delivery_Percentage from flipkart_da where On_Time_Delivery_Percentage<80.00 order by On_Time_Delivery_Percentage;

-- Compare average speed of top 5 vs bottom 5 agents
select
    'Top 5' as group_type,
    avg(avg_speed_kmph) as avg_speed
from (
    select agent_id, agent_name, avg_speed_kmph
    from flipkart_da
    order by avg_speed_kmph desc
    limit 5
) as top_5_agents
union all
select
    'Bottom 5' as group_type,
    round(avg(avg_speed_kmph),2) as avg_speed
from (
    select agent_id, agent_name, avg_speed_kmph
    from flipkart_da
    order by avg_speed_kmph asc
    limit 5
) as bottom_5_agents;

-- 6.shipment tracking analytics 
-- task: For each order, list the last checkpoint and time
select*from (select*,
        row_number() over (partition by order_id order by checkpoint_time desc) as rn
    from flipkart_sptk
) ranked
where rn = 1;   
   
-- task: Find the most common delay reasons (excluding None)   
select 
    delay_reason,
    count(*) as occurrence_count,
    avg(delay_minutes) as avg_delay_minutes
from
    flipkart_sptk
where 
    delay_reason is not null
    and delay_reason != 'None'
group by 
    delay_reason
order by 
    occurrence_count desc;   
    
-- task: Identify orders with >2 delayed checkpoints
select order_id,count(Order_ID)as cnt from flipkart_sptk where delay_minutes > 0 group by order_id having count(*) > 2 order by cnt desc;  

-- 7.advanced KPI reporting
-- task: average delivery delay per region (Start_Location)
select
    fr.start_location,
     round(avg(datediff(fo.actual_delivery_date,fo.expected_delivery_date))*1440) as avg_delay_in_min
from 
    flipkart_routes fr
    inner join flipkart_orders fo on fr.route_id = fo.route_id
group by
    fr.start_location;       
 
-- task: On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100
select round(((select count(order_id) from flipkart_sptk where Delay_Reason='None' and Delay_Minutes=0)/count(Order_ID))*100,2) as 'on_time_delivery_%'
from flipkart_sptk;

-- task: average traffic delay per route
create temporary table td_in_sptk3
select Order_ID, avg(Delay_minutes) as dt from flipkart_sptk where Delay_Reason='Traffic' group by Order_ID;
create temporary table avg_dly3
select fo.Route_ID,t.Order_ID,round(t.dt,2) as ndt
from flipkart_orders fo
left join td_in_sptk3 t 
on fo.Order_ID=t.Order_ID order by Route_ID; 
select route_id,round(avg(ndt),2) as average_traffic_delay_in_min from avg_dly3 group by route_id;

-- link to Explanation video is below in comment line.
-- https://drive.google.com/file/d/1Psyry_1D4qgXvOan80GGyrQvHHv8guat/view?usp=drive_link

