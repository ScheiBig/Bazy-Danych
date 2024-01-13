-----------------------------
--  Tworzenie bazy danych  --
-----------------------------

use master
go

drop database if exists Biblioteka
go

/* Tworzenie bazy używając dynamicznej kwerendy - użycie katalogu w którym SQL Server przechowuje bazy danych */

declare @device_directory nvarchar(512)
select @device_directory= substring(filename, 1, charindex(N'master.mdf', lower(filename)) - 1)
from master.dbo.sysaltfiles 
where dbid = 1 
	and fileid = 1

declare @sql nvarchar(2048)
select @sql = concat(
	N'   create database Biblioteka'
	, N' on primary ('
	, N' 	name= N''Biblioteka_dat'''
	, N' 	, filename= N''', @device_directory, N'lab07_biblioteka.mdf'''
	, N' )'
	, N' log on ('
	, N' 	name= N''Biblioteka_log'''
	, N' 	, filename= N''', @device_directory, N'lab07_biblioteka.ldf'''
	, N' )'
)

exec( @sql )
go


-----------------------
--  Tworzenie tabel  --
-----------------------

use Biblioteka
go

drop table if exists [Rejestr Wypozyczen]
drop table if exists Czytelnicy
drop table if exists Wojewodztwa
drop table if exists Egzemplarze
drop table if exists Szafki
drop table if exists [Autorstwa Publikacji]
drop table if exists Autorzy
drop table if exists Publikacje
drop table if exists Kategorie
drop table if exists Wydawnictwa
go

create table Wydawnictwa (

	id_wydawnictwa int identity(1,1) 
		constraint NN_wydawnictwo not null
		constraint PK_wydawnictwo primary key

	, nazwa nvarchar(128) 
		constraint NN_nazwa not null
		constraint UQ_nazwa_wydawnictwa unique
)

create table Kategorie (

	id_kategorii int identity(1,1)
		constraint NN_kategoria not null
		constraint PK_kategoria primary key

	, nazwa nvarchar(64)
		constraint NN_nazwa not null
)

/* Kolumnę z szafką przenoszę do tabeli Egzemplarze - różne Egzemplarze mogą znajdować się
	w różnych miejscach, na przykład na półce oraz na wystawie przy czytelni.
*/
create table Publikacje (

	id_publikacji int identity(1,1) 
		constraint NN_publikacja not null
		constraint PK_publikacja primary key

	, id_kategorii int 
		constraint NN_kategoria not null
		constraint FK_publikacja_kategoria references Kategorie( id_kategorii )

	, id_wydawnictwa int
		constraint NN_wydawnictwo not null
		constraint FK_publikacja_wydawnictwo references Wydawnictwa( id_wydawnictwa )

	, tytul nvarchar(128)
		constraint NN_tytul not null

	, rok_wydania char(4)
		constraint CK_rok_wydania check ( rok_wydania like '[1-2][0-9][0-9][0-9]' )

	, miejsce_wydania nvarchar(32)
)

create table Autorzy (

	id_autora int identity(1,1)  
		constraint NN_autor not null
		constraint PK_autor primary key

	, imie nvarchar(32)  
		constraint NN_imie not null

	, nazwisko nvarchar(64)  
		constraint NN_nazwisko not null

	, uwagi nvarchar(128)
)

create table [Autorstwa Publikacji] (

	id_autora int
		constraint NN_autor not null
		constraint FK_autorstwo_autor references Autorzy( id_autora )

	, id_publikacji int
		constraint NN_publikacja not null
		constraint FK_autorstwo_publikacja references Publikacje( id_publikacji )

	, constraint PK_autorstwo primary key ( id_autora, id_publikacji )
)

create table Szafki (

	id_szafki int identity(1,1) 
		constraint NN_szafka not null
		constraint PK_szafka primary key

	, lokalizacja nvarchar(64)
)

create table Egzemplarze (

	id_egzemplarza int identity(1,1)  
		constraint NN_egzemplarz not null
		constraint PK_egzemplarz primary key

	, id_szafki int 
		constraint NN_szafka not null
		constraint FK_egzemplarz_szafka references Szafki( id_szafki )
	
	, id_publikacji int 
		constraint NN_publikacja not null
		constraint FK_egzemplarz_publikacja references Publikacje( id_publikacji )
	
	, ubytki nvarchar(128) 
		constraint NN_ubytki not null
		constraint DF_ubytki default 'Brak'
)

