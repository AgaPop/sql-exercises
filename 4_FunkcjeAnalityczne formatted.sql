--Zadanie 1.
--Korzystaj�c tabeli Products zaprojektuj zapytanie, kt�re zwr�ci �redni� jednostkow� cen� wszystkich
--produkt�w. Wynik zaokr�glij do dw�ch miejsc po przecinku.

SELECT Round(Avg(UnitPrice), 2) AS AvgUnitPrice
FROM   Products 

--Zadanie 2.
--Korzystaj�c z tabel Products oraz Categories, zaprojektuj zapytanie, kt�re zwr�ci nazw� kategorii oraz
--�redni� jednostkow� cen� produkt�w w danej kategorii. �redni� zaokr�glij do dw�ch miejsc po
--przecinku. Wynik posortuj alfabetycznie po nazwie kategorii. 

SELECT c.CategoryName,
       Round(Avg(p.UnitPrice), 2) AS AvgUnitPrice
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
GROUP  BY c.CategoryName 

--Zadanie 3.
--Korzystaj�c z tabel Products oraz Categories zaprojektuj zapytanie, kt�re zwr�ci wszystkie produkty
--(ProductName) wraz z kategoriami, do kt�rych nale�� (CategoryName) oraz �redni� jednostkow� cen�
--dla wszystkich produkt�w. Analiza powinna obejmowa� produkty ze wszystkich kategorii z wyj�tkiem
--Beverages. Wynik posortuj alfabetycznie po nazwie produktu.

SELECT p.ProductName,
       c.CategoryName,
       Round(Avg(p.UnitPrice)
               OVER(), 2) AS AvgUnitPrice
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
WHERE  c.CategoryName <> 'Beverages'
ORDER  BY p.ProductName 

--Zadanie 4. (*)
--Rozbuduj poprzednie zapytanie o minimaln� i maksymaln� jednostkow� cen� dla wszystkich
--produkt�w. Tym razem interesuj� nas wszystkie produkty (usu� ograniczenie na kategori�).

SELECT p.ProductName,
       c.CategoryName,
       Round(Avg(p.UnitPrice)
               OVER(), 2) AS AvgUnitPrice,
       Round(Min(p.UnitPrice)
               OVER(), 2) AS MinUnitPrice,
       Round(Max(p.UnitPrice)
               OVER(), 2) AS MaxUnitPrice
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
ORDER  BY p.ProductName 

--Zadanie 5. (*)
--Rozbuduj poprzednie zapytanie o �redni� jednostkow� cen� w kategorii i dla danego dostawcy.

SELECT p.ProductName,
       c.CategoryName,
       Round(Avg(p.UnitPrice)
               OVER(), 2) AS AvgUnitPrice,
       Round(Min(p.UnitPrice)
               OVER(), 2) AS MinUnitPrice,
       Round(Max(p.UnitPrice)
               OVER(), 2) AS MaxUnitPrice,
       Round(Avg(p.UnitPrice)
               OVER(
                 PARTITION BY p.CategoryID), 2) AS AvgUnitPriceInCategory,
       Round(Avg(p.UnitPrice)
               OVER(
                 PARTITION BY p.SupplierId), 2) AS AvgUnitPricePerSupplier
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
ORDER  BY p.ProductName 

--Zadanie 6. (*)
--Rozbuduj poprzednie zapytanie o liczb� produkt�w w danej kategorii.

SELECT p.ProductName,
       c.CategoryName,
       Round(Avg(p.UnitPrice)
               OVER(), 2) AS AvgUnitPrice,
       Round(Min(p.UnitPrice)
               OVER(), 2) AS MinUnitPrice,
       Round(Max(p.UnitPrice)
               OVER(), 2) AS MaxUnitPrice,
       Round(Avg(p.UnitPrice)
               OVER(
                 PARTITION BY p.CategoryID), 2) AS AvgUnitPriceInCategory,
       Round(Avg(p.UnitPrice)
               OVER(
                 PARTITION BY p.SupplierId), 2) AS AvgUnitPricePerSupplier,
       Count(p.ProductID)
         OVER(
           PARTITION BY p.CategoryID) AS NumOfProdInCategory
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
ORDER  BY p.ProductName 

--Zadanie 7.
--Korzystaj�c z tabeli Orders oraz Customers przygotuj zapytanie, kt�re wy�wietli identyfikator
--zam�wienie (OrderID), nazw� klienta (CompanyName) oraz numer rekordu. Numeracja rekord�w
--powinna by� zgodna z dat� zam�wienia posortowan� rosn�co. Wyniki posortuj zgodnie
--z identyfikatorem zam�wienia (rosn�co).

