--Zadanie 1.
--Korzystaj¹c tabeli Products zaprojektuj zapytanie, które zwróci œredni¹ jednostkow¹ cenê wszystkich
--produktów. Wynik zaokr¹glij do dwóch miejsc po przecinku.

SELECT Round(Avg(UnitPrice), 2) AS AvgUnitPrice
FROM   Products 

--Zadanie 2.
--Korzystaj¹c z tabel Products oraz Categories, zaprojektuj zapytanie, które zwróci nazwê kategorii oraz
--œredni¹ jednostkow¹ cenê produktów w danej kategorii. Œredni¹ zaokr¹glij do dwóch miejsc po
--przecinku. Wynik posortuj alfabetycznie po nazwie kategorii. 

SELECT c.CategoryName,
       Round(Avg(p.UnitPrice), 2) AS AvgUnitPrice
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
GROUP  BY c.CategoryName 

--Zadanie 3.
--Korzystaj¹c z tabel Products oraz Categories zaprojektuj zapytanie, które zwróci wszystkie produkty
--(ProductName) wraz z kategoriami, do których nale¿¹ (CategoryName) oraz œredni¹ jednostkow¹ cenê
--dla wszystkich produktów. Analiza powinna obejmowaæ produkty ze wszystkich kategorii z wyj¹tkiem
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
--Rozbuduj poprzednie zapytanie o minimaln¹ i maksymaln¹ jednostkow¹ cenê dla wszystkich
--produktów. Tym razem interesuj¹ nas wszystkie produkty (usuñ ograniczenie na kategoriê).

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
--Rozbuduj poprzednie zapytanie o œredni¹ jednostkow¹ cenê w kategorii i dla danego dostawcy.

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
--Rozbuduj poprzednie zapytanie o liczbê produktów w danej kategorii.

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
--Korzystaj¹c z tabeli Orders oraz Customers przygotuj zapytanie, które wyœwietli identyfikator
--zamówienie (OrderID), nazwê klienta (CompanyName) oraz numer rekordu. Numeracja rekordów
--powinna byæ zgodna z dat¹ zamówienia posortowan¹ rosn¹co. Wyniki posortuj zgodnie
--z identyfikatorem zamówienia (rosn¹co).

SELECT o.OrderID,
       c.CompanyName,
       Row_number()
         OVER (
           ORDER BY o.orderdate) AS rowNum
FROM   Orders o
       JOIN Customers c
         ON o.CustomerID = c.CustomerID
ORDER  BY o.OrderID 

--II z wykorzystaniem f. agreguj¹cych:

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
--Zaktualizuj poprzednie zapytanie tak, aby wynik zosta³ posortowany w pierwszej kolejnoœci po nazwie
--klienta (rosn¹ca), a w drugiej po dacie zamówienia (malej¹co).

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
--Jak widaæ sortowanie w funkcji analitycznej oraz sortowanie ca³ego wyniku dzia³a niezale¿nie.

--Zadanie 9. - Stronicowanie
--Korzystaj¹c z tabel Products oraz Categories, zaprojektuj zapytanie uwzglêdniaj¹ce stronicowanie
--(wyznaczone rosn¹co po identyfikatorze produktu), które pozwoli wyœwietliæ zadan¹ stronê
--zawieraj¹c¹ informacje o produktach: identyfikator, nazwa produktu, nazwa kategorii, jednostokowa
--cena produktu, œrednia jednostkowa cena produktu w danej kategorii oraz numer strony (numer 
--wiersza nie powinien byæ wyœwietlony). Wielkoœæ strony oraz jej numer powinny byæ
--parametryzowalne. Wynik (ju¿ po uwzglêdnieniu stronicowania!) powinien zostaæ posortowany po
--nazwie produktu (alfabetycznie, rosn¹co).

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
--Korzystaj¹c z tabel Products oraz Categories oraz funkcji analitycznych stwórz ranking najdro¿szych
--(wg jednostkowej ceny) 5 produktów w danej kategorii. W przypadku produktów o tej samej wartoœci
--na ostatniej pozycji, uwzglêdnij wszystkie z nich. Je¿eli by³ na poprzednich pozycjach to ka¿dy
--z produktów jest zaliczany osobno. Wyniki posortuj wg kategorii (rosn¹co) oraz miejsca w rankingu
--(rosn¹co).

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
--Poni¿sze zadanie, które rozwi¹zywaliœmy za pomoc¹ CTE, teraz spróbuj rozwi¹zaæ z uwzglêdnieniem
--funkcji analitycznych. W tym przypadku równie¿ mo¿esz (nie musisz!) wykorzystaæ CTE.

--Korzystaj¹c z tabel Products oraz Order Details wyœwietl wszystkie identyfikatory (Products.ProductID)
--i nazwy produktów (Products.ProductName), których maksymalna wartoœæ zamówienia bez
--uwzglêdnienia zni¿ki (UnitPrice*Quantity) jest mniejsza od œredniej w danej kategorii. Inaczej mówi¹c
--– nie istnieje wartoœæ zamówienia wiêksza ni¿ œrednia wartoœæ zamówienia w kategorii, do której nale¿y
--dany Produkt.
--Wynik posortuj rosn¹co wg identyfikatora produktu. 

