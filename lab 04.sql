use Northwind;

--------------------
--                --
--  NA ZAJÊCIACH  --
--                --
--------------------

-- jaki klient nie zrealizowa³ zamówienia?

select
	c.CompanyName
from Customers c
left join Orders o
	on c.CustomerID = o.CustomerID
where o.OrderID is null
;
go
/* lub */
select
	c.CompanyName
from Customers c
where c.CustomerID not in (
	select distinct
		o.CustomerID
	from Orders o
);
go


-- z jakiej kat. nie mamy produktów?

select
	c.CategoryName
from Categories c
left join Products p
	on c.CategoryID = p.CategoryID
where p.ProductID is null
;


-- jaki pracownik nie ma nad sob¹ szefa?

select
	concat_ws( ' ', e1.FirstName, e1.LastName ) as [Name]
from Employees e1
left join Employees e2
	on e1.ReportsTo = e2.EmployeeID
where e2.EmployeeID is null
;
/* lub */
select
	concat_ws( ' ', e.FirstName, e.LastName ) as [Name]
from Employees e
where e.ReportsTo is null
;


-- jaka jest œrednia cena produktów, cena min, maks, liczba ró¿nych produktów

select
	avg( p.UnitPrice ) Mean_Average
	, min( p.UnitPrice ) Minimal_Value
	, max( p.UnitPrice ) Maximal_Value
	, count( p.UnitPrice ) Product_Count
	, sum( p.UnitPrice ) Sum_Of_Prices
	, sum( p.UnitPrice ) / count( p.UnitPrice ) Calculated_Avg1 
	, sum( p.UnitPrice ) / count( * ) Calculated_Avg2
from Products p
;
go


-- jakie produkty maj¹ cenê wiêksz¹ od œredniej ceny wszystkich produktów

select
	p.ProductName
	, p.UnitPrice
from Products p
where p.UnitPrice > (
	select
		avg( p.UnitPrice )
	from Products p
);
go


-- jaka jest wartoœæ produktów z danych kategorii

select
	c.CategoryName
	, sum( p.UnitPrice * p.UnitsInStock ) Products_Value
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
group by c.CategoryName
;
go


-- jaka jest œrednia cena produktów, cena min, maks, liczba ró¿nych produktów w danych kategoriach

select
	c.CategoryName
	, avg( p.UnitPrice ) Mean_Average
	, min( p.UnitPrice ) Minimal_Value
	, max( p.UnitPrice ) Maximal_Value
	, count( * ) Product_Count
	, sum( p.UnitPrice ) Sum_Of_Prices
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
group by CategoryName
;
go


-- jw. ale gdzie iloœæ ró¿nych produktów > 5

select
	c.CategoryName
	, avg( p.UnitPrice ) Mean_Average
	, min( p.UnitPrice ) Minimal_Value
	, max( p.UnitPrice ) Maximal_Value
	, count( * ) Product_Count
	, sum( p.UnitPrice ) Sum_Of_Prices
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
group by CategoryName
having count( * ) > 5
;
go


-- jw. ale gdzie iloœæ danego produktu > 10

select
	c.CategoryName
	, avg( p.UnitPrice ) Mean_Average
	, min( p.UnitPrice ) Minimal_Value
	, max( p.UnitPrice ) Maximal_Value
	, count( * ) Product_Count
	, sum( p.UnitPrice ) Sum_Of_Prices
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
where p.UnitsInStock > 10
group by CategoryName
having count( * ) > 5
;
go


-- jakie zamówienia opiewaj¹ na jak¹ wartoœæ

select
	od.OrderID
	, sum( od.UnitPrice * od.Quantity ) Order_Value
from [Order Details] od
group by od.OrderID
order by Order_Value
;
go


-- jakie zamówienie opiewa na najwy¿sz¹ wartoœæ

select top 1
	od.OrderID
	, sum( od.UnitPrice * od.Quantity ) Order_Value
from [Order Details] od
group by od.OrderID
order by Order_Value desc
;
go

-- znaleŸæ najtañszy i najdro¿szy produkt

select
	p.ProductName
	, p.UnitPrice
from Products p
inner join (
	select
		max( p.UnitPrice ) max_Price
		, min( p.UnitPrice ) min_Price
	from Products p
) pp
	on p.UnitPrice = pp.max_Price
		or p.UnitPrice = pp.min_Price
;
go


-- jw. kto dostarczy³ i do jakiej kategorii nale¿y

select
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
	, s.CompanyName
