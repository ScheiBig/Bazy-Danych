use Northwind;

--------------------
--                --
--  NA ZAJ�CIACH  --
--                --
--------------------

-- jaki klient nie zrealizowa� zam�wienia?

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


-- z jakiej kat. nie mamy produkt�w?

select
	c.CategoryName
from Categories c
left join Products p
	on c.CategoryID = p.CategoryID
where p.ProductID is null
;


-- jaki pracownik nie ma nad sob� szefa?

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


-- jaka jest �rednia cena produkt�w, cena min, maks, liczba r�nych produkt�w

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


-- jakie produkty maj� cen� wi�ksz� od �redniej ceny wszystkich produkt�w

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


-- jaka jest warto�� produkt�w z danych kategorii

select
	c.CategoryName
	, sum( p.UnitPrice * p.UnitsInStock ) Products_Value
from Categories c
inner join Products p
	on c.CategoryID = p.CategoryID
group by c.CategoryName
;
go


-- jaka jest �rednia cena produkt�w, cena min, maks, liczba r�nych produkt�w w danych kategoriach

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


-- jw. ale gdzie ilo�� r�nych produkt�w > 5

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


-- jw. ale gdzie ilo�� danego produktu > 10

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


-- jakie zam�wienia opiewaj� na jak� warto��

select
	od.OrderID
	, sum( od.UnitPrice * od.Quantity ) Order_Value
from [Order Details] od
group by od.OrderID
order by Order_Value
;
go


-- jakie zam�wienie opiewa na najwy�sz� warto��

select top 1
	od.OrderID
	, sum( od.UnitPrice * od.Quantity ) Order_Value
from [Order Details] od
group by od.OrderID
order by Order_Value desc
;
go

-- znale�� najta�szy i najdro�szy produkt

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


-- jw. kto dostarczy� i do jakiej kategorii nale�y

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
-- ��czenie tabel cd. --
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
-- czy wykonuj�c zapytanie widzimy wprowadzone rekordy ?
/*
Nie, widzimy jedynie liczb� zmodyfikowanych / wstawionych rekord�w
(ka�de polecienie insert wy�wietla oddzielnie liczb� 
*/

select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
inner join Products p
 	on c.CategoryID = p.CategoryID
;

-- Podaj nazw� produktu, jego cen� i nazw� kategorii z tabel Products i Categories.
	-- chcemy tak�e wy�wietli� wszystkie nazwy kategorii nawet te przez przypisanych produkt�w 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
left join Products p   -- left outer join 
	on c.CategoryID = p.CategoryID
;

-- Podaj nazw� produktu, jego cen� i nazw� kategorii z tabel Products i Categories.
	-- chcemy tak�e wy�wietli� wszystkie produkty nawet bez przypisanej kategorii 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
right join Products p   --right outer join
	on c.CategoryID = p.CategoryID
;

-- Podaj nazw� produktu, jego cen� i nazw� kategorii z tabel Products i Categories.
	-- chcemy tak�e wy�wietli� wszystkie produkty i wszystkie kategorie 
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Categories c
full outer join Products p  --full outer join
	on c.CategoryID = p.CategoryID
;


-- 1.Podaj nazwy kategorii, kt�re nie maj� przypisanych produkt�w.

select
	c.CategoryName
from Categories c
left join Products p
	on c.CategoryID = p.CategoryID
where p.ProductID is null
;
go


