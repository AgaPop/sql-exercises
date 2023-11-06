---------------------CTE--------------------------------------------------------------------------------------
--Zadanie 1.
--Korzystaj¹c z tabeli Products wyœwietl wszystkie identyfikator produktów (ProductID) oraz nazwy
--(ProductName), których cena jednostkowa (UnitPrice) jest wiêksza od œredniej w danej kategorii.
--Wynik posortuj wg ceny jednostkowej (UnitPrice).
--Zapytanie zrealizuj w dwóch wariantach: bez oraz z uwzglêdnieniem CTE.

--------------------------without CTE:
--a) zapytanie w where
SELECT p.ProductID,
       p.ProductName
FROM   Products p
WHERE  UnitPrice > (SELECT Avg (UnitPrice)
                    FROM   Products a
                    WHERE  p.CategoryID = a.CategoryID)
ORDER  BY UnitPrice 

--b) Tabela pochodna
SELECT ProductID,
       ProductName
FROM   Products p
       JOIN (SELECT Avg(UnitPrice) AS AvgUnitPrice,
                    CategoryID
             FROM   Products
             GROUP  BY CategoryID) AS a
         ON a.CategoryID = p.CategoryID
WHERE  UnitPrice > a.AvgUnitPrice
ORDER  BY UnitPrice 

--------------------------using CTE:
WITH AvgUnitPriceInCat (AvgUnitPrice, CategoryID)
     AS (SELECT Avg(UnitPrice),
                CategoryID
         FROM   Products
         GROUP  BY CategoryID)
SELECT ProductID,
       ProductName
FROM   Products p
WHERE  UnitPrice > (SELECT AvgUnitPrice
                    FROM   AvgUnitPriceInCat a
                    WHERE  a.CategoryID = p.CategoryID)
ORDER  BY UnitPrice 

--to samo zapytanie przy innym umiejscowieniu aliasów:
WITH AvgUnitPriceInCat --usunê³am aliasy kol. CTE
     AS (SELECT Avg(UnitPrice) AS AvgUnitPrice,
                CategoryID --doda³am alias AvgUnitPrice
         FROM   Products
         GROUP  BY CategoryID)
SELECT ProductID,
       ProductName
FROM   Products p
WHERE  UnitPrice > (SELECT AvgUnitPrice
                    FROM   AvgUnitPriceInCat a
                    WHERE  a.CategoryID = p.CategoryID)
ORDER  BY UnitPrice 

--druga wersja z CTE:
WITH AvgUnitPriceInCat
     AS (SELECT Avg(UnitPrice) AS AvgUnitPrice,
                CategoryID
         FROM   Products
         GROUP  BY CategoryID)
SELECT ProductID,
       ProductName
FROM   Products p
       JOIN AvgUnitPriceInCat a
         ON a.CategoryID = p.CategoryID
WHERE  p.UnitPrice > a.AvgUnitPrice
ORDER  BY p.UnitPrice 

--Zadanie 2.
--Korzystaj¹c z tabel Products oraz Order Details oraz konstrukcji CTE wyœwietl wszystkie identyfikatory
--(Products.ProductID) i nazwy produktów (Products.ProductName), których maksymalna wartoœæ
--zamówienia bez uwzglêdnienia zni¿ki (UnitPrice*Quantity) jest mniejsza od œredniej w danej kategorii.
--Inaczej mówi¹c – nie istnieje wartoœæ zamówienia wiêksza ni¿ œrednia wartoœæ zamówienia w kategorii,
--do której nale¿y dany Produkt.
--Wynik posortuj rosn¹co wg identyfikatora produktu.

WITH 
AvgVal AS
(
         SELECT   Avg(od.UnitPrice*od.Quantity) AS AvgVal,
                  CategoryID
         FROM     [Order Details] od
         JOIN     Products p
         ON       p.ProductID = od.ProductID
         GROUP BY CategoryID ), 
MaxVal AS
(
         SELECT   Max(UnitPrice*Quantity) AS MaxVal,
                  ProductID
         FROM     [Order Details]
         GROUP BY ProductID )

SELECT p.ProductID,
       p.ProductName
FROM   Products p
       JOIN MaxVal m
         ON p.ProductID = m.ProductID
       JOIN AvgVal a
         ON a.CategoryID = p.CategoryID
WHERE  m.MaxVal < a.AvgVal
ORDER  BY ProductID 

--Zadanie 3.
--Korzystaj¹c z tabeli Employees wyœwietl identyfikator, imiê oraz nazwisko pracownika wraz
--z identyfikatorem, imieniem i nazwiskiem jego prze³o¿onego. Do znalezienia prze³o¿onego danego
--pracowania u¿yj pola ReportsTo. Wyœwietl wyniki dla poziomu hierarchii nie wiêkszego ni¿ 1
--(zaczynaj¹c od 0). Do wyniku dodaj kolumnê WhoIsThis, która przyjmie odpowiednie wartoœci dla
--danego poziomu:
--• Level = 0 – Krzysiu Jarzyna ze Szczecina
--• Level = 1 – Pan ¯abka

