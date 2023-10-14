-- 1. Ustawiamy bazę Northwind
use Northwind;
go

-- 2. Wybieramy wszystkie rekordy z tabeli Categories
select
	*
from Categories
; 
go

-- 3. Wybieramy wszystkie rekordy z tabeli Categories ustawiając wcześniej bazę master
use master
select
	*
from Northwind.dbo.Customers
; 
go

-- 4. Sposób zaptań na obiektach, których nazwa zawiera znaki specjalne (np. spacje)
use Northwind;
select
	*
from [Order Details]
; 
go

-- 5. Wybieramy z tabeli Categories tylko dwie kolumny: CategoryName, [Description]
select
	CategoryName
	, [Description]
from Categories
;
go

-- 6. Wybieramy z tabeli Products trzy kolumny kolumny: ProductName, cenę produktu * 1.23 (nowa nazwa kolumny to 'Cena z VAT'), 
-- wartość danego towaru w magazynie (nowa nazwa kolumny to 'Wartość')

select
	ProductName
	, ( UnitPrice * 1.23 ) as [Cena z VAT]
	, ( UnitsInStock * UnitPrice ) as [Wartość]
from Products
;
go

-- 7. W tabeli pracowników definiujemy 1 kolumnę postaci np. Sz.P. Piotr Nowak 
select
	concat_ws(' ', TitleOfCourtesy, FirstName, LastName ) as FullName
from Employees
;
go
-- Tu można zmienić FullName na not null, oraz dodać trigger który aktualizuje
-- wartość kolumny po wstawieniu nowego rekordu

-- 8. Z tabeli pracowników definiujemy 4 kolumny, gdzie podajemy: 
	-- TitleOfCourtesy FirstName LastName, 
	-- Address, 
	-- PostalCode City, 
	-- Country, 
	-- które można wykorzystac do adresowania kopert

select
	concat_ws( ' ', TitleOfCourtesy, FirstName, LastName )  as FullName
	, [Address]
	, concat_ws( ' ', PostalCode, City ) as PostalDistrict
	, Country
from Employees
;
go


-- 9. Sortowanie - Wybieramy z tabel Suppliers kolumny: nazwa_firmy, miasto, państwo a następnie sortujemy malejąco względem Country i rosnąco względem City 
select
	CompanyName
	, City
	, Country

from Suppliers
order by
	Country desc
	, City asc
;
go

--10. Sortowanie - Wybieramy z tabel Suppliers kolumny: nazwa_firmy, miasto, państwo a następnie sortujemy malejąco względem Country, malejąco względem City i rosnąco względem nazwy firmy
select
	CompanyName
	, City
	, Country

from Suppliers
order by
	Country desc
	, City desc
	, CompanyName asc
;
go

-- j.w. tylko używamy numery kolejne kolumn
select
	CompanyName
	, City
	, Country

from Suppliers
order by
	3 desc
	, 2 desc
	, 1 asc
;
go

-- j.w. tylko używamy numery kolejne kolumn oraz aliasy nazw kolumn
select
	CompanyName as [Company Name]
	, City
	, Country

from Suppliers
order by
	3 desc
	, 2 desc
	, [Company Name] asc
;
go


----------------------------------------------------------------------
-- Szukamy w dokumentacji SQL Server frazy: Select (Transact-SQL)
-- https://docs.microsoft.com/en-us/sql/t-sql/queries/select-transact-sql?view=sql-server-ver15
-- mamy dostępne klauzle ALL, DISTINCT, TOP

--11. Wybieramy nazwy wszystkich państw z tabeli Dostawców (Suppliers) i sortujemy względem nich -- klauzula ALL jest defaultowa
select all
	Country
from Suppliers
order by Country
;
go

--12. Wybieramy nazwy wszystkich państw bez powtórzeń z tabeli Dostawców (Suppliers) i sortujemy względem nich
select distinct
	Country
from Suppliers
order by Country
;
go

--13. Wybieramy trzy najdroższe produkty
select top (3)
	*
from Products
order by 
	UnitPrice desc
;
go

--14. Wybieramy 10% najdroższych produktów
select top (10) percent
	*
from Products
order by 
	UnitPrice desc
;
go

--15. Wybieramy 11 najdroższych produktów (sprawdzamy czy na pozycjach 12 i dalej jest taka sama wartość ceny produktu jak na pozycji 11). 
-- Jeśli tak to należy je wyświetlić.
select top (11) with ties
	*
from Products
order by 
	UnitPrice desc
;
go
	
--16. Wybieramy nazwę i cenę produktów od 11 do 15 rekordu posortowanych względem ceny malejąco
	-- wykorzystujemy składnię offset .. rows fetch first .. rows only (szukamy w dokumentacji polecenia ORDER BY)
select
	*
from Products
order by 
	UnitPrice desc
offset 11 rows
fetch next 5 rows only
;
go

--17. Wyświetlamy nazwę dostawcy i numer faksu ( nie wyświetlamy firm bez numeru faksu (wartość NULL))
select
	CompanyName
	, Fax
from Suppliers
where Fax is not null
;
go

--18. Wyświetlamy nazwę dostawcy i numer faksu ( wyświetlamy firm bez numeru faksu (wartość NULL))
select
	CompanyName
	, Fax
