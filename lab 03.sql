use Northwind;

--------------------
--                --
--  NA ZAJĘCIACH  --
--                --
--------------------

-- 1. podaj nazwę kategorii i produktu z tej kategorii
select
	c.CategoryName
	, p.ProductName
from Products p
inner join Categories c
	on p.CategoryID = c.CategoryID
;
go

-- 2. jaki dostawca dostarcza jakie produkty i w jakiej cenie
select
	s.CompanyName
	, p.ProductName
	, p.UnitPrice
from Products p
inner join Suppliers s
	on p.SupplierID = s.SupplierID
;
go

-- 3. podaj nazwę kategorii, nazwę dostawcy i nazwę produktu
select
	c.CategoryName
	, s.CompanyName
	, p.ProductName
from Products p
inner join Categories c
	on p.CategoryID = c.CategoryID
inner join Suppliers s
	on p.SupplierID = s.SupplierID
;
go

-- 4. jaki klient zrealizował jakie zamówienie obsłużone przez jakiego dostawcę
select
	c.CompanyName
	, sh.CompanyName
from Orders o
inner join Customers c
	on o.CustomerID = c.CustomerID
inner join Shippers sh
	on o.ShipVia = sh.ShipperID
;
go

-- 5. jaki klient zrealizował jakie zamówienie na którym są jakie produkty i w jakiej cenie
select
	c.CompanyName
	, o.OrderID
	, p.ProductName
	, p.UnitPrice
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
inner join Products p
	on od.ProductID = p.ProductID
inner join Customers c
	on o.CustomerID = c.CustomerID
;
go

-- 6. podaj czy jest taki dostawca który jest jednocześnie moim klientem
select
	c.CompanyName
from Customers c
inner join Shippers sh
	on c.CompanyName = sh.CompanyName
;
go

-- 7. podaj nazwę produktu oraz obok nazwę odpowiednika tego produktu w tej samej cenie jednostkowej
select
	p1.ProductName as [Product 1] 
	, p2.ProductName as [Product 2]
	, p1.UnitPrice
from Products p1
inner join Products p2
	on p1.UnitPrice = p2.UnitPrice
	and p1.ProductID < p2.ProductID
;
go

-- 8. podaj jaki pracownik przynależy do jakiego kierownika
select 
	( e1.FirstName + ' ' + e1.LastName ) as [Employee Name]
	, coalesce( e2.FirstName + ' ' + e2.LastName, '-- Nikt --' ) as [Manager Name]
from Employees e1
left join Employees e2
	on e1.ReportsTo = e2.EmployeeID
;


------------------
--              --
--  lab 03.sql  --
--              --
------------------

-- 1. Znaleźć produkty, które w nazwie na miejscu dwudziestym miejscu ma literę S, gdzie długość stringu jest >= 20 znaków (LEN)
select
	*
from Products
where len( ProductName ) >= 20 
	and substring( ProductName collate Latin1_General_100_BIN2, 20, 1) = 'S'
;
go

-- 2. Znaleźć produkty zaczynające się na litery od A do S, których cena jest z zakres 15 do 120, które należą do kategorii 1,3,6. 
select
	*
from Products
/* Latin1_General_100_BIN2 jest jedynym kodowaniem, które zachowuje kolejność znaków zgodnie z kodowaniem UTF, a nie "alfabetycznie" */
where ProductName collate Latin1_General_100_BIN2 like '[A-S]%'
	and UnitPrice between 15 and 120
	and CategoryID in ( 1, 3, 6 )
;
go

-- 3. Znaleźć produkty, które w nazwie mają słowo New.
select
	*
from Products
where ProductName collate Latin1_General_100_BIN2 like '%New%'
;
go

-- 4. Łaczymy Imię, nazwisko i numer pracownika (Employees) w jeden string i wyświetlamy jedną kolumnę.

	-- wykorzystujemy funkcję CAST (sprawdzamy w dokumentacji)
select
	( FirstName + ' ' + LastName + ' ' + cast( EmployeeID as nvarchar ) ) as Identifier
from Employees
;
go
	-- wykorzystujemy funkcję CONVERT (sprawdzamy w dokumentacji)
select
	( FirstName + ' ' + LastName + ' ' + convert( nvarchar, EmployeeID) ) as Identifier
from Employees
;
go
	-- wykorzystujemy funkcję CONCAT (sprawdzamy w dokumentacji)