WITH EmployeeCTE AS
(
       SELECT EmployeeID,
              FirstName,
              LastName,
              ReportsTo,
              Cast(NULL AS nvarchar(10)) AS ManagerFirstName,
              Cast(NULL AS nvarchar(20)) AS ManagerlastName,
              0                          AS Level
       FROM   Employees
       WHERE  ReportsTo IS NULL
       UNION ALL
       SELECT e.EmployeeID,
              e.FirstName,
              e.LastName,
              cte.EmployeeID,
              cte.FirstName,
              cte.LastName,
              Level + 1
       FROM   Employees e
       JOIN   EmployeeCTE cte
       ON     e.ReportsTo = cte.EmployeeID )

SELECT EmployeeID,
       FirstName,
       LastName,
       EmployeeID,
       ReportsTo,
       ManagerFirstName,
       ManagerlastName,
       Level,
       CASE Level
         WHEN 0 THEN 'Krzysiu Jarzyna ze Szczecina'
         WHEN 1 THEN 'Pan ¯abka'
       END AS WhoIsThis
FROM   EmployeeCTE
WHERE  Level < 2;

--Zadanie 4. (*)
--Rozbuduj poprzednie zapytanie tak, aby w kolumnie ReportsTo zamiast identyfikatora, pojawi³a siê
--wartoœæ z kolumny WhoIsThis prze³o¿onego. Tym razem zaprezentuj wszystkie poziomy hierarchii. 
--Kolumna WhoIsThis dla poziomu Level=2 niech przyjmie wartoœæ - Re¿yser kina akcji. W pierwszej
--kolejnoœci postaraj siê wykonaæ zadanie bez dodawania kolejnych podzapytañ

WITH EmployeeCTE AS
(
       SELECT EmployeeID,
              FirstName,
              LastName,
              ReportsTo,
              Cast(NULL AS nvarchar(10)) AS ManagerFirstName,
              Cast(NULL AS nvarchar(20)) AS ManagerlastName,
              0                          AS Level
       FROM   Employees
       WHERE  ReportsTo IS NULL
       UNION ALL
       SELECT e.EmployeeID,
              e.FirstName,
              e.LastName,
              cte.EmployeeID,
              cte.FirstName,
              cte.LastName,
              Level + 1
       FROM   Employees e
       JOIN   EmployeeCTE cte
       ON     e.ReportsTo = cte.EmployeeID )

SELECT EmployeeID,
       FirstName,
       LastName,
       EmployeeID,
       CASE Level
         WHEN 0 THEN NULL
         WHEN 1 THEN 'Krzysiu Jarzyna ze Szczecina'
         WHEN 2 THEN 'Pan ¯abka'
       END AS ReportsTo,
       ManagerFirstName,
       ManagerlastName,
       Level,
       CASE Level
         WHEN 0 THEN 'Krzysiu Jarzyna ze Szczecina'
         WHEN 1 THEN 'Pan ¯abka'
         WHEN 2 THEN 'Re¿yser kina akcji'
       END AS WhoIsThis
FROM   EmployeeCTE; 

-- II wersja rozwi¹zania (ró¿ni siê dla kolumn WhoIsThis oraz ReportsTo):
WITH NewCTE AS
(
       SELECT EmployeeID,
              FirstName,
              LastName,
              Cast(NULL AS nvarchar(100)) AS ReportsTo,
              Cast(NULL AS nvarchar(10))  AS ManagerFirstName,
              Cast(NULL AS nvarchar(20))  AS ManagerlastName,
              0                           AS Level,
              Cast('Krzysiu Jarzyna ze Szczecina' AS nvarchar(100)) AS WhoIsThis
       FROM   Employees
       WHERE  ReportsTo IS NULL
       UNION ALL
       SELECT e.EmployeeID,
              e.FirstName,
              e.LastName,
              Cast(ct.WhoIsThis AS nvarchar(100)),
              ct.FirstName,
              ct.LastName,
              Level + 1,
              Cast(
              CASE Level + 1
                     WHEN 1 THEN 'Pan ¯abka'
                     WHEN 2 THEN 'Re¿yser kina akcji'
              END AS nvarchar(100)) AS WhoIsThis
       FROM   Employees e
       JOIN   NewCTE ct
       ON     e.ReportsTo = ct.EmployeeID )

SELECT EmployeeID,
       FirstName,
       LastName,
       EmployeeID,
       ReportsTo,
       ManagerFirstName,
       ManagerlastName,
       Level,
       WhoIsThis
FROM   NewCTE; 

--Zadanie 5. 
--Wykorzystuj¹c CTE i rekurencje, zbuduj zapytanie pozwalaj¹ce przedstawiæ ci¹g Fibonacciego, który
--opisany jest wzorem (Ÿród³o: https://pl.wikipedia.org/wiki/Ci%C4%85g_Fibonacciego):

WITH Fibo (N, FibValue, NextValue)
     AS (SELECT 0,0,1
         UNION ALL
         SELECT N + 1, NextValue, FibValue + NextValue
         FROM   Fibo
         WHERE  N < 10)
SELECT N, FibValue
FROM   Fibo 