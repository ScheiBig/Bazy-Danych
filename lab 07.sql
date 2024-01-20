USE Northwind;

---------------------------------------------------------------------
-- Zmienne
---------------------------------------------------------------------

-- Deklarowanie zmiennej i inicjowanie jej wartoœci
DECLARE @i AS INT;
SET @i = 10;
GO

-- Deklarowanie i inicjowanie zmiennej w jednym wyra¿eniu
DECLARE @i AS INT = 10;
GO

-- Przechowanie wyniku podzapytania w zmiennej
DECLARE @empname AS NVARCHAR(61);

SET @empname = (SELECT firstname + N' ' + lastname
                FROM Employees
                WHERE EmployeeID = 3);

SELECT @empname AS empname;
GO

-- U¿ycie polecenia SET do przypisania po jednej zmiennej na raz
DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SET @firstname = (SELECT firstname
                  FROM Employees
                  WHERE EmployeeID = 3);
SET @lastname = (SELECT lastname
                  FROM Employees
                  WHERE EmployeeID = 3);

SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- U¿ycie polecenia SELECT do przypisania wielu zmiennych w jednym wyra¿eniu
DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SELECT
  @firstname = firstname,
  @lastname  = lastname
FROM Employees
WHERE EmployeeID = 3;

SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- SELECT nie powoduje b³êdu w przypadku zwrócenia wielu wierszy 
DECLARE @empname AS NVARCHAR(61);

SELECT @empname = firstname + N' ' + lastname
FROM Employees
WHERE ReportsTo = 2;

SELECT @empname AS empname;
GO

-- SET powoduje b³¹d, gdy zwracanych jest wiele wierszy 
DECLARE @empname AS NVARCHAR(61);

SET @empname = (SELECT firstname + N' ' + lastname
                FROM Employees
                WHERE ReportsTo = 2);

SELECT @empname AS empname;
GO

---------------------------------------------------------------------
-- Przetwarzanie wsadowe (batch)
---------------------------------------------------------------------

-- Przetwarzanie wsadowe jako jednostka analizy

-- Poprawne
PRINT 'First batch';
USE Northwind;
GO
-- Niepoprawne
PRINT 'Second batch';
SELECT CustomerID FROM Customers;
SELECT orderid FOM Orders;   --tutaj jest z³a sk³adnia
GO
-- Poprawne
PRINT 'Third batch';
SELECT EmployeeID FROM Employees;
GO

-- Przetwarzanie wsadowe i zmienne

DECLARE @i AS INT = 10;
-- Powodzenie
PRINT @i;
GO

-- Niepowodzenie
PRINT @i;
GO

-- Instrukcje, których nie mo¿na ³¹czyæ w tym samym wsadzie

DROP VIEW IF EXISTS MyView;

CREATE VIEW MyView(a1,a2)
AS
SELECT YEAR(orderdate), COUNT(*)
FROM Orders
GROUP BY YEAR(orderdate);
GO

-- Plik wsadowy jako jednostka

-- Utwórz tabelê T1 z jedn¹ kolumn¹
DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT);
GO

-- Nieudane polecenia
ALTER TABLE dbo.T1 ADD col2 INT;
SELECT col1, col2 FROM dbo.T1;
GO

-- Udane polecenia
ALTER TABLE dbo.T1 ADD col2 INT;
GO
SELECT col1, col2 FROM dbo.T1;
GO

-- Opcja GO n 
--wykonuj¹c poni¿sze dwie linijki razem wykonujemy polecenia przed 100 razy
insert into categories values ('nazwa')
GO 100 

-- Tworzymy tabelê T1 z kolumn¹ identity
DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT IDENTITY CONSTRAINT PK_T1 PRIMARY KEY);
GO

-- Pomiñ wyœwietlanie komunikatów
SET NOCOUNT ON;
GO

-- Wykonaj plika wsadowy 100 razy
INSERT INTO dbo.T1 DEFAULT VALUES;
GO 100

SELECT * FROM dbo.T1;

---------------------------------------------------------------------
-- Elementy sterowania (kontroli)
---------------------------------------------------------------------

-- Instrukcja IF ... ELSE
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
  PRINT 'Dzisiejszy dzieñ to ostatni dzieñ roku.';