-- 2.Podaj nazwy produkt�w, kt�re nie maj� przypisanej kategorii (z wykorzystaniem JOIN'a) 

select
	p.ProductName
from Products p
left join Categories c
	on p.CategoryID = c.CategoryID
where c.CategoryID is null
;
go


-- 3.Podaj nazwy produkt�w, kt�re nie maj� przypisanej kategorii (bez wykorzystania JOIN'a) 

select
	p.ProductName
	, p.CategoryID
from Products p
where p.CategoryID is null
;
go


-- 4. Podaj nazw� produktu, jego cen� i nazw� kategorii z tabel Products i Categories.
	-- chcemy tak�e wy�wietli� wszystkie produkty i wszystkie kategorie 

select
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Products p
full outer join Categories c
	on p.CategoryID = c.CategoryID
;
go


-- 5. Z tabeli Employees podaj nazwisko pracownika i nazwisko jego szefa (wykorzysta� pole ReportsTo) - zale�no�ci s�u�bowe

select
	e1.LastName
	, e2.LastName as ManagerLastName
from Employees e1
inner join Employees e2
	on e1.ReportsTo = e2.EmployeeID
;
go


-- 6. Z tabeli Employees podaj nazwiska wszystkich pracownik�w i nazwisko ich szefa (wykorzysta� pole ReportsTo) - zale�no�ci s�u�bowe

select
	e1.LastName
	, e2.LastName as ManagerLastName
from Employees e1
left join Employees e2
	on e1.ReportsTo = e2.EmployeeID
;
go

-- 7. Podaj nazwiska pracownik�w, kt�rzy nie maj� szefa

select
	e1.LastName
from Employees e1
where ReportsTo is null
;
go

-- 8. Podaj nazw� klienta i nazwy produkt�w, kt�re kupowa� (bez powt�rze�) 

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

	--dla konkretnego jednego klienta o nazwie 'Wolski  Zajazd' (zapytanie powinno zwr�ci� kilka rekord�w)
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

-- 9. Podaj nazw� dostwacy(Suppliers) i nazw� spedytor�w (Shippers), kt�rzy dostarczaj� produkty danego dostwcy. Podaj tak�e kraj pochodzenia dostwacy 

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

--10. Podaj numer zam�wienia i nazw� towar�w sprzedanych na kazdym z nich, w jakiej ilo�ci i po jakiej cenie
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

--11. Podaj nazwisko pracownik�w, kt�rzy nie s� jednocze�nie szefami dla innych pracownik�w.
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

--12. Znale�� pracownik�w, kt�rzy maj� szefa jako samego siebie (dodaj pracownika, kt�ry ma szefa jako siebie samego) bez klauzli WHERE

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

-- kolejno�� join'�w typu outer w zapytaniu ma znaczenie przy zapytaniach ze sprze�eniami zewn�trznymi, gdy jest wi�cej ni� dwie tabele
-- (z poprzednich �wicze� mamy przynajmniej jedn� kategori� i produkt nie powi�zany ze sob�)
-- sprawdzi� ilo�� zwracanych rekord�w i dane kt�re s� zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Suppliers AS s INNER JOIN
	Products AS p ON s.SupplierID = p.SupplierID RIGHT JOIN
	Categories AS c ON p.CategoryID = c.CategoryID
-- sprawdzi� ilo�� zwracanych rekord�w i dane kt�re s� zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c LEFT JOIN
	Products AS p ON p.CategoryID = c.CategoryID INNER JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- sprawdzi� ilo�� zwracanych rekord�w i dane kt�re s� zwracane
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- ka�de z zapyta� powinno zwr�ci� inn� liczb� rekord�w
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID
-- mo�na wykorzysta� nawiasy do okre�lenia kolejno�ci z��cze� (zapytanie j.w.)
SELECT c.CategoryName, p.ProductName, s.CompanyName
	FROM (Categories AS c FULL JOIN
	Products AS p ON p.CategoryID = c.CategoryID) LEFT JOIN
	Suppliers AS s ON s.SupplierID = p.SupplierID

--13. Czy s� kategorie w kt�rych produkty nie by�y ani razu sprzedane (lub produkty niesprzedane ale bez kategorii)

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
/* Nie ma takiej kategorii, ale s� produkty niesprzedane bez kategorii */

-----------------------------------------------------------------
-- Operacje na zbiorach (union , union all, intersect, except) --
-----------------------------------------------------------------

--14. -- Dodaj trzy zestawy danych i posortuj wzgl�dem nazwy. Kolumny wynikowe powinny si� nazywa� 'Name', 'Country', 'Type'
-- pierwszy zbi�r - Zawiera nazw� dostawcy, kraj z kt�rego pochodzi oraz informacj� w kolumnie trzeciej w postaci stringu 'Supplier'
-- drugi zbi�r - Zawiera nazw� klienta, kraj z kt�rego pochodzi oraz informacj� w kolumnie trzeciej w postaci stringu 'Customer' 
-- trzeci zbi�r - Zawiera nazwisko pracownika, kraj z kt�rego pochodzi oraz informacj� w kolumnie trzeciej w postaci stringu 'Employee' 

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

--15. Sprawd� czy s� klienci, kt�rzy s� zarazem dostawcami (dodaj odpowiednie rekordy, kt�re zwr�c� wynik zapytania z danymi)

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

--16. Podaj tylko nazwy kraj�w dostawc�w i klient�w z powt�rzeniami
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

--17. Czy s� dostawcy z kraj�w, w kt�rych nie ma klient�w w danej bazie danych (poda� tylko nazw� kraju)
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


--18. Czy s� klienci z kraj�w, w kt�rych nie ma dostawc�w w danej bazie danych (poda� tylko nazw� kraju)
select
	Country
from Customers
except
select
	Country
from Suppliers
;
go
/* Tak, 9 takich kraj�w */

-----------------------
-- Zadania dodatkowe --
----------------------- 
--19. Znale�� produkty wycofane ze sprzeda�y.
select
	ProductName
from Products
where Discontinued = 1
;
go

--20. Znale�� produkty, kt�ry osi�gn�y minimalny stan magazynowy (wykorzysta� sk�adni� case), 
	-- =0 'brak produktu'
	-- >0 and <= 10 'produkt nale�y zam�wic'
	-- >10 and <= 20 'ko�czy si� produkt'
	-- >20 'OK'
select
	ProductName
	, case
		when UnitsInStock = 0
			then 'brak produktu'
		when 0 < UnitsInStock and UnitsInStock <= 10
			then 'produkt nale�y zam�wi�'
		when 10 < UnitsInStock and UnitsInStock <= 20
			then 'ko�czy si� produkt'
		when 20 < UnitsInStock
			then 'OK'
	end as StockSatus
from Products
;
go

--21. Czy istniej� produkty, kt�re s� aktualnie sprzedawane, dla kt�rych stan magazynu + zam�wiony towar < Poziomu minimalnego

select
	ProductName
from Products
where (UnitsInStock + UnitsOnOrder) < ReorderLevel
;
/* Tak, s� 2 takie produkty */

--22. Czy towary wycofne ze sprzeda�y znajduj� si� w magazynie
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
/* 4 produkty s� wci�� w magazynie, 4 ju� nie */

--23. Poda� nazw� pracownika i regiony, w kt�rych realizuje sprzeda� (podajemy opr�cz nazwy regionu tak�e numer regionu)

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

--24. Czy s� produkty, kt�rych cena sprzeda�y nie zmieni�a si� w trakcie funkcjonowania firmy

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