USE Northwind;

---------------------------------------------------------------------
-- Zmienne
---------------------------------------------------------------------

-- Deklarowanie zmiennej i inicjowanie jej wartości
DECLARE @i AS INT;
SET @i = 10;
GO

-- Deklarowanie i inicjowanie zmiennej w jednym wyrażeniu
DECLARE @i AS INT = 10;
GO

-- Przechowanie wyniku podzapytania w zmiennej
DECLARE @empname AS NVARCHAR(61);

SET @empname = (SELECT firstname + N' ' + lastname
                FROM Employees
                WHERE EmployeeID = 3);

SELECT @empname AS empname;
GO

-- Użycie polecenia SET do przypisania po jednej zmiennej na raz
DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SET @firstname = (SELECT firstname
                  FROM Employees
                  WHERE EmployeeID = 3);
SET @lastname = (SELECT lastname
                  FROM Employees
                  WHERE EmployeeID = 3);

SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- Użycie polecenia SELECT do przypisania wielu zmiennych w jednym wyrażeniu
DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SELECT
  @firstname = firstname,
  @lastname  = lastname
FROM Employees
WHERE EmployeeID = 3;

SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- SELECT nie powoduje błędu w przypadku zwrócenia wielu wierszy 
DECLARE @empname AS NVARCHAR(61);

SELECT @empname = firstname + N' ' + lastname
FROM Employees
WHERE ReportsTo = 2;

SELECT @empname AS empname;
GO

-- SET powoduje błąd, gdy zwracanych jest wiele wierszy 
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
SELECT orderid FOM Orders;   --tutaj jest zła składnia
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

-- Instrukcje, których nie można łączyć w tym samym wsadzie

DROP VIEW IF EXISTS MyView;

CREATE VIEW MyView(a1,a2)
AS
SELECT YEAR(orderdate), COUNT(*)
FROM Orders
GROUP BY YEAR(orderdate);
GO

-- Plik wsadowy jako jednostka

-- Utwórz tabelę T1 z jedną kolumną
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
--wykonując poniższe dwie linijki razem wykonujemy polecenia przed 100 razy
insert into categories values ('nazwa')
GO 100 

-- Tworzymy tabelę T1 z kolumną identity
DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT IDENTITY CONSTRAINT PK_T1 PRIMARY KEY);
GO

-- Pomiń wyświetlanie komunikatów
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
  PRINT 'Dzisiejszy dzień to ostatni dzień roku.';
ELSE
  PRINT 'Dzisiejszy dzień nie jest ostatnim dniem roku.';
GO

-- IF ELSE IF
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
  PRINT 'Dzisiejszy dzień to ostatni dzień roku.';
ELSE
  IF MONTH(SYSDATETIME()) <> MONTH(DATEADD(day, 1, SYSDATETIME()))
    PRINT 'Dzisiejszy dzień to ostatni dzień miesiąca ale nie ostatni dzień roku.';
  ELSE 
    PRINT 'Dzisiejszy dzień nie jest ostatnim dniem miesiąca.';
GO

-- Blok wyrażeń
IF DAY(SYSDATETIME()) = 1
BEGIN
  PRINT 'Dzisiejszy dzień to pierwszy dzień miesiąca.';
  PRINT 'Uruchomienie procesu dla pierwszego dnia miesiąca.';
  /* ... tu umieszczany jest kod procesu... */
  PRINT 'Zakończony proces bazy danych dla pierwszego dnia miesiąca.';
END
ELSE
BEGIN
  PRINT 'Dzisiejszy dzień nie jest pierwszym dniem miesiąca.';
  PRINT 'Uruchomienie procesu innego niż proces dla pierwszego dnia miesiąca.';
  /* ... tu umieszczany jest kod procesu... */
  PRINT 'Zakończony proces nie-dla-pierwszego dnia miesiąca.';
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

-- Użycie pętli WHILE do wypełnienia tabeli liczbami
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

-- Wypełnianie zmiennych tabelarycznych i tabeli za pomocą kursora
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

-- Napisać kod, który sprawdzi jakie w danej bazie są widoki i skasuje wszystkie

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

-- Spróbuj uzyskać dostęp do tabeli z innej sesji

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
-- Użycie typu tabelarycznego 
DECLARE @a1 AS dbo.MyType;

