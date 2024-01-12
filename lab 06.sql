----------------------------------------------------------------------------
-- Zapytania z podzapytaniami skorelowane i nieskorelowane, zapytania CTE --
----------------------------------------------------------------------------

use Northwind 
go

--1. Wyświetl najdroższe produkty w danej kategorii.

select
	c.CategoryName
	, p.ProductName
	, p.UnitPrice
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
where p.UnitPrice in (
	select max( p_i.UnitPrice )
	from Products p_i
	where p_i.CategoryID = p.CategoryID
)
go

/* lub */

with ProductPricing as (
	select
		p.ProductName
		, p.CategoryID
		, p.UnitPrice
		, rank() over (partition by p.CategoryID order by p.UnitPrice desc) PriceRank
	from Products p
)
select
	c.CategoryName
	, pp.ProductName
	, pp.UnitPrice
from ProductPricing pp
inner join Categories c
	on pp.CategoryID = c.CategoryID
	and pp.PriceRank = 1
go

--2. Znaleźć kategorię do której nie przypisano żadnego produktu
   --a. wykorzystując operator JOIN
   --b. zapytanie z podzapytaniem skorelowane --np. EXISTS lub NOT EXISTS
   --c. zapytanie z podzapytaniem nieskorelowane

begin transaction

insert into Categories (
	CategoryName
) values (
	'no product'
)

/* join */
select
	c.CategoryName
from Categories c
left join Products p
	on c.CategoryID = p.CategoryID
where p.ProductID is null

/* skorelowane */
select
	c.CategoryName
from Categories c
where not exists (
	select 1
	from Products p
	where p.CategoryID = c.CategoryID
)

/* nieskorelowane */
select
	c.CategoryName
from Categories c
where c.CategoryID not in (
	select p.CategoryID
	from Products p
)

rollback transaction
go

--3. Który z pracowników zrealizował największą liczbę zamówień, w każdym z lat funkcjonowania firmy.

with AnnualEmployeeSales as (
	select
		o.EmployeeID
		, year( o.OrderDate ) as OrderYear
		, count( * ) as OrderCount
		, rank() over (
			partition by year( o.OrderDate )
			order by count( * ) desc
		) as OrderCountRank
	from Orders o
	group by
		o.EmployeeID
		, year( o.OrderDate )
)
select
	concat_ws(' ', e.FirstName, e.LastName ) as EmployeeName
	, aes.OrderYear
	, aes.OrderCount
from 
	Employees e
	, AnnualEmployeeSales aes
where e.EmployeeID = aes.EmployeeID
	and aes.OrderCountRank = 1
go


--4. Który z pracowników zrealizował zamówienia sumarycznie za najwyższą kwotę w danym roku.

with OrderTotalsPerEmployee as (
	select
		o.EmployeeID
		, year( o.OrderDate ) as OrderYear
		, sum( od.Quantity * od.UnitPrice ) as OrderTotal
		, rank() over (
			partition by year( o.OrderDate )
			order by sum( od.Quantity * od.UnitPrice ) desc
		) as OrderTotalRank
	from 
		Orders o
		, [Order Details] od
	where o.OrderID = od.OrderID
	group by
		o.EmployeeID
		, year( o.OrderDate )
)
select
	concat_ws(' ', e.FirstName, e.LastName ) as EmployeeName
	, otpe.OrderYear
	, otpe.OrderTotal
from 
	Employees e
	, OrderTotalsPerEmployee otpe
where e.EmployeeID = otpe.EmployeeID
	and otpe.OrderTotalRank = 1
go


--5. Jaki klient kupił za największą kwotę sumarycznie, w każdym z lat funkcjonowania firmy.

with OrderTotalsPerCustomer as (
	select
		o.CustomerID
		, year( o.OrderDate ) as OrderYear
		, sum( od.Quantity * od.UnitPrice ) as OrderTotal
		, rank() over (
			partition by year( o.OrderDate )
			order by sum( od.Quantity * od.UnitPrice ) desc
		) as OrderTotalRank
	from 
		Orders o
		, [Order Details] od
	where o.OrderID = od.OrderID
	group by
		o.CustomerID
		, year( o.OrderDate )
)
select
	c.CompanyName
	, otpc.OrderYear
	, otpc.OrderTotal
from 
	Customers c
	, OrderTotalsPerCustomer otpc
where c.CustomerID = otpc.CustomerID
	and otpc.OrderTotalRank = 1
go


--6. Znajdź faktury każdego z klientów opiewające na najwyższe kwoty.