ELSE
  PRINT 'Dzisiejszy dzieñ nie jest ostatnim dniem roku.';
GO

-- IF ELSE IF
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
  PRINT 'Dzisiejszy dzieñ to ostatni dzieñ roku.';
ELSE
  IF MONTH(SYSDATETIME()) <> MONTH(DATEADD(day, 1, SYSDATETIME()))
    PRINT 'Dzisiejszy dzieñ to ostatni dzieñ miesi¹ca ale nie ostatni dzieñ roku.';
  ELSE 
    PRINT 'Dzisiejszy dzieñ nie jest ostatnim dniem miesi¹ca.';
GO

-- Blok wyra¿eñ
IF DAY(SYSDATETIME()) = 1
BEGIN
  PRINT 'Dzisiejszy dzieñ to pierwszy dzieñ miesi¹ca.';
  PRINT 'Uruchomienie procesu dla pierwszego dnia miesi¹ca.';
  /* ... tu umieszczany jest kod procesu... */
  PRINT 'Zakoñczony proces bazy danych dla pierwszego dnia miesi¹ca.';
END
ELSE
BEGIN
  PRINT 'Dzisiejszy dzieñ nie jest pierwszym dniem miesi¹ca.';
  PRINT 'Uruchomienie procesu innego ni¿ proces dla pierwszego dnia miesi¹ca.';
  /* ... tu umieszczany jest kod procesu... */
  PRINT 'Zakoñczony proces nie-dla-pierwszego dnia miesi¹ca.';
END
GO

-- Instrukcja WHILE
DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
  PRINT @i;
  SET @i = @i + 1;
END;
GO

-- BREAK
DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
  IF @i = 6 BREAK;
  PRINT @i;
  SET @i = @i + 1;
END;
GO

-- CONTINUE
DECLARE @i AS INT = 0;
WHILE @i < 10
BEGIN
  SET @i = @i + 1;
  IF @i = 6 CONTINUE;
  PRINT @i;
END;
GO

-- U¿ycie pêtli WHILE do wype³nienia tabeli liczbami
SET NOCOUNT ON;
DROP TABLE IF EXISTS dbo.Numbers;
CREATE TABLE dbo.Numbers(n INT NOT NULL PRIMARY KEY);
GO

DECLARE @i AS INT = 1;
WHILE @i <= 1000
BEGIN
  INSERT INTO dbo.Numbers(n) VALUES(@i);
  SET @i = @i + 1;
END;
GO

select count(*) from Numbers;
---------------------------------------------------------------------
-- Kursory
---------------------------------------------------------------------

-- Wype³nianie zmiennych tabelarycznych i tabeli za pomoc¹ kursora
SET NOCOUNT ON;

DECLARE @Result AS TABLE
(
  a1 varchar(200)
);

DECLARE
  @A1     AS NVARCHAR(40),
  @A2     AS MONEY,
  @A3     AS SMALLINT;

drop table if exists Test;
create table Test (a1 varchar(200));

DECLARE C CURSOR FAST_FORWARD /* read only, forward only */ FOR
  SELECT productname, unitprice, UnitsInStock
  FROM Products where ProductID<10
  ORDER BY UnitPrice, UnitsInStock;

OPEN C;

FETCH NEXT FROM C INTO @A1, @A2, @A3;

WHILE @@FETCH_STATUS = 0
BEGIN
  print CONCAT(@A1,' ',@A2,' ',@A3)  
  insert into test values (CONCAT(@A1,' ',@A2,' ',@A3));
  insert into @Result values (CONCAT(@A1,' ',@A2,' ',@A3));
  FETCH NEXT FROM C INTO @A1, @A2, @A3;
END;

CLOSE C;
DEALLOCATE C;

SELECT * FROM @Result
SELECT * from Test 
GO

-- Napisaæ kod, który sprawdzi jakie w danej bazie s¹ widoki i skasuje wszystkie

DECLARE
  @A1     AS NVARCHAR(40);

DECLARE C CURSOR FAST_FORWARD /* read only, forward only */ FOR
  select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_TYPE='VIEW';

OPEN C;

FETCH NEXT FROM C INTO @A1;

