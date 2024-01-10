use Northwind 
go

--------------------
--                --
--  NA ZAJĘCIACH  --
--                --
--------------------

-- wyświetl najdroższe produkty w danej kategorii

select
    c.CategoryName
    , p.ProductName
    , p.UnitPrice
from Categories c
inner join Products p
    on c.CategoryID = p.CategoryID
inner join (
    select
        CategoryID
        , max( UnitPrice ) UnitPrice
    from Products
    group by CategoryID
) s
    on s.UnitPrice = p.UnitPrice
    and s.CategoryID = p.CategoryID
go
/* Lub zap. skorelowanym */
select
    c.CategoryName
    , p.ProductName
    , p.UnitPrice
from Categories c
inner join Products p
    on c.CategoryID = p.CategoryID
where UnitPrice in (
    select
        max( UnitPrice ) UnitPrice
    from Products p1
    where p.CategoryID = p1.CategoryID
)
go


-- Dwa najdroższe produkty w danej kategorii

select
    c.CategoryName
    , p.ProductName
    , p.UnitPrice
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
where UnitPrice in (
	select top 2 with ties
	    UnitPrice
    from Products p1
    where p.CategoryID = p1.CategoryID
	order by UnitPrice desc
)
go
/* Lub z CTE */
with MaxPriceByCategory (CategoryID, MaxUnitPrice) as (
	select
		CategoryID
		, max( UnitPrice ) MaxUnitPrice
	from Products p1
	group by CategoryID
)
select
    c.CategoryName
    , p.ProductName
    , p.UnitPrice
from Categories c
inner join Products p
    on c.CategoryID = p.CategoryID
inner join MaxPriceByCategory m
	on p.CategoryID = m.CategoryID
	and p.UnitPrice = m.MaxUnitPrice
go
/* Lub kilka CTE */
with MaxPriceByCategory (CategoryID, MaxUnitPrice) as (
	select
		CategoryID
		, max( UnitPrice ) MaxUnitPrice
	from Products p1
	group by CategoryID
)
, CategoryAndProduct as (
	select
		c.CategoryName
		, c.CategoryID
		, p.ProductName
		, p.UnitPrice
	from Categories c
	inner join Products p
	    on c.CategoryID = p.CategoryID
)
select 
	c.CategoryName
	, c.ProductName
	, c.UnitPrice
from MaxPriceByCategory m, CategoryAndProduct c
where m.CategoryID = c.CategoryID
	and m.MaxUnitPrice = c.UnitPrice
go


-- jaka jest wat. sprzedaży w poszczególnych latach?

select
	year( o.OrderDate ) [Year]
	, sum( od.UnitPrice * od.Quantity ) Sales
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
group by year( o.OrderDate )
go


-- jaka jest wat. sprzedaży w poszczególnych miesiącach lat 1996 i '97?

select
	year( o.OrderDate ) [Year]
	, month( o.OrderDate ) [Month]
	, sum( od.UnitPrice * od.Quantity ) Sales
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
where year( o.OrderDate ) between 1996 and 1997
group by year( o.OrderDate ), month( o.OrderDate )
go


-- jaka jest wartość sprzedaży w poszczególnych miesiącach dwóch lat 
--   o największej wartości realizacji sprzedaży (operator with)

with SalesPerMonth as (
	select
		year( o.OrderDate ) [Year]
		, month( o.OrderDate ) [Month]
		, sum( od.UnitPrice * od.Quantity ) Sales
	from Orders o
	inner join [Order Details] od
		on o.OrderID = od.OrderID
	group by year( o.OrderDate ), month( o.OrderDate )
)
select
	*
from SalesPerMonth
where Year in (
	select top 2 Year
	from SalesPerMonth
	group by [Year]
	order by sum( Sales )
)
go


-- który z pracowników zrealizował największą liczbę zamówień, w każdym
--   z lat funkcjonowania firmy

with OrdersPerEmployee as (
	select
		o.EmployeeID
		, count( * ) OrdersCount
		, year( o.OrderDate ) [Year]
	from Orders o
	group by o.EmployeeID, year( o.OrderDate )
)
, MostSalesInYear as (
	select
		ope.[Year]
		, max( ope.OrdersCount ) MaxOrdersCount
	from OrdersPerEmployee ope
	group by [Year]
)
, EmployeeOfTheYear as (
	select
		ope.*
	from
		OrdersPerEmployee ope
		, MostSalesInYear msiy
	where ope.Year = msiy.Year
		and ope.OrdersCount = msiy.MaxOrdersCount
)
select
	concat_ws(' ', e.FirstName, e.LastName) EmployeeName
	, eoty.OrdersCount
	, eoty.[Year]
from 
	Employees e
	, EmployeeOfTheYear eoty
where e.EmployeeID = eoty.EmployeeID
go