with OrderTotals as (
	select
		o.CustomerID
		, o.OrderID
		, sum( od.Quantity * od.UnitPrice ) as OrderTotal
		, rank() over (
			partition by o.CustomerID
			order by sum( od.Quantity * od.UnitPrice ) desc
		) as OrderTotalRank
	from 
		Orders o
		, [Order Details] od
	where o.OrderID = od.OrderID
	group by
		o.CustomerID
		, o.OrderID
)
select
	c.CompanyName
	, ot.OrderID
	, ot.OrderTotal
from 
	Customers c
	, OrderTotals ot
where c.CustomerID = ot.CustomerID
	and ot.OrderTotalRank = 1
go


--7. Podaj najlepiej sprzedające się produkty, w każdej kategorii.

with SalesPerCategory as (
	select 
		p.CategoryID
		, p.ProductName
		, sum( od.Quantity ) as TotalQuantity
		, rank() over (
			partition by p.CategoryID
			order by sum( od.Quantity ) desc
		) as TotalQuantityRank
	from
		[Order Details] od
		, Products p
	where od.ProductID = p.ProductID
	group by 
		p.CategoryID
		, p.ProductName
)
select
	c.CategoryName
	, spc.ProductName
	, spc.TotalQuantity
from 
	Categories c
	, SalesPerCategory spc
where c.CategoryID = spc.CategoryID
	and spc.TotalQuantityRank = 1
go


--8. Podaj jakiego towaru, każdego z dostawców jest w magazynie na najwyższą kwotę.

with StockValuePerSupplier as (
	select
		p.SupplierID
		, p.ProductName
		, sum( p.UnitsInStock * p.QuantityPerUnit ) as TotalStockValue
		, rank() over (
			partition by p.SupplierID
			order by sum( p.UnitsInStock * p.QuantityPerUnit ) desc
		) as TotalStockValueRank
	from Products p
	group by 
		p.SupplierID
		, p.ProductName
)
select
	s.CompanyName as SupplierCompanyName
	, svps.ProductName
	, svps.TotalStockValue
from
	Suppliers s
	, StockValuePerSupplier svps
where s.SupplierID = svps.SupplierID
	and svps.TotalStockValueRank = 1
go


--9. Podaj najlepiej sprzedający się produkt, w każdym z roku i kwartale funkcjonowania firmy.

with AnnualQuarterlySales as (
	select
		od.ProductID
		, year( o.OrderDate ) as OrderYear
		, datepart( quarter, o.OrderDate ) as OrderQuarter
		, sum( od.Quantity ) as TotalQuantity
		, rank() over (
			partition by
				year( o.OrderDate )
				, datepart( quarter, o.OrderDate )
			order by sum( od.Quantity ) desc
		) as TotalQuantityRank
	from 
		Orders o
		, [Order Details] od
	where o.OrderID = od.OrderID
	group by 
		year( o.OrderDate ) 
		, datepart( quarter, o.OrderDate )
		, od.ProductID
)
select
	p.ProductName
	, concat( aqs.OrderYear, ' Q', aqs.OrderQuarter ) as OrderQuarter
from 
	Products p
	, AnnualQuarterlySales aqs
where p.ProductID = aqs.ProductID
	and aqs.TotalQuantityRank = 1
go


--10. W jaki dzień tygodnia była największa i najmniejsza sprzedaż.

with TotalsPerWeekday as (
	select
		datename( weekday, o.OrderDate ) [DayOfWeek]
		, sum( od.Quantity * od.UnitPrice ) TotalPrice
	from
		Orders o
		, [Order Details] od
	where o.OrderID = od.OrderID
	group by datename( weekday, o.OrderDate )
)
, TotalsPerWeekdayStats as (
	select
		*
		, min( tpw.TotalPrice ) over ( order by tpw.TotalPrice ) MinTotalPrice
		, max( tpw.TotalPrice ) over ( order by tpw.TotalPrice rows between current row and unbounded following ) MaxTotalPrice
	from TotalsPerWeekday tpw
)
select
	tpws1.[DayOfWeek] MinimumDay
	, tpws1.TotalPrice MinimumValue
	, tpws2.[DayOfWeek] MaximumDay
	, tpws2.TotalPrice MaximumValue
from 
	TotalsPerWeekdayStats tpws1
	, TotalsPerWeekdayStats tpws2
where tpws1.TotalPrice = tpws1.MinTotalPrice
	and tpws2.TotalPrice = tpws2.MaxTotalPrice
go