INSERT INTO @a1(ID, Num) VALUES (1,1),(2,2),(3,3),(4,4);
SELECT * FROM @a1;
GO


---------------------------------------------------------------------
-- Dynamiczny SQL
---------------------------------------------------------------------

-- Polecenie EXEC

-- Przykład z poleceniem EXEC
DECLARE @sql AS VARCHAR(100);
SET @sql = 'PRINT ''This message was printed by a dynamic SQL batch.'';';
EXEC(@sql);
GO

-- sp_executesql - Stored Procedure

-- Przykład z uzyciem sp_executesql
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
-- Error Handling (Obsługa błędów)
---------------------------------------------------------------------

-- Prosty przykład
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

-- Przykład wykorzystania
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



--	1. Zdefiniuj blok anonimowy T-SQL, który wyświetli w formie tekstowej (w oknie messages) co trzeciego pracownika (tabela Employees) licząc od końca (tzn. od końca tak jak są wstawieni do bazy danych), 

--  	którego wiek jest pomiędzy 2 parametrami zadanymi w definicji tych dwóch paramaterów (declare).
--		W przypadku nie podania parametru pierwszego domyślnie ustaw 18 a w przypadku nie podania drugiego ustaw 30. 

declare @from int
declare @to int = 70

begin
	if ( @from is null ) set @from = 18
	if ( @to is null ) set @to = 30

	declare c_1 scroll cursor for
	select concat_ws( ' ', e.FirstName, e.LastName )
	from Employees e
	where datediff( year, e.BirthDate, getdate() ) between @from and @to
	order by e.EmployeeID desc

	declare @emp varchar(32)

	open c_1
	fetch next from c_1 into @emp

	while @@fetch_status = 0
	begin
		print @emp
		fetch relative 3 from c_1 into @emp
	end

	close c_1
	deallocate c_1
end
go

--	2. Zdefiniuj blok anonimowy T-SQL, który będzie zwracać komunikat o różnicy w dniach 
--		między datą bieżącą a datą podaną w deklaracji zmiennej na początku bloku. 
--		W przypadku tego samego dnia zwróć komunikat o równości dat itd.
--		Przykład:
--		'Między datą obecną a datą 12-05-2020 13:15:22 jest XXX dni różnicy.'
--		lub
--		'Data podana w parametrze jest datą bieżącą.'
--		lub
--		'Data podana w parametrze jest większa od bieżacej.'

declare @date date = '1996-06-09'
declare @differenceMsg nvarchar(128)

begin
	declare @diff int = datediff( day, @date, getdate() )
	set @differenceMsg = case 
		when @diff < 0 
			then 'Data podana w parametrze jest większa od bieżacej.'
		when @diff = 0
			then 'Data podana w parametrze jest datą bieżącą.'
		else concat(
			'Między datą obecną a datą '
			, format( @date, N'dd-MM-yyyy hh:mm:ss' )
			, ' jest '
			, @diff 
			, ' dni różnicy.'
		)
	end
end

print @differenceMsg
go


--  3. Zdefiniuj blok anonimowy T-SQL, który poda w sekundach czas od rozpoczęcia skryptu do jego zakończenia (w środku wstawiamy dowone operacje albo funckcje, która czeka odpowiednią ilość czasu WAITFOR)

declare @end datetime
declare @begin datetime = getdate()

begin
	waitfor delay '00:00:20'
end

set @end = getdate()
print concat( 'Waited for ', datediff( second, @begin, @end ), ' seconds' )
go

--  4. Zdefiniuj blok anonimowy T-SQL, który wyświetli trzy najlepiej sprzedawane produkty i wartość sprzedaży tych produktów, 
--  	a następnie w skrypcie podać trzy kategorię gdzie była najwieksza sprzedaż i jaka. Na końcu wyswietlić czas w ms wykonania skryptu.

declare @end datetime
declare @begin datetime = getdate()