-- jaki klient kupił za największą kwotę sumarycznie, w każdym z lat funkcjonowania firmy

with OrderTotals as (
	select
		od.OrderID
		, sum( od.Quantity * od.UnitPrice ) Total
	from [Order Details] od
	group by od.OrderID
)
, OrderTotalDetails as (
	select
		ot.OrderID
		, ot.Total
		, year( o.OrderDate ) [Year]
		, o.CustomerID
	from 
		Orders o
		, OrderTotals ot
	where o.OrderID = ot.OrderID
)
, BiggestOrdersInYear as (
	select
		otd.[Year]
		, max( otd.Total ) MaxTotal
	from OrderTotalDetails otd
	group by otd.[Year]
)
, SalesOfTheYear as (
	select
		otd.*
	from 
		OrderTotalDetails otd
	where exists (
		select 1
		from BiggestOrdersInYear boiy
		where otd.[Year] = boiy.[Year]
			and otd.Total = boiy.MaxTotal
	)
)
select
	c.CompanyName
	, soty.Total
	, soty.[Year]
from
	Customers c
	, SalesOfTheYear soty
where c.CustomerID = soty.CustomerID
go
/* lub */
with OrderTotals as (
	select
		od.OrderID
		, sum( od.Quantity * od.UnitPrice ) Total
	from [Order Details] od
	group by od.OrderID
)
, OrderTotalDetailsRanked as (
	select
		ot.OrderID
		, ot.Total
		, year( o.OrderDate ) [Year]
		, o.CustomerID
		, rank() over ( partition by year( o.OrderDate ) order by ot.Total desc) YearRank
	from 
		Orders o
		, OrderTotals ot
	where o.OrderID = ot.OrderID
)
select
	c.CompanyName
	, otdr.Total
	, otdr.[Year]
from 
	Customers c
	, OrderTotalDetailsRanked otdr
where c.CustomerID = otdr.CustomerID
	and YearRank = 1
go


-- znajdź faktury każdego z klientów opiewające na najwyższe kwoty

with OrderTotals as (
	select
		od.OrderID
		, sum( od.Quantity * od.UnitPrice ) Total
	from [Order Details] od
	group by od.OrderID
)
, OrderTotalDetailsRanked as (
	select
		ot.OrderID
		, ot.Total
		, o.CustomerID
		, rank() over ( partition by o.CustomerID order by ot.Total desc) TotalRank
	from 
		Orders o
		, OrderTotals ot
	where o.OrderID = ot.OrderID
)
select 
	c.CompanyName
	, otdr.OrderID
	, otdr.Total
from
	OrderTotalDetailsRanked otdr
	, Customers c
where otdr.CustomerID = c.CustomerID
	and otdr.TotalRank = 1
go


-- podaj najlepiej sprzedające się produkty w każdej z kategorii

with OrderQuantitiesProducts as (
	select
		od.ProductID
		, sum( od.Quantity ) TotalQuantity
		, rank() over ( partition by p.CategoryID order by sum( od.Quantity ) desc ) TotalQuantityRank
		, p.CategoryID
	from 
		[Order Details] od
		, Products p
	where od.ProductID = p.ProductID
	group by 
		p.CategoryID
		, od.ProductID
)
select
	c.CategoryName
	, p.ProductName
	, oqp.TotalQuantity
from 
	OrderQuantitiesProducts oqp
	, Categories c
	, Products p
where oqp.CategoryID = c.CategoryID
	and oqp.ProductID = p.ProductID
	and oqp.TotalQuantityRank = 1
go


-- jakie zamówienia zostały zrealizowane w ostatnich 2 miesiącach realizacji zamówień

with LastTwoMonths as (
	select distinct top 2
		year( o.OrderDate ) OrderYear
		, month( o.OrderDate ) OrderMonth
	from Orders o
	order by OrderYear desc, OrderMonth desc
)
select
	o.OrderID
	, o.OrderDate
from Orders o
where exists (
	select 1
	from LastTwoMonths lts
	where lts.OrderYear = year( o.OrderDate )
		and lts.OrderMonth = month( o.OrderDate )
)
go

-- czy jest taki klient, który nie zrealizował zamówienia w ostatnich dwóch miesiącach realizacji zamówień

with LastTwoMonths as (
	select distinct top 2
		year( o.OrderDate ) OrderYear
		, month( o.OrderDate ) OrderMonth
	from Orders o
	order by OrderYear desc, OrderMonth desc
)
, CustomersOfLastTwoMonths as (
	select distinct
		o.CustomerID
	from Orders o
	where exists (
		select 1
		from LastTwoMonths lts
		where lts.OrderYear = year( o.OrderDate )
			and lts.OrderMonth = month( o.OrderDate )
	)
)
select
	c.CompanyName
