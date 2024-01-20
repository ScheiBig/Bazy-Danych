-----------------------------
-- Procedury przechowywane -- 
-----------------------------
USE NORTHWIND
GO
	IF EXISTS (SELECT * FROM sysobjects WHERE name = N'sample_procedure' AND type = 'P') DROP PROCEDURE sample_procedure
	GO
--lub w nowszych wersjach SQL Server
DROP PROCEDURE IF EXISTS dbo.sample_procedure;
GO
CREATE PROCEDURE sample_procedure 
	@p1 int = 0, 
	@p2 int = 0
AS
	SELECT @p1, @p2
GO
-- Przykład wykonania procedury przechowywanej -- 
EXECUTE sample_procedure 1, 2
GO

EXECUTE sample_procedure
go

---------------------------------------------------------------
-- Definicja procedury składowanej z parametrami typu OUTPUT --
---------------------------------------------------------------
DROP PROCEDURE IF EXISTS dbo.your_procedure_name
GO

CREATE PROCEDURE your_procedure_name 
	@p1 int = 0, 
	@p2 int  OUTPUT
AS
	SELECT @p2 = @p1
GO

-- Przykład wykonania procedury przechowywanej -- 
DECLARE @p2_output int 
EXECUTE your_procedure_name 1, @p2_output OUTPUT
SELECT @p2_output
GO

------------------------------------------------------
-- Procedury przechwowywane (składowane) - przykład --
------------------------------------------------------
DROP PROC IF EXISTS dbo.GetCustomerOrders;
GO

CREATE PROC dbo.GetCustomerOrders
  @custid   AS nvarchar(5),
  @fromdate AS DATETIME = '19000101',
  @todate   AS DATETIME = '99991231',
  @numrows  AS INT OUTPUT
AS
SET NOCOUNT ON;

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE CustomerID = @custid
  AND OrderDate >= @fromdate
  AND Orderdate < @todate;

SET @numrows = @@rowcount;
GO

DECLARE @rc AS INT;

EXEC dbo.GetCustomerOrders
  @custid   = 'VINET', -- Also try with 100
  @fromdate = '19970101',
  @todate   = '19980101',
  @numrows  = @rc OUTPUT;

SELECT @rc AS numrows;
GO



-------------
-- FUNCKJE --
-------------

------------------------------
-- Tworzenie funkcji INLINE --
------------------------------
IF EXISTS (SELECT * FROM   sysobjects WHERE  name = N'test_function')
	DROP FUNCTION test_function
GO

CREATE FUNCTION test_function 
	(@p1 int, 
	 @p2 char)
RETURNS TABLE 
AS
	RETURN SELECT @p1 AS c1, @p2 AS c2
GO

--------------------------------
-- Przykład wywołania funkcji --
--------------------------------
SELECT * 
FROM dbo.test_function (1, 'a')
GO

---------------------------------
-- Tworzenie funkcji skalarnej --
---------------------------------
IF EXISTS (SELECT * FROM sysobjects WHERE  name = N'test_function')
	DROP FUNCTION test_function
GO

CREATE FUNCTION test_function 
	(@p1 int, 
	 @p2 int)
RETURNS int
AS
BEGIN
	RETURN @p1 + @p2
--	lub
--	DECLARE @sum AS int
--	SELECT @sum = @p1 + @P2
--	RETURN @sum
END
GO

--------------------------------
-- Przykład wywołania funkcji --
--------------------------------
SELECT dbo.test_function (1, 2)
GO

-------------------------------------
-- Tworzenie funkcji tabelarycznej --
-------------------------------------
IF EXISTS (SELECT * FROM   sysobjects WHERE  name = N'test_function')
	DROP FUNCTION test_function
GO

CREATE FUNCTION test_function 
	(@p1 int, 
	 @p2 int)
RETURNS @table_var TABLE 
	(c1 int, 
	 c2 int)
AS
BEGIN
	INSERT @table_var SELECT @p1, @p2
	INSERT @table_var SELECT @p1*@p1, @p2*@p2
	INSERT @table_var SELECT @p1*@p2, @p1*@p2
	RETURN 