--11. Tworzenie tabel na podstawie wyników polecenia: select * from products  (SELECT INTO)
   -- Dołóż do wcześniej utworzonej tabeli na podstawie zapytania jeszcze raz te same dane.

select
	ProductID
	, ProductName
	, SupplierID
	, CategoryID
	, QuantityPerUnit
	, UnitPrice
	, UnitsInStock
	, UnitsOnOrder
	, ReorderLevel
	, Discontinued
into Products2
from Products
go

insert into Products2
select 
	ProductName
	, SupplierID
	, CategoryID
	, QuantityPerUnit
	, UnitPrice
	, UnitsInStock
	, UnitsOnOrder
	, ReorderLevel
	, Discontinued
from Products2

select * from Products2

drop table Products2


--12. Skasuj produkty należące do kategorii CAT1 (najpierw dodać 2 produkty bez kategorii, następnie nową kategorię CAT1 i przypisać    
  --dodanym wcześniej produktom tą kategorię)

begin transaction

insert into Products (
	ProductName
) values (
	'Product1'
), (
	'Product2'
)

insert into Categories (
	CategoryName
) values (
	'Category1'
)

declare @cat1 int = scope_identity()

update Products
set CategoryID = @cat1
where ProductName like 'Product_'


   --a. wykorzystać zapytanie z podzapytaniem

delete from Products
where CategoryID in (
	select CategoryID
	from Categories
	where CategoryName = 'Category1'
)

   --b. oraz zapytanie typu JOIN - jeśli się da

delete Products
from Products p
join Categories c
	on p.CategoryID = c.CategoryID
where CategoryName = 'Category1'


--select * from Products
--select * from Categories

rollback transaction



--13. Zmodyfikuj cenę produktów o 20% dla produktów należących do kategorii o nazwie CAT1.

update Products
set UnitPrice = UnitPrice * 1.20
where CategoryID in (
	select CategoryID
	from Categories
	where CategoryName = 'Category1'
)
go


--14. Podaj w pierwszej kolumnie ROK, w następnych kolumnach miesiące od 1 do 12.
  --W kolejnych rekordach podajemy sprzedaż w danym roku w danym miesiącu. Wykorzystać funkcję COALESCE.

with Dates as (
	select
		*
	from (
		select 1996 [year]
		union select 1997
		union select 1998
	) y
	cross join (
		select 1 [month]
		union select 2
		union select 3
		union select 4
		union select 5
		union select 6
		union select 7
		union select 8
		union select 9
		union select 10
		union select 11
		union select 12
	) m
)
, TotalSalesPerMonth as (
	select
		year( o.OrderDate ) [year]
		, month( o.OrderDate) [month]
		, sum( od.Quantity * od.UnitPrice ) TotalSale
	from
		Orders o
		, [Order Details] od
	where o.OrderID = od.OrderID
	group by 
		year( o.OrderDate )
		, month( o.OrderDate)
)
select
	d.[year]
	, d.[month]
	, coalesce( cast( tspm.TotalSale as varchar ), '\\Nothing//' )
from Dates d
left join TotalSalesPerMonth tspm
	on d.[year] = tspm.[year]
	and d.[month] = tspm.[month]
order by
	d.[year]
	, d.[month]
go
	

--15. Wyświetl najdroższe dwa produkty w danej kategorii (podajemy nazwę kategorii, nazwę produktu i jego cenę)

with ProductPricing as (
	select
		p.ProductName
		, p.CategoryID
		, p.UnitPrice
		, rank() over (partition by p.CategoryID order by p.UnitPrice desc) PriceRank
	from Products p
)
select
	c.CategoryName
	, pp.ProductName
	, pp.UnitPrice
from ProductPricing pp
inner join Categories c
	on pp.CategoryID = c.CategoryID
	and pp.PriceRank <= 2
go


--16. Napisz kilka przykładowych zapytań wykorzystujących operator [ANY|SOME, ALL] na bazie Northwind. Zadaj pytania, na które odpowiadają dane przykłady.

-- Sprawdź (używając `ALL`) którzy pracownicy obsłużyli przynajmniej jedno zamówienie w każdym miesiącu funkcjonowania firmy

