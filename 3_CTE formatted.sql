---------------------CTE--------------------------------------------------------------------------------------
--Zadanie 1.
--Korzystaj�c z tabeli Products wy�wietl wszystkie identyfikator produkt�w (ProductID) oraz nazwy
--(ProductName), kt�rych cena jednostkowa (UnitPrice) jest wi�ksza od �redniej w danej kategorii.
--Wynik posortuj wg ceny jednostkowej (UnitPrice).
--Zapytanie zrealizuj w dw�ch wariantach: bez oraz z uwzgl�dnieniem CTE.

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

--to samo zapytanie przy innym umiejscowieniu alias�w:
WITH AvgUnitPriceInCat --usun�am aliasy kol. CTE
     AS (SELECT Avg(UnitPrice) AS AvgUnitPrice,
                CategoryID --doda�am alias AvgUnitPrice
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
--Korzystaj�c z tabel Products oraz Order Details oraz konstrukcji CTE wy�wietl wszystkie identyfikatory
--(Products.ProductID) i nazwy produkt�w (Products.ProductName), kt�rych maksymalna warto��
--zam�wienia bez uwzgl�dnienia zni�ki (UnitPrice*Quantity) jest mniejsza od �redniej w danej kategorii.
--Inaczej m�wi�c � nie istnieje warto�� zam�wienia wi�ksza ni� �rednia warto�� zam�wienia w kategorii,
--do kt�rej nale�y dany Produkt.
--Wynik posortuj rosn�co wg identyfikatora produktu.

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
--Korzystaj�c z tabeli Employees wy�wietl identyfikator, imi� oraz nazwisko pracownika wraz
--z identyfikatorem, imieniem i nazwiskiem jego prze�o�onego. Do znalezienia prze�o�onego danego
--pracowania u�yj pola ReportsTo. Wy�wietl wyniki dla poziomu hierarchii nie wi�kszego ni� 1
--(zaczynaj�c od 0). Do wyniku dodaj kolumn� WhoIsThis, kt�ra przyjmie odpowiednie warto�ci dla
--danego poziomu:
--� Level = 0 � Krzysiu Jarzyna ze Szczecina
--� Level = 1 � Pan �abka

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
         WHEN 1 THEN 'Pan �abka'
       END AS WhoIsThis
FROM   EmployeeCTE
WHERE  Level < 2;

--Zadanie 4. (*)
--Rozbuduj poprzednie zapytanie tak, aby w kolumnie ReportsTo zamiast identyfikatora, pojawi�a si�
--warto�� z kolumny WhoIsThis prze�o�onego. Tym razem zaprezentuj wszystkie poziomy hierarchii. 
--Kolumna WhoIsThis dla poziomu Level=2 niech przyjmie warto�� - Re�yser kina akcji. W pierwszej
--kolejno�ci postaraj si� wykona� zadanie bez dodawania kolejnych podzapyta�

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
         WHEN 2 THEN 'Pan �abka'
       END AS ReportsTo,
       ManagerFirstName,
       ManagerlastName,
       Level,
       CASE Level
         WHEN 0 THEN 'Krzysiu Jarzyna ze Szczecina'
         WHEN 1 THEN 'Pan �abka'
         WHEN 2 THEN 'Re�yser kina akcji'
       END AS WhoIsThis
FROM   EmployeeCTE; 

-- II wersja rozwi�zania (r�ni si� dla kolumn WhoIsThis oraz ReportsTo):
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
                     WHEN 1 THEN 'Pan �abka'
                     WHEN 2 THEN 'Re�yser kina akcji'
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
--Wykorzystuj�c CTE i rekurencje, zbuduj zapytanie pozwalaj�ce przedstawi� ci�g Fibonacciego, kt�ry
--opisany jest wzorem (�r�d�o: https://pl.wikipedia.org/wiki/Ci%C4%85g_Fibonacciego):

WITH Fibo (N, FibValue, NextValue)
     AS (SELECT 0,0,1
         UNION ALL
         SELECT N + 1, NextValue, FibValue + NextValue
         FROM   Fibo
         WHERE  N < 10)
SELECT N, FibValue
FROM   Fibo 