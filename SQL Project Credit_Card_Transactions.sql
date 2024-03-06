select *from credit_card_transactions


--solve below questions

--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte1 as (
select  city,sum(amount) as total_spent
from credit_card_transactions
group by city)
,total_spend as (select sum(cast(amount as bigint)) as total_amount from credit_card_transactions)
select top 5 cte1.*,  cast(total_spent as float)/total_amount as percentage_spemd
from cte1, total_spend
order by total_spent desc



--2- write a query to print highest spend month and amount spent in that month for each card type
select *from credit_card_transactions;


with cte1 as(
select card_type,datepart(year,transaction_date) as year_part,datepart(month,transaction_date) as month_part, sum(amount) as high_spent
from credit_card_transactions
group by card_type, datepart(year,transaction_date) ,datepart(month,transaction_date)

)
select *from (select *, rank() over(partition by card_type order by high_spent desc) as rn
from cte1) a
where rn=1


/*3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/


with cte1 as (
select *, sum(amount) over (partition by card_type order by transaction_date, transaction_id) as total_spend
from credit_card_transactions
)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn
from cte1 where total_spend>=1000000) as a
where rn=1


--4- write a query to find city which had lowest percentage spend for gold card type
select *from credit_card_transactions
with cte1 as(
select city,card_type,sum(amount)as total_amount,
sum(case when card_type='Gold' then amount end) as gold_amount 
from credit_card_transactions
group by city,card_type
)
select top 1 city, sum(gold_amount)*1.0/ sum(total_amount) as gold_ratio
from cte1
group by city
having sum(gold_amount) is not null
order by gold_ratio


--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
select *from credit_card_transactions

with cte1 as(
select city, exp_type, sum(amount) as exp_sum
from credit_card_transactions
group by city,exp_type
--order by city,exp_type
)
select city,
max(case when rn1=1 then exp_type end)as lowest_expense_type,
min(case when rn2=1 then exp_type end)as lowest_expense_type
from
( select*, rank() over(partition by city order by exp_sum)         as rn1,
		rank() over(partition by city order by exp_sum desc)    as rn2
from cte1) as a
group by city

--6- write a query to find percentage contribution of spends by females for each expense type
select*from credit_card_transactions
with cte1 as (
select exp_type,sum(amount) as total_amount, sum(case when gender= 'F' then amount end) as exp_amnt_female
from credit_card_transactions
group by exp_type)
select exp_type,sum(exp_amnt_female)*1.0/sum(total_amount) as per_contribution
from cte1
group by exp_type
order by per_contribution

 

--7- which card and expense type combination saw highest month over month growth in Jan-2014
select *from credit_card_transactions
with cte1 as (
select card_type, exp_type,datepart(year,transaction_date)as year_part,datepart(month,transaction_date)as mon_part,sum(amount) as exp_amount
from credit_card_transactions
group by  card_type, exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
--order by  card_type, exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select top 1 *, (exp_amount-prev_month) as mon_growth
from(
select*
,lag(exp_amount,1) over(partition by card_type, exp_type order by year_part,mon_part) as prev_month
from cte1) a
where prev_month is not null and year_part=2014 and mon_part=1
order by mon_growth desc




--8- during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city , sum(amount)*1.0/count(1) as ratio
from credit_card_transactions
where datepart(weekday,transaction_date) in (1,7)
--where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc;

--9- which city took least number of days to reach its
--500th transaction after the first transaction in that city;

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transactions)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 