END
GO
--------------------------------
-- Przykład wywołania funkcji --
--------------------------------
SELECT * FROM dbo.test_function (4, 7)
GO

---------------------------------------------------------------------
-- Funkcje definiowane przez użytkownika
---------------------------------------------------------------------

DROP FUNCTION IF EXISTS dbo.GetAge;
GO

CREATE FUNCTION dbo.GetAge
(
  @birthdate AS DATE,
  @eventdate AS DATE
)
RETURNS INT
AS
BEGIN
  RETURN
    DATEDIFF(year, @birthdate, @eventdate)
    - CASE WHEN 100 * MONTH(@eventdate) + DAY(@eventdate)
              < 100 * MONTH(@birthdate) + DAY(@birthdate)
           THEN 1 ELSE 0
      END;
END;
GO

-- Test funkcji
SELECT
  EmployeeID, firstname, lastname, birthdate,
  dbo.GetAge(birthdate, '20200212') AS age
FROM dbo.Employees;

---------------------------------------------------------------------
-- Funkcje definiowane przez użytkownika
---------------------------------------------------------------------

DROP FUNCTION IF EXISTS dbo.GetAge;
GO

CREATE FUNCTION dbo.GetAge
(
  @birthdate AS DATE,
  @eventdate AS DATE
)
RETURNS INT
AS
BEGIN
  RETURN
    DATEDIFF(year, @birthdate, @eventdate)
    - CASE WHEN 100 * MONTH(@eventdate) + DAY(@eventdate)
              < 100 * MONTH(@birthdate) + DAY(@birthdate)
           THEN 1 ELSE 0
      END;
END;
GO

-- Test funkcji
SELECT
  EmployeeID, FirstName, Lastname, Birthdate,
  dbo.GetAge(birthdate, '20200212') AS age
FROM dbo.Employees;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

----------------------------------------------
-- Obsługa błędu z wykorzytsaniem procedury --
-- Opakowywanie kodu do ponownego użycia    --
----------------------------------------------
DROP PROC IF EXISTS dbo.ErrInsertHandler;
GO

CREATE PROC dbo.ErrInsertHandler
AS
SET NOCOUNT ON;

IF ERROR_NUMBER() = 2627
  BEGIN
    PRINT '    Obsługa naruszenia PK...';
  END
  ELSE IF ERROR_NUMBER() = 547
  BEGIN
    PRINT '    Obsługa naruszenia ograniczenia CHECK/FK...';
  END
  ELSE IF ERROR_NUMBER() = 515
  BEGIN
    PRINT '    Obsługa nieprawidłowej wartości NULL...';
  END
  ELSE IF ERROR_NUMBER() = 245
  BEGIN
    PRINT '    Obsługa błędu konwersji...';
  END
  ELSE
  BEGIN
    PRINT 'Obsługa nieznanego błędu...';
    THROW 420000, 'Unknown', 1; -- tylko system SQL Server 2012 
  END

  PRINT '    Numer błędu    : ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
  PRINT '    Komunikat błędu: ' + ERROR_MESSAGE();
  PRINT '    Ważność błędu  : ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
  PRINT '    Stan błędu      : ' + CAST(ERROR_STATE() AS VARCHAR(10));
  PRINT '    Wiersz błędu    : ' + CAST(ERROR_LINE() AS VARCHAR(10));
  PRINT '    Procedura błędu  : ' + COALESCE(ERROR_PROCEDURE(), 'Not within proc');
GO

-- Wywołanie procedury w bloku CATCH
BEGIN TRY

  INSERT INTO dbo.Employees(
  --EmployeeID,
  LastName, ReportsTo)
    VALUES(
	--1,
	'Emp1', NULL);

END TRY
BEGIN CATCH

  IF ERROR_NUMBER() IN (2627, 547, 515, 245)
    EXEC dbo.ErrInsertHandler;
  ELSE
    THROW;
  