SELECT o.OrderID,
       c.CompanyName,
       Row_number()
         OVER (
           ORDER BY o.orderdate) AS rowNum
FROM   Orders o
       JOIN Customers c
         ON o.CustomerID = c.CustomerID
ORDER  BY o.OrderID 

--II z wykorzystaniem f. agreguj�cych:

SELECT o.OrderID,
       c.CompanyName,
       Count(o.orderid)
         over (
           ORDER BY o.OrderDate ROWS unbounded preceding) AS ROWNUM
FROM   Orders o
       join Customers c
         ON o.CustomerID = c.CustomerID
ORDER  BY o.OrderID 

--Zadanie 8. (*)
--Zaktualizuj poprzednie zapytanie tak, aby wynik zosta� posortowany w pierwszej kolejno�ci po nazwie
--klienta (rosn�ca), a w drugiej po dacie zam�wienia (malej�co).

SELECT o.OrderID,
       c.CompanyName,
       Row_number()
         OVER (
           ORDER BY o.orderdate) AS rowNum
FROM   Orders o
       JOIN Customers c
         ON o.CustomerID = c.CustomerID
ORDER  BY c.CompanyName,
          o.OrderDate DESC 
--Jak wida� sortowanie w funkcji analitycznej oraz sortowanie ca�ego wyniku dzia�a niezale�nie.

--Zadanie 9. - Stronicowanie
--Korzystaj�c z tabel Products oraz Categories, zaprojektuj zapytanie uwzgl�dniaj�ce stronicowanie
--(wyznaczone rosn�co po identyfikatorze produktu), kt�re pozwoli wy�wietli� zadan� stron�
--zawieraj�c� informacje o produktach: identyfikator, nazwa produktu, nazwa kategorii, jednostokowa
--cena produktu, �rednia jednostkowa cena produktu w danej kategorii oraz numer strony (numer 
--wiersza nie powinien by� wy�wietlony). Wielko�� strony oraz jej numer powinny by�
--parametryzowalne. Wynik (ju� po uwzgl�dnieniu stronicowania!) powinien zosta� posortowany po
--nazwie produktu (alfabetycznie, rosn�co).

DECLARE
	@pageNum AS INT = 3,
	@pageSize AS INT = 15;

WITH 
AvgPrice 
AS
(
	SELECT c.CategoryID, Avg(UnitPrice) as AvgUnitPriceInCategory
	FROM Products p
	INNER JOIN Categories c ON c.CategoryID = p.CategoryID 
	GROUP BY c.CategoryID
),
Pages
AS 
(
	SELECT	ProductID, ProductName, CategoryName, UnitPrice, c.CategoryID, 
			Row_number() OVER (ORDER BY ProductID) AS rowNum
	FROM Products p
	INNER JOIN Categories c ON c.CategoryID = p.CategoryID
)

SELECT	pg.ProductID, pg.ProductName, pg.CategoryName, pg.UnitPrice, a.AvgUnitPriceInCategory,
		@pageNum as PageNum	
FROM Pages pg 
INNER JOIN AvgPrice a ON pg.CategoryID = a.CategoryID
WHERE pg.rowNum BETWEEN (@pageNum-1)*@pageSize+1 AND @pageNum * @pageSize
ORDER BY pg.ProductName

--Zadanie 10.
--Korzystaj�c z tabel Products oraz Categories oraz funkcji analitycznych stw�rz ranking najdro�szych
--(wg jednostkowej ceny) 5 produkt�w w danej kategorii. W przypadku produkt�w o tej samej warto�ci
--na ostatniej pozycji, uwzgl�dnij wszystkie z nich. Je�eli by� na poprzednich pozycjach to ka�dy
--z produkt�w jest zaliczany osobno. Wyniki posortuj wg kategorii (rosn�co) oraz miejsca w rankingu
--(rosn�co).

--przy pomocy CTE
WITH CTE
     AS (SELECT p.ProductID,
                p.ProductName,
                c.CategoryName,
                p.UnitPrice,
                Rank()
                  OVER (
                    PARTITION BY p.CategoryID
                    ORDER BY p.UnitPrice DESC) AS ranking
         FROM   Products p
                JOIN Categories c
                  ON c.CategoryID = p.CategoryID)
SELECT ProductID,
       ProductName,
       CategoryName,
       UnitPrice,
       ranking
FROM   CTE
WHERE  ranking <= 5
ORDER  BY CategoryName,
          ranking 

