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

  INSERT INTO dbo.Employees(EmployeeID, LastName, ReportsTo)
    VALUES(1, 'Emp1', NULL);

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
-- 1A. j.w dodatkowo procedura poda różnicę w latach pomędzy datą urodzenia pracownika a datą jego zatrudnienia.
-- 2. Zdefiniować procedurę, która zwróci liczbę zatrudnionych wszystkich pracowników.
-- 3. Zdefiniować procedurę, która zwróci liczbę produktów w danej kategorii podanej jako pierwszy parametr. Parametr drugi typu OUT zwróci liczbę produktów.

------FUNCTION
-- 1. Zdefiniować funkcję, która wycina spacje na początku i końcu zmiennej typu VARCHAR i zwraca to co zostanie.
-- 2. Zdefiniować funkcję, która dla categoryid zwraca wartość średnią z wszystkich produktów w tej kategorii
-- 3. Zdefiniować funkcję, która dla categoryname zwraca wartość średnią z wszystkich produktów w tej kategorii
-- 4. Zdefiniować funkcję do konewrsji typu date na string postaci YYYY-MM-DD.
-- 5. Zdefiniować funkcję, która zwraca z daty podanej jako parametr wejściowy dzień tygodnia w języku polskim.
-- 6. Zdefiniować funkcję z trzema parametrami, która sprawdzi czy dane boki tworzą trójąt, a jeśli tak to obliczyć jego pole.
-- 7. Zdefiniować funkcję zamieniajacą wszystkie spacje podkreśleniem.
-- 8. Zdefiniować funkcję do odwracania stringu.
-- 9. Zdefiniować funkcję, która sprawdza czy dana liczba całkowita jest parzysta czy nieparzysta i zwraca wartość 'Parzysta' lub 'Nieparzysta'.
--10. Zdefiniować funkcję do obliczenia wartości silnia z liczby całkowitej (zdefiniować obsługę błędów w przypadku liczb mniejszych od 1 i takich, które przekroczą zakres wykorzystywaneo typu.

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