--I sposób (CTE):
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

-- II sposób (podzapytanie):
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
--Korzystaj¹c z tabeli Products oraz Categories wyœwietl identyfikator produktu, kategoriê, do której
--nale¿y dany produkt, jednostkow¹ cenê oraz wyliczon¹ sumê bie¿¹c¹ jednostkowej ceny produktów
--w dalej kategorii. Suma bie¿¹ca, zdefiniowana jako suma wszystkich poprzedzaj¹cych rekordów (cen
--jednostkowych produktów), powinna byæ wyliczona na zbiorze danych posortowanych po
--jednostkowej cenie produktu – rosn¹co.
--Wynik posortuj rosn¹co wg nazwy kategorii oraz jednostkowej ceny produktu.

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
--Rozbuduj poprzednie zapytanie o wyliczenie maksymalnej wartoœci ceny jednostkowej z okna
--obejmuj¹cego 2 poprzednie wiersze i 2 nastêpuj¹ce po bie¿¹cym. Dodatkowo wylicz œredni¹ krocz¹c¹
--z ceny jednostkowej sk³adaj¹cej siê z okna obejmuj¹cego 2 poprzednie rekordy oraz aktualny. Nie
--zmieniaj sortowania – wszystkie zbiory powinny byæ uporz¹dkowane rosn¹co po cenie jednostkowej
--produktu.
--Wynik koñcowy powinien byæ posortowany rosn¹co wg nazwy kategorii oraz jednostkowej ceny
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
--Aby zbadaæ jak kolejne produkty wp³ywaj¹ na œredni¹ krocz¹c¹, rozbuduj poprzednie zapytanie
--o wyliczon¹ ró¿nicê œrednich krocz¹cych pomiêdzy aktualnym rekordem a rekordem poprzedzaj¹cym.
--Pamiêtaj, aby wyliczenia by³y w obrêbie danej kategorii

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
--W tym zadaniu omówimy doœæ czêsty problem jakim jest usuwanie duplikatów z tabeli.
--Jako, ¿e nasz model nie posiada tabeli z duplikatami, to na potrzeby æwiczenia musimy tak¹ tabelê
--stworzyæ:

IF OBJECT_ID('dbo.MyCategories') IS NOT NULL DROP TABLE dbo.MyCategories;
SELECT * INTO dbo.MyCategories FROM dbo.Categories
UNION ALL
SELECT * FROM dbo.Categories
UNION ALL
SELECT * FROM dbo.Categories

--Wykorzystaj funkcje analityczne oraz polecenie/zestaw poleceñ, po wykonaniu których w tabeli
--MyCategories pozostanie jedynie unikalny zbiór rekordów. Za³ó¿, ¿e duplikaty mo¿emy rozpoznaæ po wartoœci pola CategoryID (nie trzeba
--porównywaæ wszystkich pól w tabeli).

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
--Pojêcie Luki:
--Bior¹c pod uwagê ci¹g liczb lub ci¹g czasowy (daty), luk¹ jest miejsce gdzie brakuje pewnych pozycji
--(liczba lub interwa³ czasowy pomiêdzy kolejnymi elementami jest wiêkszy ni¿ w pozosta³ych
--przypadkach). 

--Korzystaj¹c z tabeli Orders stwórz zapytanie, które pozwoli znaleŸæ wszystkie luki (przedzia³y) w datach
--dostawy (ShippedDates), wiêksze ni¿ 1 dzieñ (poszukujemy luki wiêkszej lub równiej 1 dzieñ). Nie
--uwzglêdniaj wartoœci pustych (NULL). Wynik posortuj rosn¹co po kolumnie reprezentuj¹cej pocz¹tek
--przedzia³u. W tym zadaniu nie przejmuj siê formatem daty.

--I sposób (CTE)
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

--II sposób (Podzapytanie)
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
--W poprzednim zadaniu czêœæ luk wynika³a z faktu, ¿e wysy³ki nie by³y realizowane w weekendy. Dodaj
--kolumny StartDayOfWeek oraz EndDayOfWeek, które wyœwietl¹ dzieñ tygodnia dla pocz¹tku oraz
--koñca przedzia³u.

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
--Zaktualizuj poprzednie zapytanie tak, aby wyœwietlone zosta³y tylko luki trwaj¹ce 4 dni oraz d³u¿ej.	

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
--pojêcie Wyspy:
--Wyspy w przeciwieñstwie do Luk s¹ przedzia³ami, w których nie brakuje ¿adnych wartoœci (nie ma luk).

--Korzystaj¹c z tabeli Orders zaprojektuj zapytanie, które zwróci wszystkie wyspy dla pola ShippedDate
--(nie uwzglêdniaj wartoœci pustych). W tym zadaniu nie przejmuj siê formatem daty. Wynik posortuj
--zgodnie po kolumnie reprezentuj¹cej pocz¹tek przedzia³u.

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