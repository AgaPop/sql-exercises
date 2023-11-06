--Zadanie 1.
--Jak wiadomo, niekt�re zadania mo�na zrealizowa� zar�wno za pomoc� operatora JOIN jak i APPLY.

SELECT P.ProductID, P.ProductName, S.CompanyName
FROM Products P JOIN Suppliers S
ON P.SupplierID = S.SupplierID
ORDER BY ProductID

--Zaktualizuj powy�sze zapytanie tak, aby zamiast operatora JOIN wykorzysta� operator APPLY.
--Zapytanie powinno zwr�ci� taki sam wynik.
--Dodatkowo napisz zapytanie, kt�re wy�wietli rekordy, o kt�re zapytania si� r�ni�.

--wersja z APPLY:
SELECT P.ProductID, P.ProductName, S.CompanyName
FROM Products P 
CROSS APPLY 
(
	SELECT a.CompanyName
	FROM Suppliers a
	WHERE P.SupplierID = a.SupplierID
) AS S
ORDER BY ProductID

--por�wnanie rezultat�w:
(SELECT P.ProductID, P.ProductName, S.CompanyName
FROM Products P JOIN Suppliers S
ON P.SupplierID = S.SupplierID
EXCEPT
SELECT P.ProductID, P.ProductName, S.CompanyName
FROM Products P 
CROSS APPLY 
(
	SELECT a.CompanyName
	FROM Suppliers a
	WHERE P.SupplierID = a.SupplierID
) AS S)
UNION ALL
(SELECT P.ProductID, P.ProductName, S.CompanyName
FROM Products P 
CROSS APPLY 
(
	SELECT a.CompanyName
	FROM Suppliers a
	WHERE P.SupplierID = a.SupplierID
) AS S
EXCEPT
SELECT P.ProductID, P.ProductName, S.CompanyName
FROM Products P JOIN Suppliers S
ON P.SupplierID = S.SupplierID)
-- wniosek: puste czyli ok - brak r�nic w wynikach.

--Zadanie 2.
--W tym zadaniu wykorzystamy wcze�niej utworzon� funkcj� employeeInfo. 
--Korzystaj�c z tabeli Orders oraz funkcji employeeInfo wy�wietl identyfikator zam�wienia, identyfikator
--klienta, dat� zam�wienia (nie przejmuj si� formatowaniem daty) oraz dane pracownika obs�uguj�cego
--zam�wienie (funkcja: employeeInfo: FirstName, LastName).
--Wynik posortuj zgodnie z identyfikatorem zam�wienia

IF OBJECT_ID (N'dbo.employeeInfo', N'IF') IS NOT NULL
	DROP FUNCTION dbo.employeeInfo;
GO 
--tworzenie funkcji
CREATE FUNCTION dbo.employeeInfo(@OrderID INT)
RETURNS TABLE
AS
RETURN(
	SELECT	e.FirstName, 
			e.LastName, 
			e.Address
	FROM Employees e 
	JOIN Orders o ON e.EmployeeID = o.EmployeeID
	WHERE o.OrderID = @OrderID
)
GO

SELECT	o.OrderID, 
		o.CustomerID, 
		o.OrderDate, 
		e.FirstName, 
		e.LastName
FROM Orders o
OUTER APPLY dbo.employeeInfo(o.OrderID) AS e
ORDER BY o.OrderID

--Zadanie 3. (*)
--Zaimplementuj funkcj� customerInfo, kt�ra b�dzie podobna do funkcji employeeInfo, z t� r�nic�, �e
--b�dzie wraca�a dane klienta: CompanyName, ContactName, Address.

IF OBJECT_ID (N'dbo.customerInfo', N'IF') IS NOT NULL
	DROP FUNCTION dbo.customerInfo;
GO 
--tworzenie funkcji
CREATE FUNCTION dbo.customerInfo(@OrderID INT)
RETURNS TABLE
AS
RETURN(
	SELECT	c.CompanyName,
			c.ContactName,
			c.Address
	FROM Customers c
	JOIN Orders o ON c.CustomerID = o.CustomerID
	WHERE o.OrderID = @OrderID
)
GO

SELECT * FROM dbo.customerInfo(10248)
UNION ALL
SELECT * FROM dbo.customerInfo(NULL)
UNION ALL
SELECT * FROM dbo.customerInfo(0)

--Zadanie 4.(*)
--Zaktualizuj zapytanie z zadania 2. dodaj�c dane klienta: CompanyName, Contact, Address(wykorzystaj
--funkcj� customerInfo).

SELECT	o.OrderID, 
		o.CustomerID, 
		o.OrderDate, 
		e.FirstName AS EmpFirstName, 
		e.LastName AS EmpLastName,
		c.CompanyName AS Customer,
		c.ContactName AS CustContactName,
		c.Address AS CustAddress
FROM Orders o
OUTER APPLY dbo.employeeInfo(o.OrderID) AS e
OUTER APPLY dbo.customerInfo(o.OrderID) AS c
ORDER BY o.OrderID

--Zadanie 5.
--Korzystaj�c z tabeli Orders, Order Details oraz Employees oraz operatora OUTER APPLY (po��czenie
--zewn�trzne) wy�wietl imi�, nazwisko, miasto, region pracownika oraz sum� zam�wie� przez niego
--obs�u�onych (uwzgl�dniaj�c zni�k�!). Wynik posortuj malej�co po warto�ci zam�wie�.

--I rozwi�zanie -przy pomocy CTE:
WITH 
ValueOfOrders 
AS
(
	SELECT o.EmployeeID, SUM((od.UnitPrice * od.Quantity)*(1-od.Discount)) AS ValueOfOrders
	FROM [Order Details] od 
	JOIN Orders o ON o.OrderID = od.OrderID
	GROUP BY o.EmployeeID
)
SELECT e.FirstName, e.LastName, e.City, e.Region, ROUND(v.ValueOfOrders,2) AS ValueOfOrders
FROM Employees e 
JOIN ValueOfOrders v ON e.EmployeeID = v.EmployeeID
ORDER BY v.ValueOfOrders DESC

--II rozwi�zanie - z OUTER APPLY:
SELECT e.FirstName, e.LastName, e.City, e.Region, v.ValueOfOrders
FROM Employees e 
OUTER APPLY
(
	SELECT o.EmployeeID, SUM((od.UnitPrice * od.Quantity)*(1-od.Discount)) AS ValueOfOrders
	FROM [Order Details] od 
	JOIN Orders o ON o.OrderID = od.OrderID
	WHERE o.EmployeeID = e.EmployeeID
	GROUP BY o.EmployeeID
) AS v
ORDER BY v.ValueOfOrders DESC