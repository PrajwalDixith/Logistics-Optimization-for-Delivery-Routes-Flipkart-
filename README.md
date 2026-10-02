Project Overview: 
Flipkart, one of India’s largest e-commerce giants, delivers millions of orders every day across 
metros, Tier-2, and Tier-3 cities through its logistics arm, Ekart Logistics. 
The logistics network includes regional fulfillment centers, sorting hubs, and last-mile delivery 
partners across India. 
As order volumes rise - especially during sales and festive seasons - delays, route 
inefficiencies, and traffic disruptions can significantly affect both customer satisfaction and 
operational costs. 
Currently, Flipkart’s logistics team faces challenges in: 
● Identifying the root causes of delivery delays (e.g., congestion, hub processing issues). 
● Optimizing delivery routes for faster, more cost-efficient fulfillment. 
● Improving shipment efficiency and agent performance using data-driven insights. 
The logistics data, stored in relational databases - can be analyzed using SQL to extract 
meaningful patterns and performance metrics. These insights can help Flipkart improve route 
planning, reduce delivery delays, and enhance warehouse and agent efficiency. 


Project Objective: 
Build a SQL-driven Logistics analytics system to analyze delays, optimize routes, and enhance 
shipment efficiency by leveraging queries, aggregations. The project aims to answer key 
business questions, uncover inefficiencies, and recommend actionable improvements based on 
data analysis.

These are tasks that are solved in the sql script file while i was student intern.
Data Cleaning & Preparation
● Identify and delete duplicate Order_ID records. 
● Replace null Traffic_Delay_Min with the average delay for that route. 
● Convert all date columns into YYYY-MM-DD format using SQL functions. 
● Ensure that no Actual_Delivery_Date is before Order_Date (flag such records). 

Delivery Delay Analysis
● Calculate delivery delay (in days) for each order 
● Find Top 10 delayed routes based on average delay days. 
● Use window functions to rank all orders by delay within each warehouse. 

Route Optimization Insights
● For each route, calculate: 
  ○ Average delivery time (in days). 
  ○ Average traffic delay. 
  ○ Distance-to-time efficiency ratio: Distance_KM / Average_Travel_Time_Min. 
● Identify 3 routes with the worst efficiency ratio. 
● Find routes with >20% delayed shipments. 
● Recommend potential routes for optimization.

Warehouse Performance
● Find the top 3 warehouses with the highest average processing time. 
● Calculate total vs. delayed shipments for each warehouse. 
● Use CTEs to find bottleneck warehouses where processing time > global average. 
● Rank warehouses based on on-time delivery percentage.

Delivery Agent Performance
● Rank agents (per route) by on-time delivery percentage  
● Find agents with on-time % < 80%. 
● Compare average speed of top 5 vs bottom 5 agents using subqueries. 
● Suggest training or workload balancing strategies for low performers 

Shipment Tracking Analytics
● For each order, list the last checkpoint and time. 
● Find the most common delay reasons (excluding None). 
● Identify orders with >2 delayed checkpoints

Advanced KPI Reporting
Calculate KPIs using SQL queries: 
Average Delivery Delay per Region (Start_Location). 
On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100. 
Average Traffic Delay per Route.
