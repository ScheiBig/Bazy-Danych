use Northwind;

--------------------
--                --
--  NA ZAJĘCIACH  --
--                --
--------------------

-- jaki klient nie zrealizował zamówienia

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


-- z jakiej kat. nie mamy produktów

select
	c.CategoryName
from Categories c
left join Products p
	on c.CategoryID = p.CategoryID
where p.ProductID is null
;


-- jaki pracownik nie ma nad sobą szefa

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


-- jaka jest średnia cena produktów, cena min, maks, liczba różnych produktów

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


-- jakie produkty mają cenę większą od średniej ceny wszystkich produktów

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


-- jaka jest wartość produktów z danych kategorii

select
	c.CategoryName
	, sum( p.UnitPrice * p.UnitsInStock ) Products_Value
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
group by c.CategoryName
;
go


-- jaka jest średnia cena produktów, cena min, maks, liczba różnych produktów w danych kategoriach

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


-- jw. ale gdzie ilość różnych produktów > 5

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


-- jw. ale gdzie ilość danego produktu > 10

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


-- jakie zamówienia opiewają na jaką wartość

select
	od.OrderID
	, sum( od.UnitPrice * od.Quantity ) Order_Value
from [Order Details] od
group by od.OrderID
order by Order_Value
;
go


-- jakie zamówienie opiewa na najwyższą wartość

select top 1
	od.OrderID
	, sum( od.UnitPrice * od.Quantity ) Order_Value
from [Order Details] od
group by od.OrderID
order by Order_Value desc
;
go

-- znaleźć najtańszy i najdroższy produkt

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


-- jw. kto dostarczyć i do jakiej kategorii należy

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
-- łączenie tabel cd. --
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
-- czy wykonując zapytanie widzimy wprowadzone rekordy
/*
Nie, widzimy jedynie liczbę zmodyfikowanych / wstawionych rekordów
(każde polecienie insert wyświetla oddzielnie liczbę 
*/

select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
inner join Products p
 	on c.CategoryID = p.CategoryID
;

-- Podaj nazwę produktu, jego cenę i nazwę kategorii z tabel Products i Categories.
	-- chcemy także wyświetlić wszystkie nazwy kategorii nawet te przez przypisanych produktów 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
left join Products p   -- left outer join 
	on c.CategoryID = p.CategoryID
;

-- Podaj nazwę produktu, jego cenę i nazwę kategorii z tabel Products i Categories.
	-- chcemy także wyświetlić wszystkie produkty nawet bez przypisanej kategorii 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
right join Products p   --right outer join
	on c.CategoryID = p.CategoryID
;

-- Podaj nazwę produktu, jego cenę i nazwę kategorii z tabel Products i Categories.
	-- chcemy także wyświetlić wszystkie produkty i wszystkie kategorie 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
full outer join Products p  --full outer join
	on c.CategoryID = p.CategoryID
;


-- 1.Podaj nazwy kategorii, które nie mają przypisanych produktów.

select
	c.CategoryName
from Categories c
left join Products p
	on c.CategoryID = p.CategoryID
where p.ProductID is null
;
go