from Customers c
where c.CustomerID not in (
	select * from CustomersOfLastTwoMonths
)
go
/* Tak, całkiem sporo takich klientów */


------------------
--              --
--  lab 05.sql  --
--              --
------------------

------------------------------------------------------
-- Agregacja danych, Group by, Having, Rollup, Cube --
------------------------------------------------------

select * 
from Suppliers
go


-- Ile jest dostawców i ilu dostawców ma podany w bazie danych faks  

select 
	count(*)
	, count(fax)
from Suppliers
go


-- Podaj nazwy państw dostawców bez powtórzeń

select distinct 
	country
from Suppliers
go


-- Ile jest państw gdzie znajdują się nasi dostawcy (jedna liczba)

select 
	count(distinct country)
from Suppliers


-- 1. Ile jest produktów w tabeli Products (count), wartość maksymalna ceny (max), minimalna cena (bez zera)(min) i wartość średnia (avg) (Dodaj produkt 'Prod X' z ceną NULL)

insert into Products (
	ProductName
	, UnitPrice
) values (
	'Prod X'
	, null
)

drop table if exists #InsertedProducts
select
	scope_identity() InsertedProductID
into #InsertedProducts

select
	count( * ) ProductCount
	, count( p.UnitPrice ) ProductCountWithPrice
	, max( p.UnitPrice ) MaxPrice
	, min( p.UnitPrice ) MinPrice
	, avg( p.UnitPrice ) AveragePrice
from Products p
go


-- 2. Liczymy dodatkowo wartość średnią jako suma podzielona przez liczbę produktów oraz oblicona z wykorzystaniem AVG - porównać wyniki.

select
	avg( p.UnitPrice ) [AveragePrice ViaFunction]
	, sum( p.UnitPrice ) / count( * ) [AveragePrice CountAll]
	, sum( p.UnitPrice ) / count ( p.UnitPrice ) [AveragePrice CountWithPrice]
from Products p
go
/* Funkcja AVG() uwzględnia wyłącznie rekordy, gdzie wartość podanej kolumny nie jest `null` */
/* Użycie count( * ) w formule liczącej daje niezgodną wartość */


-- 3. Jaka jest wartość towaru w magazynie

select
	sum( p.UnitPrice * p.UnitsInStock ) TotalValue
from Products p
go


-- 4. Jaka jest całkowita sprzedaż (bez upustów, z upustami, same upusty)

select
	sum( od.Quantity * p.UnitPrice ) TotalValueNormal
	, sum( od.Quantity * od.UnitPrice ) TotalValueOnInvoice
	, sum( od.Quantity * ( p.UnitPrice - od.UnitPrice ) ) TotalValueOfDiscounts
from [Order Details] od
inner join Products p
	on od.ProductID = p.ProductID
go


-- 5. Ile firm jest w danym kraju

with Companies as (
	select
		c.CompanyName
		, c.Country
	from Customers c
	union
	select
		s.CompanyName
		, s.Country
	from Suppliers s
)
select
	c.Country
	, count( * ) NumberOfCompanies
from Companies c
group by c.Country
go


-- 6. Ile firm jest w danym kraju zaczynających się na litery od a do f.

with Companies as (
	select
		c.CompanyName
		, c.Country
	from Customers c
	union
	select
		s.CompanyName
		, s.Country
	from Suppliers s
)
select
	c.Country
	, count( * ) NumberOfCompanies
from Companies c
where c.Country like '[a-f]%'
group by c.Country
go


-- 7. Ile firm jest w danym kraju zaczynających się na litery od a do f. wyświetl te kraje gdzie liczba firm jest >=3 (GROUP BY, HAVING)

with Companies as (
	select
		c.CompanyName
		, c.Country
	from Customers c
	union
	select
		s.CompanyName
		, s.Country
	from Suppliers s
)
select
	c.Country
	, count( * ) NumberOfCompanies
from Companies c
where c.Country like '[a-f]%'
group by c.Country
having count( * ) >= 3
go


-- 8. Podaj nazwę kraju, z których pochodzą pracownicy oraz ilu ich jest w danym kraju (tabela Employees) oraz ilość pracowników jest sumarycznie (jedno zapytanie) (jedno zapytanie z opcją rollup)

/* Bez rollup */
with EmployeesByCountry as (
	select
		e.Country
		, count( * ) NumberOfEmployees
	from Employees e
	group by e.Country
)
select
	ebc1.*
from EmployeesByCountry ebc1
union
select
	null
	, sum( ebc2.NumberOfEmployees )
from EmployeesByCountry ebc2
order by NumberOfEmployees
go

/* Z użyciem rollup */
select
	e.Country
	, count( * ) NumberOfEmployees
from Employees e
group by rollup ( e.Country )
go


-- Podaj na jaką kwotę znajduje sie towaru w magazynie

select 
	sum( UnitPrice * UnitsInStock )
from Products
go