begin
	declare c_4_1 cursor for
	select 
		concat(
				'Product ['
				, p.ProductName 
				, '] with value ['
				, sum( od.UnitPrice * od.Quantity )
				, ']'
		) v
	from [Order Details] od
	inner join Products p
		on od.ProductID = p.ProductID
	group by ProductName
	order by sum( od.UnitPrice * od.Quantity )

	declare c_4_2 cursor for
	select 
		concat(
				'Category ['
				, c.CategoryName 
				, '] with value ['
				, sum( od.UnitPrice * od.Quantity )
				, ']'
		) v
	from [Order Details] od
	inner join Products p
		on od.ProductID = p.ProductID
	inner join Categories c
		on p.CategoryID = c.CategoryID
	group by CategoryName
	order by sum( od.UnitPrice * od.Quantity )


	declare @v nvarchar(128)
	declare @i int = 0

	open c_4_1

	while @i < 3
	begin
		fetch next from c_4_1 into @v
		if @@fetch_status = 0
		begin
			print @v
		end
		set @i = @i + 1
	end

	close c_4_1
	deallocate c_4_1

	set @i = 0
	open c_4_2

	while @i < 3
	begin
		fetch next from c_4_2 into @v
		if @@fetch_status = 0
		begin
			print @v
		end
		set @i = @i + 1
	end

	close c_4_2 deallocate c_4_2
end

set @end = getdate()
print concat( 'Waited for ', datediff( millisecond, @begin, @end ), ' ms' )
go

--  5. Zdefiniuj blok anonimowy T-SQL, który sprawdzi ile sekwencji jest zdefiniowanych w danej bazie danych. Jeśli brak jest sekwencji to utworzymy 3 sekwencje o doolnych nazwach,
--		a jeśli są to skasujemy wszystkie z podaniem informacji jakie były ich nazwy i ile zostało skasowanych.

begin 
	declare @seq_no int
	select @seq_no = count(*) 
	from Northwind.INFORMATION_SCHEMA.SEQUENCES

	if @seq_no > 0
	begin
		print concat(
			'There were '
			, @seq_no
			, ' sequences'
		)

		declare c_5 cursor for
		select SEQUENCE_NAME
		from Northwind.INFORMATION_SCHEMA.SEQUENCES

		declare @name varchar(128)
		declare @sql varchar(1024)

		open c_5
		fetch next from c_5 into @name

		while @@fetch_status = 0
		begin
			print concat( 
				'Sequence named: '
				, @name
			)
			set @sql = concat(
				'drop sequence if exists '
				, @name
			)
			exec( @sql )
			fetch next from c_5 into @name
		end

		close c_5 deallocate c_5
	end
	else 
	begin
		create sequence s_int as int
		create sequence s_bigint as bigint
		create sequence s_tinyint as tinyint
	end
end
go

--  6. Zdefiniuj blok anonimowy T-SQL do obliczania wartości silnia z danej liczby podanej w części declare. Jeśli przekroczymy zakres danego typu zmiennej to musimy obsłużyć błędy jakie mogą wystąpić

declare @num int = 22
begin
	declare @fact bigint = 1

	if @num < 0 print concat(
		'Cannot calculate factorial of negative number '
		, @num
	)
	else begin
		begin try
			declare @i int = 1
			while @i < @num
			begin
				set @fact = @fact * @i
				set @i = @i + 1
			end

			print concat(
				'Factorial of '
				, @num
				, ' is '
				, @fact
			)
		end try
		begin catch
			print concat(
				'Number '
				, @num
				, ' is too big for factorial calculation'
			)
			print ERROR_MESSAGE()
		end catch
	end
end
go

--  7. Zdefiniuj blok anonimowy T-SQL do wstawiania nowej kategorii do tabeli Categories, który sprawdzi czy nazwa kategorii istnieje czy nie. 
--     Jeśli nazwa istnieje to należy zwrócić wyjątek i należy go obsłużyć w części wyjatków łącznie z wycofaniem transakcji 

declare @cat_name nvarchar(15) = 'Cat1'
begin
	begin tran
	
	begin try
		if exists ( select CategoryName
			from Categories
			where CategoryName = @cat_name
		) throw 123456, 'Category with specified name already exists', 1

		insert into Categories ( CategoryName )
		values ( @cat_name )

		commit tran
	end try
	begin catch
		print 'Cannot insert category due to errors'
		print ERROR_MESSAGE()
		rollback tran
	end catch
end