-- 2.Podaj nazwy produktów, które nie mają przypisanej kategorii (z wykorzystaniem JOIN'a) 

select
	p.ProductName
from Products p
left join Categories c
	on p.CategoryID = c.CategoryID
where c.CategoryID is null
;
go


-- 3.Podaj nazwy produktów, które nie mają przypisanej kategorii (bez wykorzystania JOIN'a) 

select
	p.ProductName
	, p.CategoryID
from Products p
where p.CategoryID is null
;
go


-- 4. Podaj nazwę produktu, jego cenę i nazwę kategorii z tabel Products i Categories.
	-- chcemy także wyświetlić wszystkie produkty i wszystkie kategorie 

select
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Products p
full outer join Categories c
	on p.CategoryID = c.CategoryID
;
go


-- 5. Z tabeli Employees podaj nazwisko pracownika i nazwisko jego szefa (wykorzystać pole ReportsTo) - zależności służbowe

select
	e1.LastName
	, e2.LastName as ManagerLastName
from Employees e1
inner join Employees e2
	on e1.ReportsTo = e2.EmployeeID
;
go


-- 6. Z tabeli Employees podaj nazwiska wszystkich pracowników i nazwisko ich szefa (wykorzystać pole ReportsTo) - zależności służbowe

select
	e1.LastName
	, e2.LastName as ManagerLastName
from Employees e1
left join Employees e2
	on e1.ReportsTo = e2.EmployeeID
;
go

-- 7. Podaj nazwiska pracowników, którzy nie mają szefa

select
	e1.LastName
from Employees e1
where ReportsTo is null
;
go

-- 8. Podaj nazwę klienta i nazwy produktów, które kupować (bez powtórzeń) 

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

	--dla konkretnego jednego klienta o nazwie 'Wolski  Zajazd' (zapytanie powinno zwrócić kilka rekordów)
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

-- 9. Podaj nazwę dostwacy(Suppliers) i nazwę spedytorów (Shippers), którzy dostarczają produkty danego dostwcy. Podaj także kraj pochodzenia dostwacy 

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

--10. Podaj numer zamówienia i nazwę towarów sprzedanych na kazdym z nich, w jakiej ilości i po jakiej cenie
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

--11. Podaj nazwisko pracowników, którzy nie są jednocześnie szefami dla innych pracowników.
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

--12. Znaleźć pracowników, którzy mają szefa jako samego siebie (dodaj pracownika, który ma szefa jako siebie samego) bez klauzli WHERE

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

-- kolejność join'ów typu outer w zapytaniu ma znaczenie przy zapytaniach ze sprzeżeniami zewnętrznymi, gdy jest więcej niż dwie tabele
-- (z poprzednich ćwiczeń mamy przynajmniej jedną kategorię i produkt nie powiązany ze sobą)
-- sprawdzić ilość zwracanych rekordów i dane które są zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Suppliers AS s INNER JOIN
	Products AS p ON s.SupplierID = p.SupplierID RIGHT JOIN
	Categories AS c ON p.CategoryID = c.CategoryID
-- sprawdzić ilość zwracanych rekordów i dane które są zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c LEFT JOIN
	Products AS p ON p.CategoryID = c.CategoryID INNER JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- sprawdzić ilość zwracanych rekordów i dane które są zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- każde z zapytań powinno zwrócić inną liczbę rekordów
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- można wykorzystać nawiasy do określenia kolejności złączeń (zapytanie j.w.)
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM (Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID) LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID

--13. Czy są kategorie w których produkty nie były ani razu sprzedane (lub produkty niesprzedane ale bez kategorii)

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
/* Nie ma takiej kategorii, ale są produkty niesprzedane bez kategorii */

-----------------------------------------------------------------
-- Operacje na zbiorach (union , union all, intersect, except) --
-----------------------------------------------------------------

--14. -- Dodaj trzy zestawy danych i posortuj względem nazwy. Kolumny wynikowe powinny się nazywać 'Name', 'Country', 'Type'
-- pierwszy zbiór - Zawiera nazwę dostawcy, kraj z którego pochodzi oraz informację w kolumnie trzeciej w postaci stringu 'Supplier'
-- drugi zbiór - Zawiera nazwę klienta, kraj z którego pochodzi oraz informację w kolumnie trzeciej w postaci stringu 'Customer' 
-- trzeci zbiór - Zawiera nazwisko pracownika, kraj z którego pochodzi oraz informację w kolumnie trzeciej w postaci stringu 'Employee' 

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

--15. Sprawdź czy są klienci, którzy są zarazem dostawcami (dodaj odpowiednie rekordy, które zwrócą wynik zapytania z danymi)

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

--17. Czy są dostawcy z krajów, w których nie ma klientów w danej bazie danych (podać tylko nazwę kraju)
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


--18. Czy są klienci z krajów, w których nie ma dostawców w danej bazie danych (podać tylko nazwę kraju)
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
--19. Znaleźć produkty wycofane ze sprzedaży.
select
	ProductName
from Products
where Discontinued = 1
;
go

--20. Znaleźć produkty, który osiągnęły minimalny stan magazynowy (wykorzystać składnię case), 
	-- =0 'brak produktu'
	-- >0 and <= 10 'produkt należy zamówic'
	-- >10 and <= 20 'kończy się produkt'
	-- >20 'OK'
select
	ProductName
	, case
		when UnitsInStock = 0
			then 'brak produktu'
		when 0 < UnitsInStock and UnitsInStock <= 10
			then 'produkt należy zamówić'
		when 10 < UnitsInStock and UnitsInStock <= 20
			then 'kończy się produkt'
		when 20 < UnitsInStock
			then 'OK'
	end as StockSatus
from Products
;
go

--21. Czy istnieją produkty, które są aktualnie sprzedawane, dla których stan magazynu + zamówiony towar < Poziomu minimalnego

select
	ProductName
from Products
where (UnitsInStock + UnitsOnOrder) < ReorderLevel
;
/* Tak, są 2 takie produkty */

--22. Czy towary wycofne ze sprzedaży znajdują się w magazynie
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
/* 4 produkty są wciąż w magazynie, 4 już nie */

--23. Podać nazwę pracownika i regiony, w których realizuje sprzedaż (podajemy oprócz nazwy regionu także numer regionu)

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

--24. Czy są produkty, których cena sprzedaży nie zmieniła się w trakcie funkcjonowania firmy

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