from Suppliers
where Fax is null
;
go

--19. Wyświetlamy nazwę dostawcy i numer faksu. Jeśli numeru faksu nie ma to powinna pojawić się nazwa 'Brak faksu'. 
	-- Korzystamy z funkcji ISNULL (sprawdzamy w dokumentacji)
select
	CompanyName
	, isnull(Fax, 'Brak faksu') as Fax
from Suppliers
;
go

--20. Wyświetlamy nazwę dostawcy, numer faksu, coutry i city, który znajduje się w 'USA' lub 'France' lub w mieście 'London'
select
	CompanyName
	, Fax
	, Country
	, City
from Suppliers
where Country in ( 'USA', 'France' )
	or City = 'London'
;
go

--21. Wyświetlamy nazwę dostawcy, numer faksu, coutry i city, który znajduje się w 'USA', 'France' lub 'Poland' (korzystamy z operatora logicznego IN)
select
	CompanyName
	, Fax
	, Country
	, City
from Suppliers
where Country in ( 'USA', 'France', 'Poland' )
;
go

--22. Wyświetlamy nazwę dostawcy, numer faksu, coutry i city, który nie znajduje się w 'USA', 'France' lub 'Poland' (korzystamy z operatora logicznego NOT IN)
select
	CompanyName
	, Fax
	, Country
	, City
from Suppliers
where Country not in ( 'USA', 'France', 'Poland' )
;
go

--23. Wyświetlamy produkty, których cena jest z zakresu od 50 do 100 łącznie z tymi punktami (korzystamy z operatora AND OR NOT >= <= > <)
select
	*
from Products
where 50 <= UnitPrice
	and UnitPrice <= 100
;
go

--24. Wyświetlamy produkty, których cena jest z zakresu do 50 i od 100 bez tych punktów (korzystamy z operatora AND OR NOT >= <= > <)
select
	*
from Products
where 50 < UnitPrice
	and UnitPrice < 100
;
go

--25. Wyświetlamy produkty, których cena jest z zakresu od 50 do 100 łącznie z tymi punktami (korzystamy z operatora BETWEEN AND)
select
	*
from Products
where UnitPrice between 50 and 100
;
go

--26. Wyświetlamy produkty, których cena jest z zakresu do 50 i od 100 bez tych punktów (korzystamy z operatora NOT BETWEEN AND)
select
	*
from Products
where UnitPrice not between 50 and 50
	and UnitPrice not between 100 and 100
	and UnitPrice between 50 and 100
;
go

--27. Wyświetlamy produkty, których cena jest z zakresu <20;80) bez punktów {30;40;50;60} - korzystamy tylko z operatorów BETWEEN AND, IN, NOT, AND, OR
	-- Negacja to operatory != <> NOT
select
	*
from Products
where UnitPrice between 20 and 80
	and UnitPrice not in ( 30, 40, 50, 60, 80 )
;
go

--28. Znaleźć produkty o nazwie z zakresu od litery a do litery c (stosujemy operator between i funkcję substring - sprawdzamy w dokumentacji)
select
	*
from Products
where substring( ProductName collate SQL_Latin1_General_CP1_CS_AS, 1, 1 ) between 'a' and 'c'
;
go

--29. Znaleźć produkty z zakresu od a do c (korzystamy z klauzuli LIKE - sprawdzamy w dokumentacji)
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '[a-c]%'
;
go

--30. Znaleźć produkty, które zaczynają się na literę a (korzystamy z klauzuli LIKE)
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like 'a%'
;
go

--31. Znaleźć produkty kończące sie na literę s (gdzie korzystamy klauzula LIKE)
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '%s'
;
go

--32. Znaleźć produkty, które w nazwie mają literę a,g,k na miejscu drugim (LIKE)
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '_[agk]%'
;
go

--33. Znaleźć produkty zaczynające się na literę 'A' (LIKE)
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like 'A%'
;
go

--34. Znaleźć produkty zaczynające się na litery od A do G (LIKE)
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '[A-G]%'
;
go

--35. Znaleźć produkty zaczynające się na litery A, C, G (LIKE)
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '[ACG]%'
;
go

--35. Znaleźć produkty, które zawierają ' (apostrof) (LIKE)
select
	*
from Products
where ProductName like '%''%'
;
go

--36. Znaleźć produkty kończące sie na słowo 'up' 
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '%up'
;
go

--37. Znaleźć produkty, które w nazwie na miejscu dwudziestym miejscu ma literę S, gdzie długość stringu jest >= 20 znaków (LEN)
select
	*
from Products
where len( ProductName ) >= 20 
	and substring( ProductName collate SQL_Latin1_General_CP1_CS_AS, 20, 1) = 'S'
;
go

--38. Znaleźć produkty zaczynające się na litery od A do S, których cena jest z zakres 15 do 120, które należą do kategorii 1,3,6. 
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '[A-S]%'
	and UnitPrice between 15 and 120
	and CategoryID in ( 1, 3, 6 )
;
go

--39. Znaleźć produkty, które w nazwie mają słowo New.
select
	*
from Products
where ProductName collate SQL_Latin1_General_CP1_CS_AS like '%New%'
;
go

--40. Łaczymy Imię, nazwisko i numer pracownika (Employees) w jeden string i wyświetlamy jedną kolumnę.

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