-- Podaj na jaką kwotę znajduje sie towaru w magazynie w każdej kategorii (podajemy nazwę kategorii) oraz we wszystkich kategoriach (jedno zapytanie z opcją rollup)

select
	CategoryName
	, sum( UnitPrice * UnitsInStock )
from Categories c
inner join Products p 
	on c.CategoryID = p.CategoryID
group by rollup ( CategoryName )
--ORDER BY CategoryName


-- Podaj na jaką kwotę znajduje sie towaru w magazynie w każdej kategorii categoryid (są produkty bez kategorii i też ma byc wyświetlona ich kwota)

-- funkcja CAST (sprawdzamy w dokumentacji)
select
	isnull( cast( CategoryID as varchar ), 'brak kategorii' )
	, sum( UnitPrice * UnitsInStock )
from Products
group by CategoryID
--ORDER BY CategoryID

--funkcja CONVERT (sprawdzamy w dokumentacji)
select  
	isnull( convert( varchar, CategoryID ), 'brak kategorii' ) numer
	, sum( UnitPrice * UnitsInStock )
from Products
group by rollup ( isnull( convert( varchar, CategoryID ), 'brak kategorii' ) )
--ORDER BY 1


-- 9. Podaj na jaką kwotę znajduje sie towaru w magazynie w każdej kategorii categoryname (są produkty bez kategorii i też ma byc wyświetlona ich kwota)

declare @no_category as varchar(32) = '--Brak kategorii--'

select
	coalesce( c.CategoryName, @no_category ) CategoryName
	, sum( p.UnitPrice * p.UnitsInStock ) PriceOfStock
from Products p 
left join Categories c
	on p.CategoryID = c.CategoryID
group by rollup ( coalesce( c.CategoryName, @no_category ) )
go


-- 10. Podaj sumaryczną sprzedaż - tabela [order details] bez upustów

select
	od.OrderID
	, sum( od.Quantity * p.UnitPrice ) TotalSales
from [Order Details] od
inner join Products p
	on od.ProductID = p.ProductID
group by rollup ( od.OrderID )
go


-- 11. Podaj na jaką kwotę sprzedano towaru w każdej kategorii  (podaj wszystkie kategorie)

select
	c.CategoryName
	, sum( od.Quantity * p.UnitPrice ) TotalSales
from [Order Details] od
inner join Products p
	on od.ProductID = p.ProductID
right join Categories c
	on p.CategoryID = c.CategoryID
group by  c.CategoryName
go


-- 12. Podaj na jaką kwotę sprzedano towaru w każdej kategorii - podajemy tylko te kategorie w których sprzedano towaru za kwotę powyżej 200 000.

select
	c.CategoryName
	, sum( od.Quantity * p.UnitPrice ) TotalSales
from [Order Details] od
inner join Products p
	on od.ProductID = p.ProductID
right join Categories c
	on p.CategoryID = c.CategoryID
group by c.CategoryName
having sum( od.Quantity * p.UnitPrice ) > 200000
go


-- 13. Podaj ile rodzajów produktów było sprzedanych w kazdej kategorii

select
	c.CategoryName
	, count( distinct p.ProductID ) KindOfProductsSold
from [Order Details] od
inner join Products p
	on od.ProductID = p.ProductID
right join Categories c
	on p.CategoryID = c.CategoryID
group by c.CategoryName
go


-- 14. Porównujemy - -- nazwę kategorii, nazwę produktu i jego sprzedaż (wykorzystać cube następnie rollup i znajdujemy rónicę odejmując te zbiory)

declare @no_category as varchar(32) = '--Brak kategorii--'
declare @no_product as varchar(32) = '--Brak nazwy--'
;
with RollupTable as (
	select
		coalesce( c.CategoryName, @no_category ) CategoryName
		, coalesce( p.ProductName, @no_product ) ProductName
		, sum( od.Quantity * od.UnitPrice ) TotalSales
	from Categories c
	full join Products p
		on c.CategoryID = p.CategoryID
	left join [Order Details] od
		on p.ProductID = od.ProductID
	group by rollup (
		coalesce( c.CategoryName, @no_category )
		, coalesce( p.ProductName, @no_product )
	)
)
, CubeTable as (
	select
		coalesce( c.CategoryName, @no_category ) CategoryName
		, coalesce( p.ProductName, @no_product ) ProductName
		, sum( od.Quantity * od.UnitPrice ) TotalSales
	from Categories c
	full join Products p
		on c.CategoryID = p.CategoryID
	left join [Order Details] od
		on p.ProductID = od.ProductID
	group by cube (
		coalesce( c.CategoryName, @no_category )
		, coalesce( p.ProductName, @no_product )
	)
)
select
	*
from CubeTable
except
select
	*
from RollupTable
go


-- 15. który z pracowników sprzedaż towarów za największą kwotę