with EmployeesMonthsMatrix as (
	select
		d.[year]
		, d.[month]
		, e.EmployeeID
	from (
		select distinct
			year( o.OrderDate ) [year]
			, month( o.OrderDate ) [month]
		from Orders o
	) d
	cross join (
		select e.EmployeeID
		from Employees e
	) e
)
, EmployeesActiveMonths as (
	select
		emm.year
		, emm.month
		, emm.EmployeeID
		, case when ed.EmployeeID is null then 0 else 1 end IsActive
	from EmployeesMonthsMatrix emm
	left join (
		select distinct
			o.EmployeeID
			, year( o.OrderDate ) [year]
			, month( o.OrderDate ) [month]
		from Orders o
	) ed
		on emm.year = ed.year
		and emm.month = ed.month
		and emm.EmployeeID = ed.EmployeeID
)
select
	concat_ws(' ', e.FirstName, e.LastName ) EmployeeName
from Employees e
where 1 = all (
	select eam.IsActive
	from EmployeesActiveMonths eam
	where eam.EmployeeID = e.EmployeeID
)
go

-- Znajdź (używając `ANY`) klientów, którzy znajdują się w tym samym kraju, co któryś z pracowników

select
	c.CompanyName
	, c.Country
from Customers c
where c.Country = any ( select distinct e.Country from Employees e )
go

------------------------
-- funkcje rankongowe --
------------------------

--17. Ponumerować rekordy w tabeli PRODUCTS zgodnie z narastającą wartością kolumny productname-ROW_NUMBER().

select
	row_number() over ( order by p.ProductName ) n
	, p.*
from Products p
go


--18. Ponumerować rekordy w tabeli PRODUCTS malejąco po cenie produktu - ROW_NUMBER(), RANK(), DENSE_RANK().

select
	row_number() over ( order by p.UnitPrice desc ) n
	, rank() over ( order by p.UnitPrice desc ) r
	, dense_rank() over ( order by p.UnitPrice desc ) dr
	, p.*
from Products p
go


--19. Ponumerować rekordy rosnąco po numerze kategorii produktu i malejąco po cenie produktu.

select
	row_number() over (
		order by
			p.CategoryID
			, p.UnitPrice desc
	) n
	, p.*
from Products p
go


--20. Podaj nazwę kategorii, nazwę produktu oraz jego cenę oraz ranking wg. cen w danej kategorii (PARTITION BY)

select
	c.CategoryName
	, p.ProductName
	, p.UnitPrice
	, rank() over (
		partition by p.CategoryID
		order by p.UnitPrice
	) r
from
	Products p
	, Categories c
where p.CategoryID = c.CategoryID
go


--21. Podaj ranking sprzedaży, w każdej z kategorii.

with ProductSalesPerCategory as (
	select
		p.CategoryID
		, p.ProductName
		, sum( od.Quantity * od.UnitPrice ) as TotalSales
	from
		Products p
		, [Order Details] od
	where p.ProductID = od.ProductID
	group by 
		p.CategoryID
		, p.ProductName
)
select
	c.CategoryName
	, pspc.ProductName
	, pspc.TotalSales
	, rank() over (
		partition by pspc.CategoryID
		order by pspc.TotalSales desc
	) r
from 
	ProductSalesPerCategory pspc
	, Categories c
where pspc.CategoryID = c.CategoryID
go


--22. Podaj trzy kategorie, w których sprzedano produktów za najwyższą kwotę.

with SalesPerCategory as (
	select
		p.CategoryID
		, sum( od.Quantity * od.UnitPrice ) as TotalSales
		, rank() over ( order by sum( od.Quantity * od.UnitPrice ) desc ) r
	from
		Products p
		, [Order Details] od
	where p.ProductID = od.ProductID
	group by 
		p.CategoryID
)
select
	c.CategoryName
	, spc.TotalSales
	, spc.r
from 
	SalesPerCategory spc
	, Categories c
where spc.CategoryID = c.CategoryID
	and spc.r <= 3
go


--23. Podaj w danej kategorii 3 najlepiej sprzedawane produkty.

with ProductSalesPerCategory as (
	select
		p.CategoryID
		, p.ProductName
		, sum( od.Quantity * od.UnitPrice ) as TotalSales
		, rank() over (
			partition by p.CategoryID
			order by sum( od.Quantity * od.UnitPrice ) desc
		) r
	from
		Products p
		, [Order Details] od
	where p.ProductID = od.ProductID
	group by 
		p.CategoryID
		, p.ProductName
)
select
	c.CategoryName
	, pspc.ProductName
	, pspc.TotalSales
	, pspc.r
from 
	ProductSalesPerCategory pspc
	, Categories c
where pspc.CategoryID = c.CategoryID
	and pspc.r <= 3
go

-----------------------
-- Dodatkowe zadania - Instrukcje SQL--
-----------------------

--24. Zdefiniować słownie zapytanie i odpowiedź na nie w postaci zapytania z wykorzystaniem operatora PIVOT i UNPIVOT