select
	concat( FirstName, ' ', LastName, ' ', EmployeeID ) as Identifier
from Employees
;
go

--------------------------------------
-- Polecenia INSERT, UPDATE, DELETE --
--------------------------------------

-- Przygotowujemy dane (mogą by być z poprzednich zajęć)
select * from Categories; 
delete Products where ProductID>=78;
delete Categories where CategoryID >= 9;

--Wstawiamy nową kategorię o nazwie 'Kat 1' 
insert into Categories (CategoryName) values ('Kat 1')

--Wstawiamy dwie nowe kategorie o nazwie 'Kat 2' i 'Kat 3' jednym poleceniem 
insert  into Categories (CategoryName) values ('Kat 2'),('Kat 3');

--Wstawiamy nową kategorię o nazwie 'Kat 4' łącznie z polem Description 'Opis 4' 
insert into Categories (CategoryName, Description) values ('Kat 4','opis 4')

--Wstawiamy nową kategorię o nazwie 'Kat 5' łącznie z polem Description z wartością NULL
insert into Categories (CategoryName, Description) values ('Kat 5', NULL)

--Kasujemy rekord gdzie  CategoryName = 'Kat 5' i CategoryID >= 9
delete Categories where CategoryName = 'Kat 5' and CategoryID >= 9

--Modyfikujemy wszystkie kategorie zaczynające się na słowo 'Kat' i ustawiamy aby ich nowa nazwa była pisana dużymi literami oraz Description było wartością NULL
update Categories set CategoryName = UPPER(categoryname), Description = NULL
	 where CategoryName like 'Kat%';

-- 1. Zmodyfikuj kategorię aby była pisana małymi literami (klauzula WHERE zawiera konkretny numer kategorii)
update Categories 
set 
	CategoryName = lower( CategoryName )
where CategoryName like '[Kk][Aa][Tt] 1'
;
go

-- 2. Skasuj daną kategorię (klauzula WHERE zawiera konkretny numer kategorii)
delete Categories
where CategoryName = 'kat 4'
;
go

----------------
-- Transakcje --
----------------

----------------------------------------------------------------------------------------------------------------------------
-- Przykład 1 wycofanie transakcji (dla spradzenia działania wykonujemy każde polecenie po kolei)--
----------------------------------------------------------------------------------------------------------------------------
begin tran
	insert  into Categories (CategoryName) values ('Kat t1'),('Kat t2');
	-- Sprawdzamy czy faktycznnie operacja została wykonana czy wycofana
	select * from Categories where CategoryName like 'Kat%'
-- wycofujemy transkacje
rollback tran 
-- Sprawdzamy czy faktycznnie operacja została wykonana czy wycofana
select * from Categories where CategoryName like 'Kat%'
----------------------------------------------------------------------------------------------------------------------------
-- Przykład 2 zatwierdzenie transakcji (dla spradzenia działania wykonujemy każde polecenie po kolei)--
begin tran
	insert  into Categories (CategoryName) values ('Kat t1'),('Kat t2');
	-- Sprawdzamy czy faktycznnie operacja została wykonana czy wycofana
	select * from Categories where CategoryName like 'Kat%'
-- zatwierdzamy transkacje
commit tran 
-- Sprawdzamy czy faktycznnie operacja została wykonana czy wycofana
select * from Categories where CategoryName like 'Kat%'
----------------------------------------------------------------------------------------------------------------------------

-- 3.Sprawdzić i podać jaki jest ustawiony poziom izolacji transakcji i jak zmienić aktualny poziom
select 
	case  
		when transaction_isolation_level = 1 
			then 'READ UNCOMMITTED' 
		when transaction_isolation_level = 2 
		and is_read_committed_snapshot_on = 1 
			then 'READ COMMITTED SNAPSHOT' 
		when transaction_isolation_level = 2 
		and is_read_committed_snapshot_on = 0 
			then 'READ COMMITTED' 
		when transaction_isolation_level = 3 
			then 'REPEATABLE READ' 
		when transaction_isolation_level = 4 
			then 'SERIALIZABLE' 
		when transaction_isolation_level = 5 
			then 'SNAPSHOT' 
		else null
	end as TRANSACTION_ISOLATION_LEVEL 
from sys.dm_exec_sessions as s
cross join sys.databases as d
where session_id = @@SPID
	and d.database_id = DB_ID()