with EmployeeSales as (
	select
		o.EmployeeID
		, sum( od.Quantity * od.UnitPrice ) TotalSales
	from [Order Details] od
	inner join Orders o
		on od.OrderID = o.OrderID
	group by o.EmployeeID
)
select top 1
	concat_ws( ' ', e.FirstName, e.LastName ) EmployeeName
	, es.TotalSales
from EmployeeSales es
inner join Employees e
	on es.EmployeeID = e.EmployeeID
order by es.TotalSales desc
go


-- 16. Podaj klienta, nazwę kategorii i sumaryczną jego sprzedaż w każdej z nich

declare @no_sales as varchar(32) = '--Brak sprzedaży--'

select
	cs.CompanyName
	, ct.CategoryName
	, coalesce( cast( sum( od.Quantity * od.UnitPrice ) as varchar(32) ), @no_sales ) TotalSales
	, od.Quantity
from Customers cs
left join Orders o
	on cs.CustomerID = o.CustomerID
left join [Order Details] od
	on o.OrderID = od.OrderID
left join Products p
	on od.ProductID = p.ProductID
full join Categories ct
	on p.CategoryID = ct.CategoryID
group by rollup (
	cs.CompanyName
	, ct.CategoryName
)
go

-- 17. Jaki spedytor przewiózł największą wartość sprzedanych towarów

with ShipperSales as (
	select
		o.ShipVia
		, sum( od.Quantity * od.UnitPrice ) TotalSales
	from [Order Details] od
	inner join Orders o
		on od.OrderID = o.OrderID
	group by o.ShipVia
)
select top 1
	s.CompanyName
	, ss.TotalSales
from ShipperSales ss
inner join Shippers s
	on ss.ShipVia = s.ShipperID
order by ss.TotalSales desc
go


-- 18. Wykorzystać funkcję grouping do zapytania podającego nazwę kategorii, nazwę produktu i jego sprzedaż

with CategoryProductSalesSummary as (
	select
		c.CategoryName
		, p.ProductName
		, sum( od.Quantity * od.UnitPrice ) TotalSales
		, grouping( c.CategoryName ) g_c
		, grouping( p.ProductName ) g_p
	from Categories c
	full join Products p
		on c.CategoryID = p.CategoryID
	left join [Order Details] od
		on p.ProductID = od.ProductID
	group by rollup (
		c.CategoryName
		, p.ProductName
	)
)
select
	coalesce( 
		CategoryName
		, case g_c
			when 0 then 'Brak kategori'
			else '--- Podsumowanie ---'
		end
	) CategoryName
	, coalesce(
		ProductName
		, case g_p
			when 0 then 'Brak produktów'
			else '--- Podsumowanie ---'
		end
	) ProductName
	, coalesce( cast( TotalSales as varchar ), 'Brak sprzedaży' ) TotalSales
from CategoryProductSalesSummary


------ funkcje, agregacje:
------------------------------------------------------------------------------------------
-- Agregacja danych, funkcje związaną z datą, zapytania z podzapytaniami, zapytania CTE --
------------------------------------------------------------------------------------------

-- 1. Podaj aktualną datę systemową

select sysdatetime() CurrentDateTime 
go


-- 2. Jak dodać jedną godzinę do daty systemowej

select dateadd( hour, 1, sysdatetime() ) [CurrentDateTime + 1h]
go

-- 3. Podaj z daty systemowej osobno rok, miesięc i dzień podany jako typ integer (YEAR, MONTH, DAY)

select
	year( sysdatetime() ) CurrentYear
	, month( sysdatetime() ) CurrentMonth
	, day( sysdatetime() ) CurrentDay
go


-- 4. Podaj z daty systemowej osobno rok, miesięc i dzień podany jako typ integer (funkcja DATEPART)

select
	datepart( year, sysdatetime() ) CurrentYear
	, datepart( month, sysdatetime() ) CurrentMonth
	, datepart( day, sysdatetime() ) CurrentDay
go


-- 5. Podaj z daty systemowej osobno godzinę, miinuty i sekundy jako typ integer (funkcja DATEPART)

select
	datepart( hour, sysdatetime() ) CurrentHour
	, datepart( minute, sysdatetime() ) CurrentMinute
	, datepart( second, sysdatetime() ) CurrentSecond
go


-- 6. Podaj z daty systemowej osobno rok, miesięc i dzień podany jako typ char (funkcja DATENAME)

select
	datename( year, sysdatetime() ) CurrentYear
	, datename( month, sysdatetime() ) CurrentMonth
	, datename( day, sysdatetime() ) CurrentDay
go


-- 7. Podaj nazwę aktualnego miesięca podanego jako nazwa oraz dzień w postaci nazwy (kwiecień, poniedziałek) oraz (april, monday)
    -- select @@LANGUAGE /* us_english */