--przy pomocy podzapytania
SELECT ProductID,
       ProductName,
       CategoryName,
       UnitPrice,
       ranking
FROM   (SELECT p.ProductID,
               p.ProductName,
               c.CategoryName,
               p.UnitPrice,
               Rank()
                 OVER (
                   PARTITION BY p.CategoryID
                   ORDER BY p.UnitPrice DESC) AS ranking
        FROM   Products p
               JOIN Categories c
                 ON c.CategoryID = p.CategoryID) AS pod
WHERE  ranking <= 5
ORDER  BY CategoryName,
          ranking 

--Zadanie 11.
--Poni�sze zadanie, kt�re rozwi�zywali�my za pomoc� CTE, teraz spr�buj rozwi�za� z uwzgl�dnieniem
--funkcji analitycznych. W tym przypadku r�wnie� mo�esz (nie musisz!) wykorzysta� CTE.

--Korzystaj�c z tabel Products oraz Order Details wy�wietl wszystkie identyfikatory (Products.ProductID)
--i nazwy produkt�w (Products.ProductName), kt�rych maksymalna warto�� zam�wienia bez
--uwzgl�dnienia zni�ki (UnitPrice*Quantity) jest mniejsza od �redniej w danej kategorii. Inaczej m�wi�c
--� nie istnieje warto�� zam�wienia wi�ksza ni� �rednia warto�� zam�wienia w kategorii, do kt�rej nale�y
--dany Produkt.
--Wynik posortuj rosn�co wg identyfikatora produktu. 

--I spos�b (CTE):
WITH Agregaty
     AS (SELECT p.ProductID,
                p.ProductName,
                Max(od.UnitPrice * od.Quantity)
                  OVER (
                    PARTITION BY p.ProductID)  AS MaxVal,
                Avg(od.UnitPrice * od.Quantity)
                  OVER (
                    PARTITION BY p.CategoryID) AS AvgVal
         FROM   Products p
                INNER JOIN [Order Details] od
                        ON od.ProductID = p.ProductID)
SELECT DISTINCT ProductID,
                ProductName
FROM   Agregaty
WHERE  MaxVal < AvgVal
ORDER  BY ProductID 

-- II spos�b (podzapytanie):
SELECT DISTINCT ProductID,
                ProductName
FROM   (SELECT p.ProductID,
               p.ProductName,
               Max(od.UnitPrice * od.Quantity)
                 OVER (
                   PARTITION BY p.ProductID)  AS MaxVal,
               Avg(od.UnitPrice * od.Quantity)
                 OVER (
                   PARTITION BY p.CategoryID) AS AvgVal
        FROM   Products p
               INNER JOIN [Order Details] od
                       ON od.ProductID = p.ProductID) a
WHERE  a.MaxVal < a.AvgVal
ORDER  BY a.ProductID 

--Zadanie 12.
--Korzystaj�c z tabeli Products oraz Categories wy�wietl identyfikator produktu, kategori�, do kt�rej
--nale�y dany produkt, jednostkow� cen� oraz wyliczon� sum� bie��c� jednostkowej ceny produkt�w
--w dalej kategorii. Suma bie��ca, zdefiniowana jako suma wszystkich poprzedzaj�cych rekord�w (cen
--jednostkowych produkt�w), powinna by� wyliczona na zbiorze danych posortowanych po
--jednostkowej cenie produktu � rosn�co.
--Wynik posortuj rosn�co wg nazwy kategorii oraz jednostkowej ceny produktu.

