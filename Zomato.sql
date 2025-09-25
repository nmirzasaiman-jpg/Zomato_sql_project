#1 Find the top 2 most frequently ordered dishes by the customer named 'Ashley Sanders' during the last 2 years.
select c1.customer_name,order_item,count(order_id),dense_rank() over(order by count(order_id) desc) as r1
from customers as c1
join orders as o1
on c1.customer_id=o1.customer_id
where c1.customer_name='Ashley Sanders' and order_date>=date_sub(current_date(),interval 2 year)
group by c1.customer_name,order_item

#2 popular time slots
#identify the time slots during which the most orders are placed based on 2 hour interval
select 
hour(order_time),
count(order_id) over(partition by floor(hour(order_time)/2)) as k1
from orders
order by k1 desc

#3 rder value analysis
#find the averege order value per customer who has placed more then 6 orders

select c1.customer_name,count(order_id) as c1,avg(total_amount) as avg_order_value
from customers as c1
join orders as o1
on c1.customer_id=o1.customer_id
group by 1
having c1=6

# 4 high value customers
#list the customers who spent more then 1000 in total on food orders
select c1.customer_name,sum(total_amount) as sum_order_value
from customers as c1
join orders as o1
on c1.customer_id=o1.customer_id
group by 1
having sum_order_value>=1000

# 5 oders without delivery
#write a query to find orders that were placed but not delivered

select *
from orders as o1
left join deliveries as d1
on o1.order_id=d1.order_id
where delivery_status='Cancelled'

# 6 Restaurant revenue ranking
#rank restaurant by thir total revenue from the last year,including thier name,rank within thier city

select city,restaurant_name,sum(total_amount) as total_revenue,dense_rank() over(partition by city order by sum(total_amount) desc )
from restaurants as r1
left join orders as o1
on r1.restaurant_id=o1.restaurant_id
where order_date>=date_sub(current_date,interval 1 year)
group by city,restaurant_name

# 7 most popular dishes by city
#Identify the most popular dishes in each city based on the number of orders

select city,order_item,count(order_id) as total_order,dense_rank() over(partition by city order by count(order_id) desc )
from restaurants as r1
left join orders as o1
on r1.restaurant_id=o1.restaurant_id
where order_date>=date_sub(current_date,interval 1 year)
group by 1,2

# 8 customer churun
#find the customers who have not placed an order in 2024 but did in 2023

select distinct(c1.customer_id)
from customers as c1
left join orders as o1
on c1.customer_id=o1.customer_id
where extract(year from order_date)=2023 and c1.customer_id not in (select distinct(c1.customer_id)
from customers as c1
left join orders as o1
on c1.customer_id=o1.customer_id
where extract(year from order_date)=2024)

# 9 cancellation rate comparision
#calculate and compare the order cancellation rate for each restaurant between the current year and pervious year
select t1.restaurant_name,current_year_cancellation,last_year_cancellation,(t1.current_year_cancellation - t2.last_year_cancellation) AS difference_percent
from (select restaurant_name,((count(case when order_status='Cancelled' then 1 end)/count(order_id))*100) as current_year_cancellation
from restaurants as r1
left join orders  as o1
on r1.restaurant_id=o1.restaurant_id
where extract(year from order_date)=YEAR(CURDATE())
group by restaurant_name) as t1
join 
(select restaurant_name,((count(case when order_status='Cancelled' then 1 end)/count(order_id))*100) as last_year_cancellation
from restaurants as r1
left join orders  as o1
on r1.restaurant_id=o1.restaurant_id
where extract(year from order_date)=YEAR(CURDATE())-1
group by restaurant_name) as t2
on t1.restaurant_name=t2.restaurant_name

# 10 rider average delivery time
#Determine each riders averege delivery time

select rider_name,avg(timestampdiff(minute,delivery_time,order_time))
from riders as r1
left join deliveries as d1
on r1.rider_id=d1.rider_id
join orders as o1
on o1.order_id=d1.order_id
group by 1

# 11 monthly restaurant growth rate
#calculate each retaurants growth ratio based on the total number of delivered orders since it joining

select restaurant_name,date_format(order_date,'%m-%Y'),count(o1.order_id) as total_orders,
lag(count(o1.order_id)) over(partition by  restaurant_name order by date_format(order_date,'%m-%Y')) as l1,
count(o1.order_id)/lag(count(o1.order_id)) over(partition by  restaurant_name order by date_format(order_date,'%m-%Y')) as growth_ratio
from restaurants as r1
left join orders as o1
on r1.restaurant_id=o1.restaurant_id
join deliveries as d1
on d1.order_id=o1.order_id
where delivery_status='Delivered'  and extract(year from order_date)=YEAR(CURDATE())
group by restaurant_name,date_format(order_date,'%m-%Y')
order by 1,date_format(order_date,'%m-%Y')

# 12 customer segmentation
#segment customers into gold or sliver groups based on thier total spending based on AOV(averege order value )
-- if customer total spending exceed aov then gold otherwise silver

select customer_name,sum(total_amount) as total_spending,
case 
when sum(total_amount)>(select avg(total_amount) from orders) then 'Gold'
when sum(total_amount)<(select avg(total_amount) from orders) then 'Silver'
end as status_customer
from customers as c1
left join orders as o1
on c1.customer_id=o1.customer_id
group by customer_name

# 13 calculate each riders monthly earnings,assuming they earn 8% of total amount

select r1.rider_id,rider_name,(sum(total_amount)/100)*8 as eight_percent
from riders as r1
left join deliveries as d1
on r1.rider_id=d1.rider_id
join orders as o1
on o1.order_id=d1.order_id
group by r1.rider_id,rider_name

# 14 Rating rider analysis

select rider_name,timestampdiff(minute,delivery_time,order_time) as 'tolat_time',
case 
when timestampdiff(minute,delivery_time,order_time)<20 then '5-star'
when timestampdiff(minute,delivery_time,order_time) between 20 and 30 then '4-star'
when timestampdiff(minute,delivery_time,order_time)>30 then '3-star'
end as 'rating'
from riders as r1
left join deliveries as d1
on r1.rider_id=d1.rider_id
join orders as o1
on o1.order_id=d1.order_id
WHERE d1.delivery_status = 'Delivered'
ORDER BY rating DESC

# 15 order frequency by day
#analyze order frequency per day of the week and identify the peak day for each restaurant

select restaurant_name,dayname(order_date),count(order_id)
from restaurants as r1
left join orders as o1
on r1.restaurant_id=o1.restaurant_id
group by restaurant_name,2

#customer life time value (CLV)
#calculate the total revenue generated by each customer over all thier orders

select customer_name,sum(total_amount) as 'total_amount_sum'
from customers as c1
left join orders as o1
on c1.customer_id=o1.customer_id
group by customer_name

#order item popularatiy seasons wise

Spring → March–May (3–5)
Summer → June (6)
Monsoon → July–September (7–9)
Winter → October–February (10–12, 1–2)

select order_item,
case
when extract(month from order_date) between 3 and 5 then 'spring'
when extract(month from order_date) between 7 and 9 then 'Monsoon'
when extract(month from order_date) between 10 and 12 then 'Winter'
when extract(month from order_date) between 1 and 2 then 'Winter'
when extract(month from order_date)=6 then 'Summer'
end as seasons,
count(order_id) as k
from orders
group by 1,2
order by 1,2 and k desc