set language POLISH
select
	datename( month, sysdatetime() ) ObecnyMiesiac
	, datename( dayofyear, sysdatetime() ) ObecnyDzienTygodnia
go

set language US_ENGLISH
select
	datename( month, sysdatetime() ) CurrentMonth
	, datename( dayofyear, sysdatetime() ) CurrentDayOfWeek
go


-- 8. Ile lat upłyneło od ostatniego zamówienia (funkcja DATEDIFF)

select
	datediff(
		year
		, ( select max( OrderDate ) from Orders )
		, sysdatetime()
	) YearsSinceLastOrder
go


-- 9. Ile miesięcy upłyneło od ostatniego zamówienia (funkcja DATEDIFF)

select
	datediff(
		month
		, ( select max( OrderDate ) from Orders )
		, sysdatetime()
	) MonthsSinceLastOrder
go


-- 10. Dodaj do bieżącej daty 3 miesięce (funkcja DATEADD)

select dateadd( month, 3, sysdatetime() ) [CurrentDateTime + 3mnth]
go
/* lub */
select dateadd( quarter, 1, sysdatetime() ) [CurrentDateTime + 3mnth]
go


-- 11. W jaki dzień obchodzimy w tym roku urodziny (korzystamy z funkcji CONVERT do zamiany naszej daty tekstowej na typ DATETIME lub DATE)

select datename( weekday, convert( datetime, '2024-06-18' ) ) WeekDayOfBirthday
go


-- 12. W jaki dzień tygodnia przypada w przyszłym roku w ostatni dzień lutego oraz ile dni ma luty w przyszłym roku 
   --(korzystamy z funkcji CONVERT do zamiany naszej daty tekstowej na typ datetime bez korzystania z funkcji EOMONTH()
   --a następnie z korzystamy z funkcji EOMONTH())

with LastDayOfFeb as (
	select dateadd( day, -1, convert( datetime, '2024-03-01' ) ) Val
)
select 
	datename( weekday, Val ) WeekDayOfLastDayOfFebruary
	, day( Val ) DaysInFebruary
from LastDayOfFeb
go
/* lub z eomonth */
with LastDayOfFeb as (
	select eomonth( convert( datetime, '2024-02-01' ) ) Val
)
select 
	datename( weekday, Val ) WeekDayOfLastDayOfFebruary
	, day( Val ) DaysInFebruary
from LastDayOfFeb
go


-- 13. W jakich kolejnych latach była realizowana sprzedaż w bazie NORTHWIND

select distinct
	year( o.OrderDate ) Years 
from Orders o
order by Years
go


-- 14. Podaj sprzedaż towarów, w każdym roku działania firmy (bez upustów)

select
	year( o.OrderDate ) [Year]
	, sum( od.Quantity ) NumberOfSoldProducts
	, sum( od.Quantity * od.UnitPrice ) TotalSales
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
group by year( o.OrderDate )
go


-- 15. Podaj sprzedaż towarów w każdym roku i miesięcu działania firmy
   -- rok i miesięc podajemy w jednej kolumnie 

select
	format( o.OrderDate, 'yyyy-MM' ) [Year Month]
	, sum( od.Quantity ) NumberOfSoldProducts
	, sum( od.Quantity * od.UnitPrice ) TotalSales
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
group by 
	format( o.OrderDate, 'yyyy-MM' )
go


-- 16. Podaj sprzedaż towarów w każdym roku i miesięcu działania firmy
   -- rok i miesięc podajemy w osobnych kolumnach)
  
select
	year( o.OrderDate ) [Year]
	, month( o.OrderDate ) [Month]
	, sum( od.Quantity ) NumberOfSoldProducts
	, sum( od.Quantity * od.UnitPrice ) TotalSales
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
group by
	year( o.OrderDate )
	, month( o.OrderDate )
order by
	year( o.OrderDate )
	, month( o.OrderDate )
go


-- 17. Do ostatniego zapytania dołóż klauzulę CUBE i ROLLUP i porównaj wyniki obu zapytań (EXCEPT)

drop table if exists #CubeTable
drop table if exists #RollupTable
go

select
	year( o.OrderDate ) [Year]
	, month( o.OrderDate ) [Month]
	, sum( od.Quantity ) NumberOfSoldProducts
	, sum( od.Quantity * od.UnitPrice ) TotalSales
into #CubeTable
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
group by
	year( o.OrderDate )
	, month( o.OrderDate )
	with cube
order by
	year( o.OrderDate )
	, month( o.OrderDate )
select * from #CubeTable
go

select
	year( o.OrderDate ) [Year]
	, month( o.OrderDate ) [Month]
	, sum( od.Quantity ) NumberOfSoldProducts
	, sum( od.Quantity * od.UnitPrice ) TotalSales
