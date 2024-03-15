---Total Rows 541909
---Total Rows with null value 135080
---Total rows with value 406829


With Online_Retail as
(
	SELECT  [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [Portfoilio].[dbo].[Cohorant]
	  where CustomerID IS NOT NULL
), Qunatity_unit_price as
(
--- Total Rows after qty and price >0 is 397884
	select * from Online_Retail
	where Quantity>0 AND UnitPrice>0
), Dup_check as
(
	---duplicate check
	select * , ROW_NUMBER() Over(partition by InvoiceNo,StockCode,Quantity order by InvoiceNo)dueflag
	from Qunatity_unit_price
)
Select * into #online_retail_main 
from Dup_check
where dueflag=1
---Total Rows after duplicate is 392669
--- Total duplicates is 5215

---Clean Data Set
--- Begin Cohorant Analysis

select * from online_retail_main

---Unique Identifier(InvoiveID)
---Initial Start Date(Forst Invoice Date)
---Revenue data

select CustomerID,
	min(InvoiceDate) as first_purchase_date,
	DATEFROMPARTS(year(min(InvoiceDate)),month(min(InvoiceDate)),1) as cohort_date
	into #cohort
from online_retail_main
group by CustomerID

Select * from #cohort
---Create cohort index

select mmm.*,
	cohort_index= year_diff * 12 + month_diff +1
	into #cohort_retention
from
	(
		Select mm.*,
			year_diff=invoice_year -cohort_year,
			month_diff=invoice_month - cohort_month
		from
			(
				select m.*,
					c.cohort_date,
					year(m.InvoiceDate)as invoice_year,
					month(m.InvoiceDate)as invoice_month,
					year(c.cohort_date) as cohort_year,
					month(c.cohort_date) as cohort_month
				from online_retail_main m 
				left join #cohort c on m.CustomerID=c.customerID
				) as mm
		)mmm


select *  from #cohort_retention

---Pivot data to see the cohort table

Select *
into #cohort_pivot
from
	(
	select distinct
		CustomerID,
		cohort_date,
		cohort_index
	from #cohort_retention
	) tbl
	pivot (
			Count(CustomerID)
			for Cohort_Index IN
				(
				[1],
				[2],
				[3],
				[4],
				[5],
				[6],
				[7],
				[8],
				[9],
				[10],
				[11],
				[12],
				[13])
	)as pivot_table


select Cohort_Date ,
	(1.0 * [1]/[1] * 100) as [1], 
    1.0 * [2]/[1] * 100 as [2], 
    1.0 * [3]/[1] * 100 as [3],  
    1.0 * [4]/[1] * 100 as [4],  
    1.0 * [5]/[1] * 100 as [5], 
    1.0 * [6]/[1] * 100 as [6], 
    1.0 * [7]/[1] * 100 as [7], 
	1.0 * [8]/[1] * 100 as [8], 
    1.0 * [9]/[1] * 100 as [9], 
    1.0 * [10]/[1] * 100 as [10],   
    1.0 * [11]/[1] * 100 as [11],  
    1.0 * [12]/[1] * 100 as [12],  
	1.0 * [13]/[1] * 100 as [13]
from #cohort_pivot
order by Cohort_Date