;
go

/* Zwraca jest wartość "READ COMMITED" */
/* Zmiana następuje poprzez zapytanie:
set transaction isolation level { ISOLATION_LEVEL };
*/

-- 4.Otworzyć dwa okna i zaobserwować w drugim okienku blokowanie czytanych danych przy nie zakończonej transakcji z pierwszego okienka na danej tabeli np. categories

select *
from Categories
;
go

/* 
Na pasku stanu wyświetla się animacja spinner wraz z etykietą 
"Executing query...", natomiast okno rezultatu pozostaje puste.

Status zmienia się na "✅ Query executed successfully." oraz dane wynikowe
pojawiają się dopiero po zamknięciu transakcji.
*/

-- 5. j.w. tylko w drugim okienku ustawić poziom izolacji transakcji jako 'set transaction isolation level read uncommitted' i czytamy dane z tabeli categories (jaka jest różnica?)

set transaction isolation level 
read uncommitted
;
select *
from Categories
;
go

/*
Wyniki zapytania wyświetlane są natychmiast, nawet jeśli w innym oknie otwarta
jest obecnie transakcja - wyniki zawierają zmiany wprowadzone już w otwartej 
transakcji.
*/

-- 6.Dodać nową kategorię o nazwie 'Kategoria 1' a następnie dodać produkt o nazwie 'Produkt 1' należący do kategorii 'Kategoria 1' 
	-- (nie znamy categoryid danej kategorii)(pamiętajmy iż niektóre pola są wymagane do wstawienia rekordu)

insert into Categories 
	(CategoryName)
values
	('Kategoria 1')
;
insert into Products
	(
		ProductName
		, CategoryID
		, Discontinued
	)
select
	'Produkt 1'
	, CategoryID
	, 0
from Categories
where CategoryName = 'Kategoria 1'
;
go

select *
from Products
where ProductName = 'Produkt 1'
;
go

-- 7.Dodać produkt 'Produkt 2' do kategorii o numerze 2000 
	-- (jak wynik zapytania podać wygenerowany błąd i poniżej odpowiedzieć na pytanie dlaczego ten błąd wystąpił i co maiało na to wpływ)

insert into Products
	(
		ProductName
		, CategoryID
		, Discontinued
	)
select
	'Produkt 2'
	, 2000
	, 0
;
go

/* 
Błąd:
	The INSERT statement conflicted with the FOREIGN KEY constraint 
	"FK_Products_Categories". The conflict occurred in database "Northwind",
	table "dbo.Categories", column 'CategoryID'.
*/
/*
Błąd spowodowany jest przez wiązanie integralności ustawione na tabeli Products,
które definiuje kolumnę CategoryID jako klucz obcy na pole Categories.CategoryID
- sprawia ono, że nie można do tabeli Products wstawić rekordu, w którym 
CategoryID nie jest istniejącą wartośćią ów kolumny w tabeli Categories - a wartość 
Categories.CategoryID = 2000 nie istnieje na moment wywoływania zapytania.
*/

delete from Products
where ProductName = 'Produkt 1'
;
delete from Categories
where CategoryName = 'Kategoria 1'
;
go

--------------------
-- Łączenie tabel --
--------------------

-- Podaj nazwę produktu, jego cenę, numer kategorii i nazwę kategorii z tabel Products i Categories (wykorzystujemy klauzulę WHERE)
select 
	p.ProductName
	, p.UnitPrice
	, p.CategoryID
	, c.CategoryName
from Categories c, Products p
where c.CategoryID = p.CategoryID
;
go

/*
Domyślnie, podanie wielu tabel w klauzuli from jest adekwatne dla CROSS JOIN.

Podanie dodatkowego warunku w klauzuli WHERE, sprawdzającego równość kluczy, 
jest już adekwatne dla połączenia INNER JOIN.
*/

-- 8.Podaj nazwę produktu, jego cenę, numer kategorii i nazwę kategorii z tabel Products i Categories (wykorzystujemy klauzulę WHERE)
	-- dla produktów z categoryid >= 8

select 
	p.ProductName
	, p.UnitPrice
	, p.CategoryID
	, c.CategoryName
from Categories c, Products p
where c.CategoryID = p.CategoryID
	and c.CategoryID >= 8
;
go