WHILE @@FETCH_STATUS = 0
BEGIN
  print @A1;
  SET @a1 = 'drop view '+@a1;  
  exec (@a1);
  FETCH NEXT FROM C INTO @A1;
END;

CLOSE C;
DEALLOCATE C;

GO

---------------------------------------------------------------------
-- Temporary Tables
---------------------------------------------------------------------

-- Local Temporary Tables

DROP TABLE IF EXISTS #MyTable;
GO
CREATE TABLE #MyTable
(
  ID INT NOT NULL PRIMARY KEY,
  Num INT NOT NULL
);

INSERT INTO #MyTable(ID, Num) values (1,1),(2,2),(3,3);
SELECT * FROM #MyTable;
GO

-- Spróbuj uzyskaæ dostêp do tabeli z innej sesji

SELECT * FROM #MyTable;

-- Czyszczenie z oryginalnej sesji
DROP TABLE IF EXISTS #MyTable;

-- Global Temporary Tables
CREATE TABLE ##MyTable
(
  ID INT NOT NULL PRIMARY KEY,
  Num INT NOT NULL
);

-- Uruchom z dowolnej sesji
INSERT INTO ##MyTable(id, Num) VALUES (1,1),(2,2),(3,3),(4,4);

-- Uruchom z dowolnej sesji
SELECT * FROM ##MyTable;

-- Uruchom z dowolnej sesji
DROP TABLE IF EXISTS ##MyTable;
GO

-- Zmienna tabelaryczna
DECLARE @MyTable TABLE
(
  ID INT NOT NULL PRIMARY KEY,
  Num INT NOT NULL
);

INSERT INTO @MyTable (id, Num) VALUES (1,1),(2,2),(3,3),(4,4);

SELECT * FROM @MyTable;
GO

-- Typ tabelaryczny
DROP TYPE IF EXISTS dbo.MyType;

CREATE TYPE dbo.MyType AS TABLE
(
  ID INT NOT NULL PRIMARY KEY,
  Num INT NOT NULL
);
GO
-- U¿ycie typu tabelarycznego 
DECLARE @a1 AS dbo.MyType;

INSERT INTO @a1(ID, Num) VALUES (1,1),(2,2),(3,3),(4,4);
SELECT * FROM @a1;
GO


---------------------------------------------------------------------
-- Dynamiczny SQL
---------------------------------------------------------------------

-- Polecenie EXEC

-- Przyk³ad z poleceniem EXEC
DECLARE @sql AS VARCHAR(100);
SET @sql = 'PRINT ''This message was printed by a dynamic SQL batch.'';';
EXEC(@sql);
GO

-- sp_executesql - Stored Procedure

-- Przyk³ad z uzyciem sp_executesql
DECLARE @sql AS NVARCHAR(100);

SET @sql = N'SELECT orderid, orderdate
FROM Orders
WHERE orderid = @orderid;';

EXEC sys.sp_executesql
  @stmt = @sql,
  @params = N'@orderid AS INT',
  @orderid = 10248;
GO

---------------------------------------------------------------------
-- Error Handling (Obs³uga b³êdów)
---------------------------------------------------------------------

-- Prosty przyk³ad
BEGIN TRY
  PRINT 10/2;
  PRINT 'No error';
END TRY
BEGIN CATCH
  PRINT 'Error';
END CATCH;
GO

BEGIN TRY
  PRINT 10/0;
  PRINT 'No error';
END TRY
BEGIN CATCH
  PRINT 'Error';
END CATCH;
GO

-- Skrypt do tworzenia tabeli Employees1 
DROP TABLE IF EXISTS dbo.Employees1;

CREATE TABLE dbo.Employees1
(
  empid   INT         NOT NULL,
  empname VARCHAR(25) NOT NULL,
  mgrid   INT         NULL,
  CONSTRAINT PK_Employees1 PRIMARY KEY(empid),
  CONSTRAINT CHK_Employees_empid1 CHECK(empid > 0),
  CONSTRAINT FK_Employees_Employees1
    FOREIGN KEY(mgrid) REFERENCES dbo.Employees1(empid)
);
GO