into #RollupTable
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
group by
	year( o.OrderDate )
	, month( o.OrderDate )
	with rollup
order by
	year( o.OrderDate )
	, month( o.OrderDate )
select * from #RollupTable
go

select * from #CubeTable
except
select * from #RollupTable
go

drop table if exists #CubeTable
drop table if exists #RollupTable
go


-- 18. Podaj numery zamówień, ich datę oraz całkowitą wartość (orderid, orderdate, unitprice*quantity) 
	-- oraz posortuj względem całkowitej wartości

with OrderTotals as (
	select
		od.OrderID
		, sum( od.UnitPrice * od.Quantity ) TotalSales
	from [Order Details] od
	group by od.OrderID
)
select
	ot.OrderID
	, o.OrderDate
	,  ot.TotalSales
from OrderTotals ot
inner join Orders o
	on ot.OrderID = o.OrderID
order by ot.TotalSales
go


-- 19. Podaj numery zamówień, ich datę oraz całkowitą wartość, 
	-- które były zrealizowane na największą wartość 

with OrderTotals as (
	select
		od.OrderID
		, sum( od.UnitPrice * od.Quantity ) TotalSales
	from [Order Details] od
	group by od.OrderID
)
select
	ot.OrderID
	, o.OrderDate
	,  ot.TotalSales
from OrderTotals ot
inner join Orders o
	on ot.OrderID = o.OrderID
order by ot.TotalSales desc
go


-- 20. Podaj numery zamówień, ich datę oraz całkowitą wartość, 
	-- które były zrealizowane na najmniejszą wartość(bez 0)

with OrderTotals as (
	select
		od.OrderID
		, sum( od.UnitPrice * od.Quantity ) TotalSales
	from [Order Details] od
	group by od.OrderID
)
select
	ot.OrderID
	, o.OrderDate
	,  ot.TotalSales
from OrderTotals ot
inner join Orders o
	on ot.OrderID = o.OrderID
where ot.TotalSales > 0
order by ot.TotalSales
go


-- 21. Podaj numery zamówień, ich datę oraz całkowitą wartość, 
	-- które były zrealizowane na największą wartość i na najmniejszą wartość(bez 0) w jednym zapytaniu.

select
	ot.OrderID
	, o.OrderDate
	,  ot.TotalSales
from (
	select
		od.OrderID
		, sum( od.UnitPrice * od.Quantity ) TotalSales
	from [Order Details] od
	group by od.OrderID
) ot
inner join Orders o
	on ot.OrderID = o.OrderID
order by ot.TotalSales desc
go


-- 22. Podaj numery zamówień, ich datę oraz całkowitą wartość, 
	-- które były zrealizowane na największą wartość i na najmniejszą wartość(bez 0) w jednym zapytaniu.
	-- zapytania typu CTE zaczynające się klauzulą WITH
	
with OrderTotals as (
	select
		od.OrderID
		, sum( od.UnitPrice * od.Quantity ) TotalSales
	from [Order Details] od
	group by od.OrderID
)
select
	ot.OrderID
	, o.OrderDate
	,  ot.TotalSales
from OrderTotals ot
inner join Orders o
	on ot.OrderID = o.OrderID
order by ot.TotalSales desc
go


-- 23. Podaj najdroższy i najtańszy z produktów (bez klauzuli TOP ani FETCH FIRST) (Podzapytania)

select
	p1.ProductName
	, p1.UnitPrice
from (
	select
		p.ProductName
		, p.UnitPrice
		, max( p.UnitPrice ) over ( order by p.UnitPrice desc ) MaxUnitPrice
		, min( p.UnitPrice ) over ( order by p.UnitPrice ) MinUnitPrice
	from Products p
) p1
where p1.UnitPrice = p1.MaxUnitPrice
	or p1.UnitPrice = p1.MinUnitPrice
go


-- 24. Podaj najdroższy i najtańszy z produktów (bez klauzuli TOP ani FETCH FIRST) (Podzapytania)
	-- Zapytanie typu CTE zaczynającą się na WITH

with ProductsWithMaxMin as (
	select
		p.ProductName
		, p.UnitPrice
		, max( p.UnitPrice ) over ( order by p.UnitPrice desc ) MaxUnitPrice
		, min( p.UnitPrice ) over ( order by p.UnitPrice ) MinUnitPrice
	from Products p
)
select
	p1.ProductName
	, p1.UnitPrice
from ProductsWithMaxMin p1
where p1.UnitPrice = p1.MaxUnitPrice
	or p1.UnitPrice = p1.MinUnitPrice
go


-- 25. Podaj numery zamówień, ich datę oraz całkowitą wartość, 
	-- które były zrealizowane na największą wartość i na najmniejszą wartość(bez 0) w jednym zapytaniu.
	-- wykonaj powyższe zapytanie bez klauzuli top tylko z wykorzystaniem podzapytań

