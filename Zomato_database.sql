create database zomato;
use zomato
create table customers(
customer_id int primary key,
customer_name varchar(25),
reg_date date
);
create table restaurants(
restaurant_id int primary key,
restaurant_name varchar(55),
city varchar(15),
opening_hours varchar(55)
);
create table deliveries(
delivery_id int primary key,
order_id int, -- this is coming order table
delivery_status varchar(35),
delivery_time time,
rider_id int -- this is coming from riders
);
alter table deliveries
add constraint fk_orders
foreign key (order_id)
references orders(order_id),
add constraint ref_riders
foreign key (rider_id)
references riders(rider_id)



create table orders(
order_id int primary key,
customer_id int ,-- this is come from customer table
restaurant_id int,-- this is come from resturent table
order_item varchar(55),
order_date date,
order_time time,
order_status varchar(55),
total_amount float
);
alter table orders
add constraint fk_customer
foreign key (customer_id)
references customers(customer_id),
add constraint fk_restaurants
foreign key (restaurant_id)
references restaurants(restaurant_id)


create table riders(
rider_id int primary key,
rider_name varchar(55),
signup_date date
);