-- Podaj nazwę produktu, jego cenę i nazwę kategorii z tabel Products i Categories (wykorzystujemy klauzulę JOIN ... ON)
	-- dla produktów z categoryid >= 8 oraz posortować malejąco po cenie
select 
	p.ProductName
	, p.UnitPrice
	, c.CategoryName
from Products p
inner join Categories c
	on p.CategoryID = c.CategoryID
where c.CategoryID >= 8
order by UnitPrice desc
;
go

-- 9.Podaj nazwę produktu, jego cenę i nazwę firmy dostawcy (wykorzystujemy klauzulę INNER JOIN ... ON)

select 
	ProductName
	, UnitPrice
	, CompanyName as SupplierName
from Products p
inner join Suppliers s
	on p.SupplierID = s.SupplierID
;
go

-- 10.Podaj nazwę produktu, jego cenę i nazwę dostawcy z tabel Products i Suppliers (wykorzystujemy klauzulę INNER JOIN ... ON)
	-- dla produktów z categoryid >= 8 oraz posortować malejąco po cenie

select 
	p.ProductName
	, p.UnitPrice
	, s.CompanyName as SupplierName
from Products p
inner join Suppliers s
	on p.SupplierID = s.SupplierID
where p.CategoryID >= 8
order by p.UnitPrice desc
;
go

-- 11.Podaj nazwę produktu, jego cenę, nazwę firmy dostawcy i nazwę kategorii do której należy.

select 
	p.ProductName
	, p.UnitPrice
	, s.CompanyName as SupplierName
	, c.CategoryName
from Products p
inner join Suppliers s
	on p.SupplierID = s.SupplierID
inner join Categories c
	on p.CategoryID = c.CategoryID
;
go

-- 12.Dana firma w jakiej kategorii dostarcza produkty (posortować po nazwie firmy i nazwie kategorii)
select distinct
	s.CompanyName as SupplierName
	, c.CategoryName
from Products p
inner join Suppliers s
	on p.SupplierID = s.SupplierID
inner join Categories c
	on p.CategoryID = c.CategoryID
order by 
	SupplierName
	, c.CategoryName
;

-- 13.Podaj nazwę klienta, datę zamówienia i nazwę pracownika, który go obsługiwał.
select
	c.ContactName as CustomerName
	, o.OrderDate
	, e.FirstName + ' ' + e.LastName as EmployeName
from Orders o
inner join Customers c
	on o.CustomerID = c.CustomerID
inner join Employees e
	on o.EmployeeID = e.EmployeeID
;
go

-- 14.Podaj nazwę klienta i nazwy kategorii, w których klient kupował produkty (bez powtórzeń)
select distinct
	c1.ContactName as CustomerName
	, c2.CategoryName
from Orders o
inner join Customers c1
	on o.CustomerID = c1.CustomerID
inner join [Order Details] od
	on o.OrderID = od.OrderID
inner join Products p
	on od.ProductID = p.ProductID
inner join Categories c2
	on p.CategoryID = c2.CategoryID
;
go

-- 15.Podaj numer zamówienia, nazwę produktu i jego cenę na zamówieniu oraz upust.
select
	o.OrderID
	, p.ProductName
	, od.UnitPrice as [Order Price]
	, concat(od.Discount * 100, '%') as Discount
from Orders o
inner join [Order Details] od
	on o.OrderID = od.OrderID
inner join Products p
	on od.ProductID = p.ProductID
;
go

----------------------------------------------------------------------------------------------------------------------------
-- Aby nie pisać zapytania za każdym razem kiedy chcemy go wykonać to możemy utworzyć widok na podstawie danego zapytania --
----------------------------------------------------------------------------------------------------------------------------
create view v_Prod_Supp(name,price,c_name) 
as
select 
	ProductName
	, UnitPrice
	, CompanyName
from Products
inner join Suppliers
	on Products.SupplierID = Suppliers.SupplierID
	-- where categories.CategoryID >= 8 /* <- Tabela Categories nie jest częścią źródła danych - błąd skłądni
;
go
----------------------------------------------------------------------------------------------------------------------------

-- 16.Podaj wynik na podstawie widoku (nie tabel), gdzie kolumna price ma być >=100 i posortować względem kolumny name.

select *
from v_Prod_Supp
where price >= 100
order by name
;

-- Skasuj dany widok
drop view v_Prod_Supp;
go