END CATCH;


-------------------------------------------------------------------------
-- Wykorzystanie kursora bez definiowania procedury zwracającej kursor --
-- oraz to samo z wkorzystaniem procedury                              --
-------------------------------------------------------------------------
USE Northwind;  
GO  
-- blok Transact-SQL bez procedury
-- deklarujemy zmienne, aby zapisać wartości zwrócone przez FETCH.  
DECLARE @LastName varchar(50), @FirstName varchar(50);  
  
DECLARE contact_cursor CURSOR FOR  
SELECT LastName, FirstName FROM dbo.Employees  
WHERE LastName LIKE '[B-F]%'  
ORDER BY LastName, FirstName;  
  
OPEN contact_cursor;  
  
-- Wykonaj pierwsze pobranie i zapisz wartości w zmiennych.
-- Uwaga: Zmienne są w tej samej kolejności, co kolumny w instrukcji SELECT.  
FETCH NEXT FROM contact_cursor INTO @LastName, @FirstName;  
  
-- Sprawdzamy @@FETCH_STATUS czy są jeszcze wiersze do pobrania  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   PRINT 'Contact Name: ' + @FirstName + ' ' +  @LastName  
   -- Jest to wykonywane, dopóki poprzednie pobranie rekordu powiedzie się  
   FETCH NEXT FROM contact_cursor INTO @LastName, @FirstName;  
END  
  
CLOSE contact_cursor;  
DEALLOCATE contact_cursor;  
GO

----------------------------------------------------------------------------
-- Tworzenie procedury przechowywanej z parametrem wyjściowym typu CURSOR --
----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS dbo.sample_procedure
GO
-- Definicja procedury przechowywanej z parametrem wyjściowym typu CURSOR 
CREATE PROCEDURE sample_procedure 
	@sample_procedure_cursor CURSOR VARYING OUTPUT
AS
   SET @sample_procedure_cursor = CURSOR FOR
		SELECT LastName, FirstName FROM dbo.Employees  
		WHERE LastName LIKE '[B-F]%'  
		ORDER BY LastName, FirstName;  
   OPEN @sample_procedure_cursor
GO

-------------------------------------------------
-- blok Transact-SQL z procedurą przechowywaną --
-------------------------------------------------
-- Deklarujemy zmienne, aby zapisać wartości zwrócone przez FETCH.  
DECLARE @LastName varchar(50), @FirstName varchar(50),
		@test_cursor_variable CURSOR

EXEC sample_procedure @sample_procedure_cursor = @test_cursor_variable OUTPUT;  
  
-- Wykonaj pierwsze pobranie i zapisz wartości w zmiennych.
-- Uwaga: Zmienne są w tej samej kolejności, co kolumny w instrukcji SELECT.  
  
FETCH NEXT FROM @test_cursor_variable  INTO @LastName, @FirstName;  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   PRINT 'Contact Name: ' + @FirstName + ' ' +  @LastName;  
   FETCH NEXT FROM @test_cursor_variable INTO @LastName, @FirstName;  
END;  
CLOSE @test_cursor_variable;
DEALLOCATE @test_cursor_variable; 
GO
--------------------------------------------------------------------------------------------
-- Zadania --

------PROCEDURE


-- 1. Zdefiniuj procedurę, która wyświetli na ekranie imię, nazwisko oraz państwo pochodzenia (Country) o identyfikatorze podanym jako pierwszy parametr. Jeżeli nie ma takiego id to zwrócony zostanie informacja a braku takiego pracownika.

drop proc if exists p_1
go
create proc p_1
	@emp_id int = 0
as
	if exists (
		select e.EmployeeID 
		from Employees e 
		where e.EmployeeID = @emp_id
	) begin
		select
			e.FirstName
			, e.LastName
			, e.Country
		from Employees e
		where e.EmployeeID = @emp_id
	end
	else print concat( 'No such employee with ID= ', @emp_id )
go

exec p_1 1
go
exec p_1 
go