--25. Zdefiniować słownie zapytanie i odpowiedź na nie w postaci zapytania z wykorzystaniem instrukcji MERGE 



-----------------------
---  DDL - tworzenie obiektów
-----------------------
--Zapoznać się z materiałem wykładowym dotyczącym możliwości definiowania baz dancych oraz obiektów w bazie w środowisku SQL --Serwer.
--Następnie:

--26. Założyć bazę danych o nazwie TestDB, w której wystąpi plik danych oraz plik dziennika transakcji.



/* Pobranie ścieżki w której ma się znajdować baza, kod skopiowany ze skryptu Northwind z Wikamp
	Ścieżkę pobieram do zmiennej, bo nie wiem jaką strukturę katalogów ma obraz Docker'a
*/

use master
go

declare @device_directory nvarchar(512)
select @device_directory = substring(filename, 1, charindex(N'master.mdf', lower(filename)) - 1)
from master.dbo.sysaltfiles 
where dbid = 1 
	and fileid = 1

/* Dynamiczna kwerenda, wymagana aby użyć ścieżki ze zmiennej */

declare @sql nvarchar(2048)
select @sql = concat(
	N'   create database TestDB '
--. Plik danych powinien mieć ustawione następujące atrybuty:
	, N' on primary ('
	, N' 	name= N''TestDB_dat'''
	, N' 	, filename= N''', @device_directory, N'lab06_testdb.mdf'''
	, N' 	, size= 5mb'
	, N' 	, maxsize= 10mb'
	, N' 	, filegrowth= 1mb'
	, N' )'
	, N' log on ('
	, N' 	name= N''TestDB_log'''
--- Plik dziennika powinien mieć ustawione atrybuty:
	, N' 	, filename= N''', @device_directory, N'lab06_testdb.ldf'''
	, N' 	, size= 5mb'
	, N' 	, maxsize= 10mb'
	, N' 	, filegrowth= 1mb'
	, N' )'
)

/* Wykonanie kwerendy tworzącej bazę danych */

exec( @sql )
go


-- 27. Zmodyfikować plik danych zwiększając jego rozmiar SIZE do 7MB

use master

/* Zmiana na 7MB może nie działać - na obrazie Docker'a
	po stworzeniu bazy danych plik bazy od razu rośnie do 8MB 
*/
alter database TestDB
modify file (
	name= TestDB_dat
	, size= 7mb
)
go


-- 28. Poleceniem SQL wyświetl listę wszystkich dostępnych opcji ustawień dla poszczególnych baz danych na danym serwerze SQL. --Następnie przeanalizuj dla danej wybranej bazy opcje konfiguracyjne.

select *
from sys.databases
where [name] = 'TestDB'
go


--Rozwiązanie:

select * from sys.databases

--29. W bazie TestDB założyć trzy tabele: STUDENCI, PRZEDMIOTY, ZALICZENIE. Zaproponować nazwy kolumn oraz typy danych tak, by możlowe było wprowadzanie do tych tabel nazwisk, imion studentów, nazw przedmiotów oraz ocen różnych zaliczeń danych studentów z przedmiotów. Dodatkowo proszę zarejestrowac kiedy takie zaliczenie się odbyło oraz jaką ocenę (przyjąć zakres ocen 2.0, 2.5, 3.0,3.5,4.0,4.5,5.0) dana osoba otrzymała. 

create table TestDB.dbo.Studenci (
	id_studenta int not null
	, imie nvarchar(32)
	, nazwisko nvarchar(64)

	, constraint PK_student primary key ( id_studenta )
)

create table TestDB.dbo.Przedmioty (
	id_przedmiotu int not null
	, nazwa_przedmiotu nvarchar(128)

	, constraint PK_przedmiot primary key ( id_przedmiotu )
)

create table TestDB.dbo.Zaliczenia (
	id_zaliczenia int not null
	, id_studenta int not null
	, id_przedmiotu int not null
	, data_zaliczenia datetime not null
	, ocena float not null
	
	, constraint PK_zaliczenie 
		primary key ( id_zaliczenia )
	, constraint FK_zaliczenie_student 
		foreign key ( id_studenta )
		references TestDB.dbo.Studenci
	, constraint FK_zaliczenie_przedmiot 
		foreign key ( id_przedmiotu )
		references TestDB.dbo.Przedmioty( id_przedmiotu )
	, constraint CK_ocena
		check ( ocena in ( 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0 ) )
)


/*  Sprzątanie  */ 

use master
drop database TestDB