-- Przyk³ad wykorzystania
BEGIN TRY

  INSERT INTO dbo.Employees1(empid, empname, mgrid)
    VALUES(0, 'Emp1', NULL);
  -- Also try with empid = 0, 'A', NULL

END TRY
BEGIN CATCH

  IF ERROR_NUMBER() = 2627
  BEGIN
    PRINT 'Handling PK violation...';
  END;
  ELSE IF ERROR_NUMBER() = 547
  BEGIN
    PRINT 'Handling CHECK/FK constraint violation...';
  END;
  ELSE IF ERROR_NUMBER() = 515
  BEGIN
    PRINT 'Handling NULL violation...';
  END;
  ELSE IF ERROR_NUMBER() = 245
  BEGIN
    PRINT 'Handling conversion error...';
  END;
  ELSE
  BEGIN
    PRINT 'Re-throwing error...';
    THROW;
  END;

  PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
  PRINT 'Error Message : ' + ERROR_MESSAGE();
  PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
  PRINT 'Error State   : ' + CAST(ERROR_STATE() AS VARCHAR(10));
  PRINT 'Error Line    : ' + CAST(ERROR_LINE() AS VARCHAR(10));
  PRINT 'Error Proc    : ' + COALESCE(ERROR_PROCEDURE(), 'Not within proc');
 
END CATCH;
GO



--	1. Zdefiniuj blok anonimowy T-SQL, który wyœwietli w formie tekstowej (w oknie messages) co trzeciego pracownika (tabela Employees) licz¹c od koñca (tzn. od koñca tak jak s¹ wstawieni do bazy danych), 
--  	którego wiek jest pomiêdzy 2 parametrami zadanymi w definicji tych dwóch paramaterów (declare).
--		W przypadku nie podania parametru pierwszego domyœlnie ustaw 18 a w przypadku nie podania drugiego ustaw 30. 


--	2. Zdefiniuj blok anonimowy T-SQL, który bêdzie zwracaæ komunikat o ró¿nicy w dniach 
--		miêdzy dat¹ bie¿¹c¹ a dat¹ podan¹ w deklaracji zmiennej na pocz¹tku bloku. 
--		W przypadku tego samego dnia zwróæ komunikat o równoœci dat itd.
--		Przyk³ad:
--		'Miêdzy dat¹ obecn¹ a dat¹ 12-05-2020 13:15:22 jest XXX dni ró¿nicy.'
--		lub
--		'Data podana w parametrze jest dat¹ bie¿¹c¹.'
--		lub
--		'Data podana w parametrze jest wiêksza od bie¿acej.'

--  3. Zdefiniuj blok anonimowy T-SQL, który poda w sekundach czas od rozpoczêcia skryptu do jego zakoñczenia (w œrodku wstawiamy dowone operacje albo funckcje, która czeka odpowiedni¹ iloœæ czasu WAITFOR)

--  4. Zdefiniuj blok anonimowy T-SQL, który wyœwietli trzy najlepiej sprzedawane produkty i wartoœæ sprzeda¿y tych produktów, 
--  	a nastêpnie w skrypcie podaæ trzy kategoriê gdzie by³a najwieksza sprzeda¿ i jaka. Na koñcu wyswietliæ czas w ms wykonania skryptu.

--  5. Zdefiniuj blok anonimowy T-SQL, który sprawdzi ile sekwencji jest zdefiniowanych w danej bazie danych. Jeœli brak jest sekwencji to utworzymy 3 sekwencje o doolnych nazwach,
--		a jeœli s¹ to skasujemy wszystkie z podaniem informacji jakie by³y ich nazwy i ile zosta³o skasowanych.

--  6. Zdefiniuj blok anonimowy T-SQL do obliczania wartoœci silnia z danej liczby podanej w czêœci declare. Jeœli przekroczymy zakres danego typu zmiennej to musimy obs³u¿yæ b³êdy jakie mog¹ wyst¹piæ

--  7. Zdefiniuj blok anonimowy T-SQL do wstawiania nowej kategorii do tabeli Categories, który sprawdzi czy nazwa kategorii istnieje czy nie. 
--     Jeœli nazwa istnieje to nale¿y zwróciæ wyj¹tek i nale¿y go obs³u¿yæ w czêœci wyjatków ³¹cznie z wycofaniem transakcji 