from Products p
inner join (
	select
		max( p.UnitPrice ) max_Price
		, min( p.UnitPrice ) min_Price
	from Products p
) pp
	on p.UnitPrice = pp.max_Price
		or p.UnitPrice = pp.min_Price
left join Categories c
	on p.CategoryID = c.CategoryID
left join Suppliers s
	on p.SupplierID = s.SupplierID
;
go

------------------
--              --
--  lab 04.sql  --
--              --
------------------

------------------------
-- £¹czenie tabel cd. --
------------------------

-- Wykonaj dwa polecenia
insert into Categories (
	CategoryName
) values (
	'A1'
);
insert into Products (
	ProductName
) values (
	'P1'
);
-- czy wykonuj¹c zapytanie widzimy wprowadzone rekordy ?
/*
Nie, widzimy jedynie liczbê zmodyfikowanych / wstawionych rekordów
(ka¿de polecienie insert wyœwietla oddzielnie liczbê 
*/

select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
inner join Products p
 	on c.CategoryID = p.CategoryID
;

-- Podaj nazwê produktu, jego cenê i nazwê kategorii z tabel Products i Categories.
	-- chcemy tak¿e wyœwietliæ wszystkie nazwy kategorii nawet te przez przypisanych produktów 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
left join Products p   -- left outer join 
	on c.CategoryID = p.CategoryID
;

-- Podaj nazwê produktu, jego cenê i nazwê kategorii z tabel Products i Categories.
	-- chcemy tak¿e wyœwietliæ wszystkie produkty nawet bez przypisanej kategorii 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
right join Products p   --right outer join
	on c.CategoryID = p.CategoryID
;

-- Podaj nazwê produktu, jego cenê i nazwê kategorii z tabel Products i Categories.
	-- chcemy tak¿e wyœwietliæ wszystkie produkty i wszystkie kategorie 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
full outer join Products p  --full outer join
	on c.CategoryID = p.CategoryID
;


-- 1.Podaj nazwy kategorii, które nie maj¹ przypisanych produktów.

select
	c.CategoryName
from Categories c
left join Products p
	on c.CategoryID = p.CategoryID
where p.ProductID is null
;
go


