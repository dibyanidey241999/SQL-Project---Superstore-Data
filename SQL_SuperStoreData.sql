select * from ['Master Data$']

select [Order ID], [Customer ID], [Product ID], [Postal Code], Sales, Profit into Fact from ['Master Data$']

select [Order ID], [Order Date], [Ship Date], [Ship Mode] into Orders_MD from ['Master Data$']

select [Customer ID], [Customer Name], Segment into Customers_MD from ['Master Data$']

select [Product ID], Category, [Sub-Category], [Product Name] into Products_MD from ['Master Data$']

select [Postal Code], Region, Country, City, State into Location_MD from ['Master Data$']

select * from Fact
select * from Orders_MD
select * from Customers_MD
select * from Products_MD
select * from Location_MD


------removing duplicates--------
with cte as 
	(select [Order ID], row_number() over(partition by [Order ID] order by [Order ID]) row_num FROM Orders_MD)
DELETE FROM cte
WHERE row_num > 1

 
----removing null values----
delete from Orders_MD
where [Order ID] is null

-----adding primary key------
alter table Orders_MD 
add primary key ([Order ID])

WITH cte AS (
    SELECT [Customer ID], [Customer Name], Segment,
	ROW_NUMBER() OVER(
	PARTITION by [Customer Name], Segment
	order by [Customer Name], Segment) row_num
    FROM Customers_MD)
DELETE FROM cte
WHERE row_num > 1

delete from Customers_MD
where [Customer ID] is null

alter table Customers_MD
alter column [Customer ID] varchar (50) not null

alter table Customers_MD
add primary key ([Customer ID])

WITH cte AS (
    SELECT [Product ID], ROW_NUMBER() 
	OVER(PARTITION BY [Product ID]
	order by [Product ID]) row_num
    FROM Products_MD)
DELETE FROM cte
WHERE row_num > 1

delete from Products_MD
where [Product ID] is null

alter table Products_MD
alter column [Product ID] varchar (50) not null

alter table Products_MD
add primary key ([Product ID])

WITH cte AS (
    SELECT [Postal Code], ROW_NUMBER() 
	OVER(PARTITION BY [Postal Code]
	order by [Postal Code]) row_num
    FROM Location_MD)
DELETE FROM cte
WHERE row_num > 1

delete from Location_MD
where [Postal Code] is null

alter table Location_MD
alter column [Postal Code] varchar (50) not null

alter table Location_MD
add primary key ([Postal Code])

alter table Fact
add foreign key ([Order ID]) references Orders_MD([Order ID])

alter table Fact
add foreign key ([Customer ID]) references Customers_MD([Customer ID])

alter table Fact
add foreign key ([Product ID]) references Products_MD([Product ID])

alter table Fact
add foreign key ([Postal Code]) references Location_MD([Postal Code])




-----top 5 customers-----

select top 5 a.[Customer ID], a.[Customer Name], b.Sales as Sum_of_Sales, b.Profit as Profit, (b.Profit/b.Sales) as Profit_Margin, row_number() over(order by sales desc) as Ranks_by_Sales
from Customers_MD a
inner join Fact b
on a.[Customer ID] = b.[Customer ID]




-------customer retention rate-----

select(
	(select COUNT(*) as RepeatCustomers from
		(select[Customer ID], count([Order ID]) as orders from Fact
		group by [Customer ID]
		having count([Order ID]) > 1)
		as repeat_customers)*1.0/
	(select COUNT(*) as TotalCustomers from
		(select [Customer ID], count([Order ID]) as No_of_Orders from Fact
		group by [Customer ID])
		as total_customers)
) as Customer_Retention_Rate





-----top 10 cities with max no. of customers-----

select top 10 City, COUNT(distinct [Customer ID]) as No_of_Customers 
from Location_MD a
inner join Fact b
on a.[Postal Code] = b.[Postal Code]
group by City
order by No_of_Customers desc




----top 3 sub-categories of each category----

select * from 
	(select Category, [Sub-Category], sum(sales) as Total_Sales, rank() over(partition by [Category] order by sum(Sales) desc) as Rank 
	from Products_MD P, Fact F
	where P.[Product ID] = F.[Product ID]
	group by [Sub-Category], Category) as a
where Rank<=3





---------customers who didn't place orders in the last 2 months---------

select a.[Customer ID], a.[Customer Name], b.[Order ID] from Customers_MD a
inner join Fact b
on a.[Customer ID] = b.[Customer ID]
where b.[Order ID] not in 
	(select [Order ID] from Orders_MD
	where [Order Date] >= 
		(select dateadd(month, -2, max([Order Date]))
		from Orders_MD
	)
)