-- 1A. j.w dodatkowo procedura poda różnicę w latach pomędzy datą urodzenia pracownika a datą jego zatrudnienia.

drop proc if exists p_1a
go
create proc p_1a
	@emp_id int = 0
as
	if exists (
		select e.EmployeeID 
		from Employees e 
		where e.EmployeeID = @emp_id
	) begin
		select
			e.FirstName
			, e.LastName
			, e.Country
			, datediff( year, e.BirthDate, e.HireDate ) [Age on Hire Date]
		from Employees e
		where e.EmployeeID = @emp_id
	end
	else print concat( 'No such employee with ID: ', @emp_id )
go

exec p_1a 1
go
exec p_1a 
go


-- 2. Zdefiniować procedurę, która zwróci liczbę zatrudnionych wszystkich pracowników.

drop proc if exists p_2
go
create proc p_2
	@emp_no int out
as
	select @emp_no = count( * )
	from Employees
go

declare @num int
exec p_2 @num out
print concat( 'Number of employees: ', @num )
go


-- 3. Zdefiniować procedurę, która zwróci liczbę produktów w danej kategorii podanej jako pierwszy parametr. Parametr drugi typu OUT zwróci liczbę produktów.

drop proc if exists p_3
go
create proc p_3
	@cat_id int
	, @prod_no int out
as
	select @prod_no = count( * )
	from Products p
	where p.CategoryID = @cat_id
go

declare @num int
exec p_3 1, @num out
print concat( 'Number of products: ', @num )
go


------FUNCTION


-- 1. Zdefiniować funkcję, która wycina spacje na początku i końcu zmiennej typu VARCHAR i zwraca to co zostanie.

drop function if exists f_1
go
create function f_1(
	@str varchar(1024)
) returns varchar(1024)
begin
	return trim( @str )
end
go

print '[' + dbo.f_1( '        Hello world!        ' ) + ']'
go


-- 2. Zdefiniować funkcję, która dla categoryid zwraca wartość średnią z wszystkich produktów w tej kategorii

drop function if exists f_2
go
create function f_2(
	@cat_id int
) returns float
begin
	declare @prod_no int

	select @prod_no = avg( p.UnitPrice * p.UnitsInStock )
	from Products p
	where p.CategoryID = @cat_id

	return @prod_no
end
go

select
	c.CategoryID
	, dbo.f_2( c.CategoryID ) [Average value of stock]
from Categories c
go


-- 3. Zdefiniować funkcję, która dla categoryname zwraca wartość średnią z wszystkich produktów w tej kategorii

drop function if exists f_3
go
create function f_3(
	@cat_name nvarchar(15)
) returns float
begin
	declare @prod_no int

	select @prod_no = avg( p.UnitPrice * p.UnitsInStock )
	from Products p
	inner join Categories c
		on p.CategoryID = c.CategoryID
	where c.CategoryName = @cat_name

	return @prod_no
end
go

select
	c.CategoryName
	, dbo.f_3( c.CategoryName ) [Average value of stock]
from Categories c
go


-- 4. Zdefiniować funkcję do konewrsji typu date na string postaci YYYY-MM-DD.

drop function if exists f_4
go
create function f_4(
	@date date
) returns char(10)
begin
	return concat_ws(
		'-'
		, format( year( @date ), 'D4' )
		, format( month( @date ), 'D2' )
		, format( day( @date ), 'D2' )
	)
end 
go

select dbo.f_4( getdate() )
go


-- 5. Zdefiniować funkcję, która zwraca z daty podanej jako parametr wejściowy dzień tygodnia w języku polskim.

drop function if exists f_5
go
create function f_5(
	@date date
) returns varchar(15)
begin
	return case datepart( dw, @date )
	when 2 then 'poniedziałek'
	when 3 then 'wtorek'
	when 4 then 'środa'
	when 5 then 'czwartek'
	when 6 then 'piątek'
	when 7 then 'sobota'
	else 'niedziela'
	end
end 
go

select dbo.f_5( getdate() )
go