select
	otr.OrderID
	, o.OrderDate
	,  otr.TotalSales
from (
	select
		ot.OrderID
		, ot.TotalSales
		, max( ot.TotalSales ) over ( order by ot.TotalSales desc ) MaxTotalSales
		, min( ot.TotalSales ) over ( order by ot.TotalSales ) MinTotalSales
	from (
		select
			od.OrderID
			, sum( od.UnitPrice * od.Quantity ) TotalSales
		from [Order Details] od
		group by od.OrderID
	) ot
) otr
inner join Orders o
	on otr.OrderID = o.OrderID
where otr.TotalSales = otr.MaxTotalSales
	or otr.TotalSales = otr.MinTotalSales
go


-- 26. Skasuj produkty należące do kategorii CATX (nie znamy categoryid tylko categoryname)
	-- (najpierw dodać kategorie CATX i później 2 produkty należące do tej kategorii)

insert into Categories (
	CategoryName
) values (
	'CATX'
)
declare @insertedCategory int = scope_identity()
insert into Products (
	ProductName
	, CategoryID
) values (
	'PRODX1'
	, @insertedCategory
)
, (
	'PRODX2'
	, @insertedCategory
)
go

with IdToDelete as (
	select CategoryID
	from Categories
	where CategoryName = 'CATX'
)
delete from Products
where CategoryID in ( select * from IdToDelete )

delete from Categories
where CategoryName = 'CATX'
go


-- 27. Jaka jest sprzedaż sumaryczna w roku 1996 i 1997 (bez group by)

select distinct
	year( o.OrderDate ) [Year]
	, sum( od.Quantity * od.UnitPrice ) over ( partition by year( o.OrderDate ) ) TotalSales
from [Order Details] od
inner join Orders o
	on od.OrderID = o.OrderID
where year( o.OrderDate ) in (
	1996
	, 1997
)
go


-- 28. Podaj nazwę klienta, rok sprzedaży oraz wartość sprzedaży w danym roku.

select
	c.CompanyName
	, year( o.OrderDate ) [Year]
	, sum( od.Quantity * od.UnitPrice ) TotalSales
from Customers c
left join Orders o
	on c.CustomerID = o.CustomerID
left join [Order Details] od
	on o.OrderID = od.OrderID
group by
	c.CompanyName
	, year( o.OrderDate )
order by
	c.CompanyName
	, year( o.OrderDate )
go


-- 29. W jaki dzień tygodnia sumaryczenie sprzedano towaru za największą kwotę.

select top 1
	datename( weekday, o.OrderDate ) DayOfTheWeek
	, sum( od.Quantity * od.UnitPrice ) TotalSales
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
group by
	datename( weekday, o.OrderDate )
go


-- 30. Podaj nazwę kategorii oraz rok w którym w danej kategorii była największa sprzedaż.

with SalesPerCategoryAnnually as (
	select
		ct.CategoryName
		, year( o.OrderDate ) [Year]
		, sum( od.Quantity * od.UnitPrice ) TotalSales
		, rank() over ( 
			partition by 
				ct.CategoryName
			order by sum( od.Quantity * od.UnitPrice ) desc
		) Ranking
	from Orders o
	left join [Order Details] od
		on o.OrderID = od.OrderID
	left join Products p
		on od.ProductID = p.ProductID
	full join Categories ct
		on p.CategoryID = ct.CategoryID
	group by
		ct.CategoryName
		, year( o.OrderDate )
)
select
	CategoryName
	, [Year]
	, TotalSales
from SalesPerCategoryAnnually
where Ranking = 1
go


-- 31. W którym roku była nawyższa sprzedaż.

select top 1
	year( o.OrderDate ) [Year]
	, sum( od.Quantity * od.UnitPrice ) TotalSales
from Orders o
left join [Order Details] od
	on o.OrderID = od.OrderID
group by
	year( o.OrderDate )
order by TotalSales desc
go


-- 32. który z pracowników obsłużył klientów za największą kwotę.

with EmployeeSalesRanking as (
	select
		e.EmployeeID
		, sum( od.Quantity * od.UnitPrice ) TotalSales
		, rank() over ( order by sum( od.Quantity * od.UnitPrice ) desc ) Ranking
	from Employees e
	left join Orders o
		on e.EmployeeID = o.EmployeeID
	left join [Order Details] od
		on o.OrderID = od.OrderID
	group by e.EmployeeID
)
select
	concat_ws(' ', e.FirstName, e.LastName) EmployeeName
	, esr.TotalSales
from EmployeeSalesRanking esr
inner join Employees e
	on esr.EmployeeID = e.EmployeeID
where esr.Ranking = 1
go


----------------
/* Sprzątanie */

delete from Products
where ProductID in (
	select * from #InsertedProducts
)
drop table if exists #InsertedProducts
go
