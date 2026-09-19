create database Policy_AnalyticalProject;
use policy_AnalyticalProject;
rename table `policy data` to `Customer Information`;
select* from `customer information`;
-- (2) Kpi
select count(*) as Total_Customers
from `customer information`;

-- (3) kpi
select count(*) as Total_Policies
from `policy details`;

-- (4) kpi
select
case
when sum(`claim amount`) >=1000000 then concat(round(sum(`claim amount`)/1000000,2),"M")
when sum(`claim amount`) >=1000 then concat(round(sum(`claim amount`)/1000,2),"K")
else round(sum(`Claim Amount`),2)
end as claim_amount
from `claims`;
-- (5) kpi
select
case
when avg(`coverage amount`) >=1000000 then concat(round(avg(`coverage amount`)/1000000,2),"M")
when avg(`coverage amount`) >=1000 then concat(round(avg(`coverage amount`)/1000,2),"K")
else round(avg(`coverage amount`),2)
end as avg_coverage_amount
from `policy details`;

-- (6) kpi
select
case
when avg(`Premium amount`) >=1000000 then concat(round(avg(`premium amount`)/1000000,2),"M")
when avg(`premium amount`) >=1000 then concat(round(avg(`premium amount`)/1000 ,2),"K")
else round(avg(`premium amount`),2)
end as avg_premium_amount
from `policy details`;

-- (7) Percentage of policies are currently active
select
round(100.0 *count(case when status = "Active" then 1 end)/
nullif(count(*),0),2) as Active_policy_percentage
from `policy details`;

-- (8) active,lapsed,terminated policies
select status, count(`ï»¿Policy ID`) as Total_Policies
from `policy details`
group by status
order by Total_policies asc; 

-- (9) Highest policies by status
select status,count(`ï»¿Policy ID`) as Highest_policies
from `policy details`
group by status
order by Highest_policies desc
limit 1;

-- (10) Ratio Between Active policies and Inactive policies

select
count(case when status ='Active' then 1 end) as Active_count,
count(case when status in ('lapsed','terminated')then 1 end ) as inactive_count,
round(1.0 * count(case when status = 'Active' then 1 end)/nullif(count(case when status in ('Lapsed','Terminated') then 1 end),0),2) as active_inactive_ratio,
concat(round(1.0 * count(case when status = 'Active' then 1 end)/nullif(count(case when status in ('Lapsed','Terminated')then 1 end),0),2),': 1' ) as Ratio_between
from `policy details`;

-- (11) creating column for age_group
alter table `customer information` add column Age_group varchar(20);
 update `customer information` 
 set Age_group  = 
 case
 when  age <= 18 then 'under 18'
 when age <=27 then ' 18-27'
 when age <=37 then '28-37'
 when  age <=47 then '38-47'
 when age <=57 then '48-57'
 when age <=67 then '58-67'
 when age <=77 then '68-77'
 when age <=87 then '78-87'
 when age <=99 then '88-99'
 else 'Unknoum'
 end;
  
  select* from `customer information`;
  
  -- age_group of policies
  
  select age_group,count(*) as total_policies
  from `customer information`
  group by age_group
  order by total_policies desc;
  
  -- (12) Top 3 age_groups by policy_count
select age_group,count(*)as policy_count
from `customer information`
group by age_group
order by policy_count desc
limit 3;

-- (13) gender policy participation
select gender,count(*) as total_policies,
round(100.0 * count(*)/sum(count(*)) over(),2) as Percentage
from `customer information`
group by gender
order by total_policies desc;

-- (14) difference between male and female policy count along with percentage
select
count(case when lower(gender)= 'Male' then 1 end) as Male_count ,
count(case when lower(gender) = 'Female' then 1 end) as Female_count,
count(case when lower(gender) = 'Male' then 1 end) - count(case when lower(gender)='Female' then 1 end) as difference,
round(100.0 * (count(case when lower(gender)='Male' then 1 end) - count(case when lower(gender) = 'Female' then 1 end))/nullif(count(*),0),2) as percentage
from `customer information`;

-- (15) and (16) Maximum and Minimum policies

with policy_counts as (
select
`policy type`, count(*) as policy_count
from `policy details`
group by `policy type`
)
(select `policy type`,policy_count ,'Maximum' as total
from policy_counts
order by policy_count desc
limit 1)
union all
(select `policy type`,policy_count,'Minimum' as total
from policy_counts
order by policy_count asc
limit 1);

-- (17) differnce between auto and health policy counts 
select
count(case when `policy type` = 'Health' then 1 end) as Health_count,
count(case when `policy type` = 'Auto' then 1 end) as Auto_count,
count(case when `policy type` = 'Health' then 1 end) - count(case when `policy type` = 'Auto' then 1 end) as Difference
from `policy details`;

-- (18) total policies with policy type
select `policy type`,count(*) as total_policies
from `policy details`
group by `policy type`
order by total_policies desc;

-- (19)  yearly_growth rate

with yearly_premium as (
select
year(`policy start date`) as policy_year,
sum(`premium amount`) as total_premium
from `policy details`
group by policy_year
)
select
policy_year,
total_premium,
lag(total_premium) over(order by policy_year) as prev_year_premium,
concat(
round(
(((total_premium)-lag(total_premium) over(order by policy_year))
/lag(total_premium)over (order by policy_year))*100,2),
"%"
)as yearly_growth_rate
from yearly_premium
order by policy_year;

 -- average growth_rate
 
with yearly_premium as (
select
year(`policy start date`) as policy_year,
sum(`premium amount`) as total_premium
from `policy details`
group by policy_year
),
Growth_rate as (
select 
policy_year,
((total_premium - lag(total_premium) over(order by policy_year))
/ lag(total_premium) over(order by policy_year))*100 as growth_rate
from yearly_premium
)
select 
concat(round(avg(growth_rate),2),"%")as avg_growth_rate_percentage
from growth_rate
where growth_rate is not null;

-- (20)  growth_rate trend

with yearly_premium as (
select
year(`policy start date`) as policy_year,
sum(`premium amount`) as total_premium
from `policy details`
group by policy_year
)
select
policy_year,
total_premium,
round(((total_premium-lag(total_premium)over(order by policy_year)) 
/lag(total_premium) over(order by policy_year))*100
,2
) as growth_percentage,
case
when total_premium > lag(total_premium) over(order by policy_year) then "Increasing"
when total_premium < lag(total_premium)over(order by policy_year) then "Decreasing"
else "No change"
end as trend
from yearly_premium
order by policy_year;

-- (21) difference between highest and lowest premium growth_rate
with yearly_premium as (
select
year(`policy start date`) as policy_year,
sum(`premium amount`) as total_premium
from `policy details`
group by policy_year
),
growth_rate as (
select
((total_premium-lag(total_premium) over (order by policy_year))
/lag(total_premium) over(order by total_premium))*100 as growth_rate
from yearly_premium
)
select
concat(round(max(growth_rate),2),"%") as Highest_growth_rate,
concat(round(min(growth_rate),2),"%") as lowest_growth_rate,
concat(round(max(growth_rate)-min(growth_rate),2),"%") as differnce
from growth_rate
where growth_rate is not null;

-- (22) yearly_policies from 2016 to 2034
select
year(`policy end date`) as ending_year,
count(*) as total_policies
from `policy details`
where year(`Policy End Date`) between 2016 and 2034
group by ending_year
order by ending_year asc;