create table Wojewodztwa (
	
	id_wojewodztwa int identity(1,1) 
		constraint NN_wojewodztwo not null
		constraint PK_wojewodztwo primary key
		constraint CK_wojewodztwo check ( id_wojewodztwa <= 16 )
	
	, nazwa nvarchar(20)
		constraint NN_nazwa not null
		constraint CK_nazwa check ( nazwa in (
			'dolnośląskie', 'kujawsko-pomorskie', 'lubelskie', 'lubuskie'
			, 'łódzkie', 'małopolskie', 'mazowieckie', 'opolskie'
			, 'podkarpackie', 'podlaskie', 'pomorskie', 'śląskie'
			, 'świętokrzyskie', 'warmińsko-mazurskie', 'wielkopolskie', 'zachodniopomorskie'
		) )
)

create table Czytelnicy (
	
	id_czytelnika int identity(1,1)
		constraint NN_czytelnik not null
		constraint PK_czytelnik primary key

	, imie nvarchar(32)
		constraint NN_imie not null

	, nazwisko nvarchar(64)
		constraint NN_nazwisko not null	
	
	, id_dokumentu nvarchar(128)
		constraint NN_id_dokumentu not null
		constraint UQ_id_dokumentu unique
	
	, nr_dokumentu nvarchar(32)
		constraint NN_nr_dokumentu not null
	
	, PESEL char(11)
		constraint NN_PESEL not null
		constraint CH_PESEL check ( PESEL like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' 
			and ( (
				convert( tinyint, substring( PESEL,  1, 1 ) * 1 ) +
				convert( tinyint, substring( PESEL,  2, 1 ) * 3 ) +
				convert( tinyint, substring( PESEL,  3, 1 ) * 7 ) +
				convert( tinyint, substring( PESEL,  4, 1 ) * 9 ) +
				convert( tinyint, substring( PESEL,  5, 1 ) * 1 ) +
				convert( tinyint, substring( PESEL,  6, 1 ) * 3 ) +
				convert( tinyint, substring( PESEL,  7, 1 ) * 7 ) +
				convert( tinyint, substring( PESEL,  8, 1 ) * 9 ) +
				convert( tinyint, substring( PESEL,  9, 1 ) * 1 ) +
				convert( tinyint, substring( PESEL, 10, 1 ) * 3 ) +
				convert( tinyint, substring( PESEL, 11, 1 ) * 1 )
			) % 10 ) = 0
		)
		constraint UQ_PESEL unique
	
	/* Należy pamiętać, aby 1 stycznia 2300 zaktualizować formułę! */
	, data_urodzenia as ( 
		case
			when substring( PESEL, 3, 1 ) in ( '8', '9' ) 
				then datefromparts(
					convert( int, '18' + substring( PESEL, 1, 2 ) )
					, convert( int, substring( PESEL, 3, 2 ) ) - 80
					, convert( int, substring( PESEL, 5, 2 ) )
				)
			when substring( PESEL, 3, 1 ) in ( '0', '1' ) 
				then datefromparts(
					convert( int, '19' + substring( PESEL, 1, 2 ) )
					, convert( int, substring( PESEL, 3, 2 ) )
					, convert( int, substring( PESEL, 5, 2 ) )
				)
			when substring( PESEL, 3, 1 ) in ( '2', '3' ) 
				then datefromparts(
					convert( int, '20' + substring( PESEL, 1, 2 ) )
					, convert( int, substring( PESEL, 3, 2 ) ) - 20
					, convert( int, substring( PESEL, 5, 2 ) )
				)
			when substring( PESEL, 3, 1 ) in ( '4', '5' ) 
				then datefromparts(
					convert( int, '21' + substring( PESEL, 1, 2 ) )
					, convert( int, substring( PESEL, 3, 2 ) ) - 40
					, convert( int, substring( PESEL, 5, 2 ) )
				)
			when substring( PESEL, 3, 1 ) in ( '6', '7' ) 
				then datefromparts(
					convert( int, '22' + substring( PESEL, 1, 2 ) )
					, convert( int, substring( PESEL, 3, 2 ) ) - 60
					, convert( int, substring( PESEL, 5, 2 ) )
				)
			end
	) persisted
		constraint CH_data_minimum check ( dateadd( year, 12, data_urodzenia )<=  getdate() )

	, plec as (
		case substring( PESEL, 10, 1 )
			when 0 then 'Kobieta'
			when 2 then 'Kobieta'
			when 4 then 'Kobieta'
			when 6 then 'Kobieta'
			when 8 then 'Kobieta'

			when 1 then 'Mężczyzna'
			when 3 then 'Mężczyzna'
			when 5 then 'Mężczyzna'
			when 7 then 'Mężczyzna'
			when 9 then 'Mężczyzna'
		end
	)
	
	, miejsce_urodzenia nvarchar(32)
	
	, numer_telefonu char(9)
		constraint CH_numer_telefonu check ( numer_telefonu like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' )
	
	, kod_pocztowy char(6)
		constraint NN_kod_pocztowy not null
		constraint CK_kod_pocztowy check ( kod_pocztowy like '[0-9][0-9]-[0-9][0-9][0-9]' )
	
	, miejscowosc nvarchar(32)
		constraint NN_miejscowosc not null
	
	, typ_ulicy char(5)
		constraint CK_typ_ulicy check ( typ_ulicy is null or typ_ulicy in ( 'ul.','Al.','Plac','skwer' ) )
	
	, nazwa_ulicy nvarchar(96)
	
	, numer_posesji nvarchar(8)
		constraint NN_numer_posesji not null
	
	, numer_mieszkania nvarchar(8)
	
	, id_wojewodztwa int
		constraint NN_wojewodztwo not null
		constraint FK_wojewodztwo references Wojewodztwa( id_wojewodztwa )
)


create table [Rejestr Wypozyczen] (
	
	id_czytelnika int
		constraint NN_cczytelnik not null
		constraint FK_czytelnik references Czytelnicy( id_czytelnika )
	
	, id_egzemplarza int
		constraint NN_egzemplarz not null
		constraint FK_egzemlarz references Egzemplarze( id_egzemplarza )
	
	, data_wypozyczenia datetime
		constraint NN_data_wypozyczenia not null
		constraint DF_data_wypozyczenia default getdate()

	, termin_zwrotu datetime
		constraint NN_termin_zwrotu not null
		constraint DF_termin_zwrotu default dateadd( month, 3, getdate() )

	, data_zwrotu datetime

	, constraint PK_wypozyczenie primary key ( id_czytelnika, id_egzemplarza, data_wypozyczenia )
	, constraint CH_termin_kolejnosc check ( termin_zwrotu > data_wypozyczenia )
	, constraint CH_daty_kolejnosc check (data_zwrotu is null or data_zwrotu > data_wypozyczenia )
)


-------------------------
--  Wstawianie danych  --
-------------------------

insert into Wydawnictwa ( nazwa )
values
	( 'Greg' )
	, ( 'NieZwykłe' )
	, ( 'Wydawnictwo Prószyński i S-Ka' )
	, ( 'Wydawnictwo Kobiece' )
go

insert into Kategorie ( nazwa )
values
	( 'Lektury' )
	, ( 'Literatura obyczajowa' )
	, ( 'Dla młodzieży' )
	, ( 'Biografie' )
go

insert into Publikacje (
	id_kategorii
	, id_wydawnictwa
	, tytul
	, rok_wydania
	, miejsce_wydania
)
values
(
	1
	, 1
	, 'Potop'
	, '2021'
	, 'Kraków'
)
, (
	2
	, 2
	, 'Maybe You. Westwood Academy. Tom 2'
	, '2023'
	, 'Grojec'
)
, (
	3
	, 3
	, 'Pamiętnik księżniczki. Tom 1'
	, '2023'
	, 'Warszawa'
)
, (
	4
	, 4
	, 'Barbie i Ruth'
	, '2023'
	, 'Białystok'
)
go

insert into Autorzy (
	imie
	, nazwisko
	, uwagi
)
values
(
	'Henryk'
	, 'Sienkiewicz'
	, 'Nie żyje'
)
, (
	'Weronika'
	, 'Ancerowicz'
	, null
)
, (
	'Meg'
	, 'Cabot'
	, null
)
, (
	'Robin'
	, 'Gerber'
	, null
)
go

insert into [Autorstwa Publikacji] (
	id_autora
	, id_publikacji
)
values 
( 1, 1 )
, ( 2, 2 )
, ( 3, 3 )
, ( 4, 4 )
go

insert into Szafki ( lokalizacja )
values
	( 'Czytelnia' )
	, ( 'Piętro 1 Korytarz 3' )
	, ( 'Parter Korytarz 5')
	, ( null )
go

insert into Egzemplarze (
	id_szafki
	, id_publikacji
)
values ( 2, 1 )

insert into Egzemplarze (
	id_szafki
	, id_publikacji
	, ubytki
)
values (
	1, 2
	, 'Pognieciona ostatnia strona'
)

insert into Egzemplarze (
	id_szafki
	, id_publikacji
)
values ( 3, 3 )

insert into Egzemplarze (
	id_szafki
	, id_publikacji
	, ubytki
)
values (
	4, 4
	, 'Przetarta okładka'
)
go


insert into Wojewodztwa ( nazwa )
values 
	( 'dolnośląskie' )          -- 1
	, ( 'kujawsko-pomorskie' )  -- 2
	, ( 'lubelskie' )           -- 3
	, ( 'lubuskie' )            -- 4
	, ( 'łódzkie' )             -- 5
	, ( 'małopolskie' )         -- 6
	, ( 'mazowieckie' )         -- 7
	, ( 'opolskie' )            -- 8
	, ( 'podkarpackie' )        -- 9
	, ( 'podlaskie' )           -- 10
	, ( 'pomorskie' )           -- 11
	, ( 'śląskie' )             -- 12
	, ( 'świętokrzyskie' )      -- 13
	, ( 'warmińsko-mazurskie' ) -- 14
	, ( 'wielkopolskie' )       -- 15
	, ( 'zachodniopomorskie' )  -- 16
go

insert into Czytelnicy (
	imie
	, nazwisko
	, id_dokumentu
	, nr_dokumentu
	, PESEL
	, numer_telefonu
	, kod_pocztowy
	, miejscowosc
	, typ_ulicy
	, nazwa_ulicy
	, numer_posesji
	, numer_mieszkania
	, id_wojewodztwa
) values 
( -- 1
	'Jan'
	, 'Nowak'
	, 'LOL234667'
	, 'LOL234667'
	, '98032885157'
	, '696079472'
	, '05-840'
	, 'Kotowice'
	, null
	, null
	, '50A'
	, null
	, 7
)
, ( -- 2
	'Aleksander'
	, 'Kowalski'
	, 'KEK432153'
	, 'KEK432153'
	, '07292643733'
	, '784566672'
	, '95-030'
	, 'Rzgów'
	, 'ul.'
	, 'Cmentarna'
	, '41'
	, null
	, 5
)
, ( -- 3
	'Zofia'
	, 'Wiśniewska'
	, 'HEH736457'
	, 'HEH736457'
	, '01291358197'
	, '539983186'
	, '61-586'
	, 'Poznań'
	, 'ul.'
	, 'Matyi'
	, '2'
	, 'P1'
	, 15
)
, ( -- 4
	'Zuzanna'
	, 'Wójcik'
	, 'XDD901230'
	, 'XDD901230'
	, '51081288296'
	, '667858587'
	, '70-784'
	, 'Szczecin'
	, 'ul.'
	, 'Andrzeja Struga'
	, '32'
	, null
	, 16
)
go

insert into [Rejestr Wypozyczen] (
	id_czytelnika
	, id_egzemplarza
)
values (
	4
	, 1
)

insert into [Rejestr Wypozyczen] (
	id_czytelnika
	, id_egzemplarza
	, data_wypozyczenia
	, data_zwrotu
)
values (
	2
	, 4
	, '2023-12-12'
	, '2024-01-05'
)
insert into [Rejestr Wypozyczen] (
	id_czytelnika
	, id_egzemplarza
	, data_wypozyczenia
	, termin_zwrotu
	, data_zwrotu
)
values (
	1
	, 2
	, '2023-04-20'
	, '2023-06-09'
	, null
)
insert into [Rejestr Wypozyczen] (
	id_czytelnika
	, id_egzemplarza
	, data_wypozyczenia
)
values (
	3
	, 3
	, '2024-01-13'
)
go