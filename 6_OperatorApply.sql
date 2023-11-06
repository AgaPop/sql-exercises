--Zadanie 1.
--Jak wiadomo, niektóre zadania mo¿na zrealizowaæ zarówno za pomoc¹ operatora JOIN jak i APPLY.

SELECT P.ProductID, P.ProductName, S.CompanyName
FROM Products P JOIN Suppliers S
ON P.SupplierID = S.SupplierID
ORDER BY ProductID

--Zaktualizuj powy¿sze zapytanie tak, aby zamiast operatora JOIN wykorzystaæ operator APPLY.
--Zapytanie powinno zwróciæ taki sam wynik.
--Dodatkowo napisz zapytanie, które wyœwietli rekordy, o które zapytania siê ró¿ni¹.

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

--porównanie rezultatów:
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
-- wniosek: puste czyli ok - brak ró¿nic w wynikach.

--Zadanie 2.
--W tym zadaniu wykorzystamy wczeœniej utworzon¹ funkcjê employeeInfo. 
--Korzystaj¹c z tabeli Orders oraz funkcji employeeInfo wyœwietl identyfikator zamówienia, identyfikator
--klienta, datê zamówienia (nie przejmuj siê formatowaniem daty) oraz dane pracownika obs³uguj¹cego
--zamówienie (funkcja: employeeInfo: FirstName, LastName).
--Wynik posortuj zgodnie z identyfikatorem zamówienia

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
--Zaimplementuj funkcjê customerInfo, która bêdzie podobna do funkcji employeeInfo, z t¹ ró¿nic¹, ¿e
--bêdzie wraca³a dane klienta: CompanyName, ContactName, Address.

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
--Zaktualizuj zapytanie z zadania 2. dodaj¹c dane klienta: CompanyName, Contact, Address(wykorzystaj
--funkcjê customerInfo).

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
--Korzystaj¹c z tabeli Orders, Order Details oraz Employees oraz operatora OUTER APPLY (po³¹czenie
--zewnêtrzne) wyœwietl imiê, nazwisko, miasto, region pracownika oraz sumê zamówieñ przez niego
--obs³u¿onych (uwzglêdniaj¹c zni¿kê!). Wynik posortuj malej¹co po wartoœci zamówieñ.

--I rozwi¹zanie -przy pomocy CTE:
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

--II rozwi¹zanie - z OUTER APPLY:
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