-- 6. Zdefiniować funkcję z trzema parametrami, która sprawdzi czy dane boki tworzą trójąt, a jeśli tak to obliczyć jego pole.

drop function if exists f_6
go
create function f_6(
	@a float
	, @b float
	, @c float
) returns float
begin
	return case
		when @a + @b > @c
				and @a + @c > @b
				and @b + @c > @a
			then sqrt(
				4 * @a * @a * @b * @b
				- power( @a * @a + @b * @b - @c * @c, 2 )
			) / 4.0
		else -1
	end
end 
go

select dbo.f_6(3, 4, 5)
select dbo.f_6(1, 1, 3)
go


-- 7. Zdefiniować funkcję zamieniajacą wszystkie spacje podkreśleniem.

drop function if exists f_7
go
create function f_7(
	@str varchar(1024)
) returns varchar(1024)
begin
	return replace( @str, ' ', '_' ) 
end 
go

select dbo.f_7( 'Hello There. General Kenobi!' )
go


-- 8. Zdefiniować funkcję do odwracania stringu.

drop function if exists f_8
go
create function f_8(
	@str varchar(1024)
) returns varchar(1024)
begin
	return reverse( @str )
end 
go

select dbo.f_8( 'coffee' )
go


-- 9. Zdefiniować funkcję, która sprawdza czy dana liczba całkowita jest parzysta czy nieparzysta i zwraca wartość 'Parzysta' lub 'Nieparzysta'.

drop function if exists f_9
go
create function f_9(
	@num int
) returns varchar(12)
begin
	return iif( @num % 2 = 0, 'Parzysta', 'Nieparzysta' )
end 
go

select dbo.f_9( 1 )
select dbo.f_9( 2 )
go


--10. Zdefiniować funkcję do obliczenia wartości silnia z liczby całkowitej (zdefiniować obsługę błędów w przypadku liczb mniejszych od 1 i takich, które przekroczą zakres wykorzystywaneo typu.

drop function if exists f_10
go
create function f_10(
	@num int
) returns bigint
begin
	return case
		when @num < 0 then -1
		when @num > 20 then -2
		when @num = 0 then 1
		when @num = 1 then 1
		else @num * dbo.f_10( @num - 1)
	end
end 
go

select dbo.f_10( 13 )
go


------------------------------------
-- Dla chętnych dodatkowe zadanie --
------------------------------------
-- 11. Zadanie dla chętnych związanej z definicją procedury przechowywanej związanej z numerem PESEL
-- Założenia procedury:
-- •	Dodawanie użytkowników następuje na podstawie numeru PESEL (unikalny id tabeli), imienia oraz nazwiska
-- •	Z numeru pesel uzyskujemy datę urodzenia oraz płeć
-- •	Numer pesel, zawsze liczy 11 znaków
-- •	Do procedury można docelowo dołożyć weryfikację sumy kontrolnej oraz poszczególnych składników peselu.
-- •	bez obsługi lat 1800-1899
-- •	bez obsługi 11 cyfry, będącej sumą kontrolną
-- •	obsługa potencjalnych błędów (opcjonalnie)
-- dodatkowe założenia, aby procedura była w pełni funkcjonalna
-- •	Wspomnianq wcześniej obsługa lat 1800-1899
-- •	Obsługa 11 cyfry, będącej sumą kontrolną
-- •	Obsługa potencjalnych błędów

-- Informacje o strukturze PESEL - https://pl.wikipedia.org/wiki/PESEL

--Struktura tabeli i procedury
CREATE TABLE Osoba
(
    OsobaId char(11) NOT NULL PRIMARY KEY,
    Imie varchar(50) NOT NULL,
    Nazwisko varchar(50) NOT NULL,
    Plec char(1) NOT NULL,
    DataUrodzenia smalldatetime NOT NULL
)
GO
CREATE PROCEDURE DodajOsoba 
    @OsobaId char(11),
    @Imie varchar(50),
    @Nazwisko varchar(50)
	AS
	BEGIN
    PRINT 'Start'
--  ...
	END;
GO