-- 2.Podaj nazwy produktów, które nie maj¹ przypisanej kategorii (z wykorzystaniem JOIN'a) 

select
	p.ProductName
from Products p
left join Categories c
	on p.CategoryID = c.CategoryID
where c.CategoryID is null
;
go


-- 3.Podaj nazwy produktów, które nie maj¹ przypisanej kategorii (bez wykorzystania JOIN'a) 

select
	p.ProductName
	, p.CategoryID
from Products p
where p.CategoryID is null
;
go


-- 4. Podaj nazwê produktu, jego cenê i nazwê kategorii z tabel Products i Categories.
	-- chcemy tak¿e wyœwietliæ wszystkie produkty i wszystkie kategorie 

select
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Products p
full outer join Categories c
	on p.CategoryID = c.CategoryID
;
go


-- 5. Z tabeli Employees podaj nazwisko pracownika i nazwisko jego szefa (wykorzystaæ pole ReportsTo) - zale¿noœci s³u¿bowe

select
	e1.LastName
	, e2.LastName as ManagerLastName
from Employees e1
inner join Employees e2
	on e1.ReportsTo = e2.EmployeeID
;
go


-- 6. Z tabeli Employees podaj nazwiska wszystkich pracowników i nazwisko ich szefa (wykorzystaæ pole ReportsTo) - zale¿noœci s³u¿bowe

select
	e1.LastName
	, e2.LastName as ManagerLastName
from Employees e1
left join Employees e2
	on e1.ReportsTo = e2.EmployeeID
;
go

-- 7. Podaj nazwiska pracowników, którzy nie maj¹ szefa

select
	e1.LastName
from Employees e1
where ReportsTo is null
;
go

-- 8. Podaj nazwê klienta i nazwy produktów, które kupowa³ (bez powtórzeñ) 

select distinct
	c.CompanyName
	, p.ProductName
from Customers c
inner join Orders o
	on c.CustomerID = o.CustomerID
inner join [Order Details] od
	on o.OrderID = od.OrderID
inner join Products p
	on od.ProductID = p.ProductID
;
go

	--dla konkretnego jednego klienta o nazwie 'Wolski  Zajazd' (zapytanie powinno zwróciæ kilka rekordów)
select distinct
	c.CompanyName
	, p.ProductName
from Customers c
inner join Orders o
	on c.CustomerID = o.CustomerID
inner join [Order Details] od
	on o.OrderID = od.OrderID
inner join Products p
	on od.ProductID = p.ProductID
where c.CompanyName = 'Wolski  Zajazd'
;
go

-- 9. Podaj nazwê dostwacy(Suppliers) i nazwê spedytorów (Shippers), którzy dostarczaj¹ produkty danego dostwcy. Podaj tak¿e kraj pochodzenia dostwacy 

select distinct
	s.CompanyName as SupplierName
	, s.Country as SupplierCountry
	, sh.CompanyName as ShipperName
from Suppliers s
left join Products p
	on s.SupplierID = p.SupplierID
left join [Order Details] od
	on p.ProductID = od.ProductID
left join Orders o
	on od.OrderID = o.OrderID
left join Shippers sh
	on o.ShipVia = sh.ShipperID
;
go

--10. Podaj numer zamówienia i nazwê towarów sprzedanych na kazdym z nich, w jakiej iloœci i po jakiej cenie
select
	o.OrderID
	, p.ProductName
	, od.Quantity
	, od.UnitPrice
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
inner join Products p
	on od.ProductID = p.ProductID
;
go

--11. Podaj nazwisko pracowników, którzy nie s¹ jednoczeœnie szefami dla innych pracowników.
select e1.LastName
from Employees e1
left join Employees e2
	on e1.EmployeeID = e2.ReportsTo
where e2.EmployeeID is null
;
go
/* albo z wykorzystaniem exists */
select e1.LastName
from Employees e1
where not exists (
	select 1
	from Employees e2
	where e2.ReportsTo = e1.EmployeeID
)
;
go

--12. ZnaleŸæ pracowników, którzy maj¹ szefa jako samego siebie (dodaj pracownika, który ma szefa jako siebie samego) bez klauzli WHERE

insert into Employees (
	LastName
	, FirstName
	, Title
	, TitleOfCourtesy
) values (
	'Cena'
	, 'John'
	, 'Boss of all bosses'
	, 'Their mayesty'
);
declare @last_id INT;
set @last_id = SCOPE_IDENTITY();
update Employees
set ReportsTo = @last_id
where EmployeeID = @last_id
;
select *
from Employees
where EmployeeID = @last_id
;
go

select
	e.*
from Employees e
inner join ( select null nothing ) n
	on e.EmployeeID = e.ReportsTo
;
go

-- kolejnoœæ join'ów typu outer w zapytaniu ma znaczenie przy zapytaniach ze sprze¿eniami zewnêtrznymi, gdy jest wiêcej ni¿ dwie tabele
-- (z poprzednich æwiczeñ mamy przynajmniej jedn¹ kategoriê i produkt nie powi¹zany ze sob¹)
-- sprawdziæ iloœæ zwracanych rekordów i dane które s¹ zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Suppliers AS s INNER JOIN
	Products AS p ON s.SupplierID = p.SupplierID RIGHT JOIN
	Categories AS c ON p.CategoryID = c.CategoryID
-- sprawdziæ iloœæ zwracanych rekordów i dane które s¹ zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c LEFT JOIN
	Products AS p ON p.CategoryID = c.CategoryID INNER JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- sprawdziæ iloœæ zwracanych rekordów i dane które s¹ zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- ka¿de z zapytañ powinno zwróciæ inn¹ liczbê rekordów
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- mo¿na wykorzystaæ nawiasy do okreœlenia kolejnoœci z³¹czeñ (zapytanie j.w.)
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM (Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID) LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID

--13. Czy s¹ kategorie w których produkty nie by³y ani razu sprzedane (lub produkty niesprzedane ale bez kategorii)

select
	p.ProductName
	, p.CategoryID
from Products p
left join [Order Details] od
	on p.ProductID = od.ProductID
where od.OrderID is null
;
go
/* albo z wykorzystaniem exists */
select
	p.ProductName
	, p.CategoryID
from Products p
where not exists (
	select 1
	from [Order Details] od
	where od.ProductID = p.ProductID
)
;
go
/* Nie ma takiej kategorii, ale s¹ produkty niesprzedane bez kategorii */

-----------------------------------------------------------------
-- Operacje na zbiorach (union , union all, intersect, except) --
-----------------------------------------------------------------

--14. -- Dodaj trzy zestawy danych i posortuj wzglêdem nazwy. Kolumny wynikowe powinny siê nazywaæ 'Name', 'Country', 'Type'
-- pierwszy zbiór - Zawiera nazwê dostawcy, kraj z którego pochodzi oraz informacjê w kolumnie trzeciej w postaci stringu 'Supplier'
-- drugi zbiór - Zawiera nazwê klienta, kraj z którego pochodzi oraz informacjê w kolumnie trzeciej w postaci stringu 'Customer' 
-- trzeci zbiór - Zawiera nazwisko pracownika, kraj z którego pochodzi oraz informacjê w kolumnie trzeciej w postaci stringu 'Employee' 

select
	s.CompanyName as [Name]
	, s.Country as Country
	, 'Supplier' as Type
from Suppliers s
union
select
	c.CompanyName
	, c.Country
	, 'Customer'
from Customers c
union
select
	concat_ws( ' ', e.FirstName, e.LastName )
	, e.Country
	, 'Supplier'
from Employees e
order by [Name]
;
go

--15. SprawdŸ czy s¹ klienci, którzy s¹ zarazem dostawcami (dodaj odpowiednie rekordy, które zwróc¹ wynik zapytania z danymi)

insert into Customers (
	CustomerID
	, CompanyName
	, ContactName
) values (
	421
	, 'Binley Mega Chippy'
	, 'Kamal Gandhi'
);
insert into Suppliers (
	CompanyName
	, ContactName
) values (
	'Binley Mega Chippy'
	, 'Kamal Gandhi'
);
go

select
	CompanyName
from Customers
intersect
select
	CompanyName
from Suppliers
;
go

--16. Podaj tylko nazwy krajów dostawców i klientów z powtórzeniami
select
	Country
from Customers
intersect
select
	Country
from Suppliers
where Country is not null
;
go

--17. Czy s¹ dostawcy z krajów, w których nie ma klientów w danej bazie danych (podaæ tylko nazwê kraju)
select
	Country
from Suppliers
except
select
	Country
from Customers
;
go
/* Tak, 4 takie kraje */


--18. Czy s¹ klienci z krajów, w których nie ma dostawców w danej bazie danych (podaæ tylko nazwê kraju)
select
	Country
from Customers
except
select
	Country
from Suppliers
;
go
/* Tak, 9 takich krajów */

-----------------------
-- Zadania dodatkowe --
----------------------- 
--19. ZnaleŸæ produkty wycofane ze sprzeda¿y.
select
	ProductName
from Products
where Discontinued = 1
;
go

--20. ZnaleŸæ produkty, który osi¹gnê³y minimalny stan magazynowy (wykorzystaæ sk³adniê case), 
	-- =0 'brak produktu'
	-- >0 and <= 10 'produkt nale¿y zamówic'
	-- >10 and <= 20 'koñczy siê produkt'
	-- >20 'OK'
select
	ProductName
	, case
		when UnitsInStock = 0
			then 'brak produktu'
		when 0 < UnitsInStock and UnitsInStock <= 10
			then 'produkt nale¿y zamówiæ'
		when 10 < UnitsInStock and UnitsInStock <= 20
			then 'koñczy siê produkt'
		when 20 < UnitsInStock
			then 'OK'
	end as StockSatus
from Products
;
go

--21. Czy istniej¹ produkty, które s¹ aktualnie sprzedawane, dla których stan magazynu + zamówiony towar < Poziomu minimalnego

select
	ProductName
from Products
where (UnitsInStock + UnitsOnOrder) < ReorderLevel
;
/* Tak, s¹ 2 takie produkty */

--22. Czy towary wycofne ze sprzeda¿y znajduj¹ siê w magazynie
select
	IsInStock
	, count( * )
from (
	select
		case UnitsInStock
			when 0 then 0
			else 1
		end as IsInStock
	from Products
	where Discontinued = 1
) a
group by IsInStock
;
go
/* 4 produkty s¹ wci¹¿ w magazynie, 4 ju¿ nie */

--23. Podaæ nazwê pracownika i regiony, w których realizuje sprzeda¿ (podajemy oprócz nazwy regionu tak¿e numer regionu)

select
	concat_ws(' ', e.FirstName, e.LastName ) as EmployeeName
	, r.RegionID
	, r.RegionDescription
from Employees e
left join EmployeeTerritories et
	on e.EmployeeID = et.EmployeeID
left join Territories t
	on et.TerritoryID = t.TerritoryID
left join Region r
	on t.RegionID = r.RegionID
;
go

--24. Czy s¹ produkty, których cena sprzeda¿y nie zmieni³a siê w trakcie funkcjonowania firmy

select
	p.ProductName
	, a.UnitPrice
from Products p
right join (
	select 
		ProductID
		, max( UnitPrice ) as UnitPrice
	from [Order Details] od
	group by ProductID
	having max( UnitPrice ) = min( UnitPrice )
) a
on p.ProductID = a.ProductID
;