SELECT	ProductID, 
		CategoryName, 
		UnitPrice,
		Sum(UnitPrice) OVER (
			PARTITION BY CategoryName
			ORDER BY UnitPrice
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunSum
FROM Products p 
JOIN Categories c ON c.CategoryID = p.CategoryID
ORDER BY CategoryName, UnitPrice

--Zadanie 13. (*)
--Rozbuduj poprzednie zapytanie o wyliczenie maksymalnej warto�ci ceny jednostkowej z okna
--obejmuj�cego 2 poprzednie wiersze i 2 nast�puj�ce po bie��cym. Dodatkowo wylicz �redni� krocz�c�
--z ceny jednostkowej sk�adaj�cej si� z okna obejmuj�cego 2 poprzednie rekordy oraz aktualny. Nie
--zmieniaj sortowania � wszystkie zbiory powinny by� uporz�dkowane rosn�co po cenie jednostkowej
--produktu.
--Wynik ko�cowy powinien by� posortowany rosn�co wg nazwy kategorii oraz jednostkowej ceny
--produktu.

SELECT	ProductID, 
		CategoryName, 
		UnitPrice,
		Sum(UnitPrice) OVER (
			PARTITION BY CategoryName
			ORDER BY UnitPrice
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunSum,
		Max(UnitPrice) OVER (
			PARTITION BY CategoryName
			ORDER BY UnitPrice
			ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS MaxUnitPrice,
		Round(Avg(UnitPrice) OVER (
			PARTITION BY CategoryName
			ORDER BY UnitPrice
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS MovAvg
FROM Products p 
JOIN Categories c ON c.CategoryID = p.CategoryID
ORDER BY CategoryName, UnitPrice

--Zadanie 14. (*)
--Aby zbada� jak kolejne produkty wp�ywaj� na �redni� krocz�c�, rozbuduj poprzednie zapytanie
--o wyliczon� r�nic� �rednich krocz�cych pomi�dzy aktualnym rekordem a rekordem poprzedzaj�cym.
--Pami�taj, aby wyliczenia by�y w obr�bie danej kategorii

WITH MovingAverage
AS
(
	SELECT	ProductID, 
			CategoryName, 
			UnitPrice,
			Sum(UnitPrice) OVER (
				PARTITION BY CategoryName
				ORDER BY UnitPrice
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunSum,
			Max(UnitPrice) OVER (
				PARTITION BY CategoryName
				ORDER BY UnitPrice
				ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS MaxUnitPrice,
			Round(Avg(UnitPrice) OVER (
				PARTITION BY CategoryName
				ORDER BY UnitPrice
				ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS MovAvg
	FROM Products p 
	JOIN Categories c ON c.CategoryID = p.CategoryID
)

SELECT	ProductID, 
		CategoryName, 
		UnitPrice,
		RunSum,
		MaxUnitPrice,
		MovAvg,
		MovAvg - Lag(MovAvg) OVER(
			PARTITION BY CategoryName
			ORDER BY UnitPrice) AS MovAvgDiff
FROM MovingAverage
ORDER BY CategoryName, UnitPrice

--Zadanie 15.
--W tym zadaniu om�wimy do�� cz�sty problem jakim jest usuwanie duplikat�w z tabeli.
--Jako, �e nasz model nie posiada tabeli z duplikatami, to na potrzeby �wiczenia musimy tak� tabel�
--stworzy�:

IF OBJECT_ID('dbo.MyCategories') IS NOT NULL DROP TABLE dbo.MyCategories;
SELECT * INTO dbo.MyCategories FROM dbo.Categories
UNION ALL
SELECT * FROM dbo.Categories
UNION ALL
SELECT * FROM dbo.Categories

--Wykorzystaj funkcje analityczne oraz polecenie/zestaw polece�, po wykonaniu kt�rych w tabeli
--MyCategories pozostanie jedynie unikalny zbi�r rekord�w. Za��, �e duplikaty mo�emy rozpozna� po warto�ci pola CategoryID (nie trzeba
--por�wnywa� wszystkich p�l w tabeli).

WITH Duplicates 
AS 
( 
	SELECT	CategoryID, 
			CategoryName, 
			Row_number() OVER (PARTITION BY CategoryID ORDER BY CategoryID) AS RowNum 
	FROM	MyCategories 
) 

DELETE FROM Duplicates 
WHERE RowNum != 1

SELECT Count(*) AS CNT
FROM dbo.MyCategories

 --Opcja 2: 
WITH DuplicatedRows  
AS 
( 
    SELECT	*,
			Row_number() OVER (PARTITION BY CategoryID ORDER BY CategoryID) AS RowNum 
	FROM    MyCategories 
) 

SELECT	CategoryID,
		CategoryName, 
		Description, 
		Picture  
INTO    MyCategoriesTmp 
FROM    DuplicatedRows 
WHERE   RowNum = 1;   

DROP TABLE MyCategories; 

EXEC sp_rename 'MyCategoriesTmp', 'MyCategories'

--Opcja 3: 
WITH DuplicatedRows3  
AS 
( 
    SELECT	Row_number() OVER (ORDER BY CategoryID) AS RowNum, 
            Rank() OVER (ORDER BY CategoryID) AS Rank 
    FROM    MyCategories 
) 

DELETE FROM DuplicatedRows3 
WHERE	RowNum != Rank  

SELECT  CategoryID, 
        Row_number() OVER (ORDER BY CategoryID) AS RowNum, 
        Rank() OVER (ORDER BY CategoryID) AS Rank 
FROM    MyCategories 

--Zadanie 16.
--Poj�cie Luki:
--Bior�c pod uwag� ci�g liczb lub ci�g czasowy (daty), luk� jest miejsce gdzie brakuje pewnych pozycji
--(liczba lub interwa� czasowy pomi�dzy kolejnymi elementami jest wi�kszy ni� w pozosta�ych
--przypadkach). 

--Korzystaj�c z tabeli Orders stw�rz zapytanie, kt�re pozwoli znale�� wszystkie luki (przedzia�y) w datach
--dostawy (ShippedDates), wi�ksze ni� 1 dzie� (poszukujemy luki wi�kszej lub r�wniej 1 dzie�). Nie
--uwzgl�dniaj warto�ci pustych (NULL). Wynik posortuj rosn�co po kolumnie reprezentuj�cej pocz�tek
--przedzia�u. W tym zadaniu nie przejmuj si� formatem daty.

--I spos�b (CTE)
WITH DatesCTE
AS
(
	SELECT	ShippedDate,
			Lead(ShippedDate) OVER (ORDER BY ShippedDate) AS NextDate
			FROM Orders
			WHERE ShippedDate IS NOT NULL
) 

SELECT	ShippedDate +1 AS RangeStart,
		NextDate -1 AS RangeEnd
FROM	DatesCTE
WHERE	ShippedDate +1 < NextDate

--II spos�b (Podzapytanie)
SELECT	Dateadd(day, 1, ShippedDate) AS RangeStart,
		Dateadd(day, -1, NextDate) AS RangeEnd
FROM (
	SELECT	ShippedDate,
			Lead(ShippedDate) OVER (ORDER BY ShippedDate) AS NextDate
			FROM Orders
			WHERE ShippedDate IS NOT NULL
	) c
WHERE Datediff(day, ShippedDate, NextDate) > 1;

--Zadanie 17. (*)
--W poprzednim zadaniu cz�� luk wynika�a z faktu, �e wysy�ki nie by�y realizowane w weekendy. Dodaj
--kolumny StartDayOfWeek oraz EndDayOfWeek, kt�re wy�wietl� dzie� tygodnia dla pocz�tku oraz
--ko�ca przedzia�u.

WITH DatesCTE
AS
(
	SELECT	ShippedDate,
			Lead(ShippedDate) OVER (ORDER BY ShippedDate) AS NextDate
			FROM Orders
			WHERE ShippedDate IS NOT NULL
) 

SELECT	ShippedDate +1 AS RangeStart,
		NextDate -1 AS RangeEnd,
		Datename(weekday, ShippedDate +1) AS StartDay,
		Datename(weekday, NextDate -1) AS EndDay
FROM	DatesCTE
WHERE	ShippedDate +1 < NextDate

--Zadanie 18. (*)
--Zaktualizuj poprzednie zapytanie tak, aby wy�wietlone zosta�y tylko luki trwaj�ce 4 dni oraz d�u�ej.	

WITH DatesCTE
AS
(
	SELECT	ShippedDate,
			Lead(ShippedDate) OVER (ORDER BY ShippedDate) AS NextDate
			FROM Orders
			WHERE ShippedDate IS NOT NULL
) 

SELECT	ShippedDate +1 AS RangeStart,
		NextDate -1 AS RangeEnd,
		Datename(weekday, ShippedDate +1) AS StartDay,
		Datename(weekday, NextDate -1) AS EndDay
FROM	DatesCTE
WHERE	Datediff(day, ShippedDate, NextDate) > 4
		
--Zadanie 19.
--poj�cie Wyspy:
--Wyspy w przeciwie�stwie do Luk s� przedzia�ami, w kt�rych nie brakuje �adnych warto�ci (nie ma luk).

--Korzystaj�c z tabeli Orders zaprojektuj zapytanie, kt�re zwr�ci wszystkie wyspy dla pola ShippedDate
--(nie uwzgl�dniaj warto�ci pustych). W tym zadaniu nie przejmuj si� formatem daty. Wynik posortuj
--zgodnie po kolumnie reprezentuj�cej pocz�tek przedzia�u.

WITH Wyspy
AS
(
	SELECT	ShippedDate,
			Dateadd(day, -1* DENSE_RANK() OVER (ORDER BY ShippedDate), ShippedDate) AS DateRank
	FROM Orders
	WHERE ShippedDate IS NOT NULL
)

SELECT	Min(ShippedDate) AS RangeStart,
		Max(ShippedDate) AS RangeEnd
FROM Wyspy
GROUP BY DateRank 
ORDER BY RangeStart