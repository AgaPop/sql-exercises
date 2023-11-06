--Zadanie 1.
--Zaprojektuj funkcję orderValue, która korzystając z tabeli Order Details dla danego identyfikatora
--zamówienia zwróci wartość danego zamówienia (bez uwzględnienia zniżki). W przypadku gdy podane
--zamówienie nie istnieje, to funkcja powinna zwrócić 0,00.

-- sprawdzam na poczatku czy taka funkcja istnieje i jesli tak to usuwam
IF OBJECT_ID (N'dbo.orderValue', N'FN') IS NOT NULL
	DROP FUNCTION dbo.orderValue;
GO-- wysylam do serwera ten kawalek zapytania
--tworzenie funkcji
CREATE FUNCTION	dbo.orderValue(@OrderID INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @value MONEY;

	SELECT @value = sum(od.UnitPrice * od.Quantity)
	FROM [Order Details] od
	WHERE od.OrderID = @OrderID;

	IF @value IS NULL
		SET @value = 0;
	RETURN @value;
END;
GO
--wywolanie tej funkcji:
SELECT dbo.orderValue(NULL) AS OrderAmt
SELECT dbo.orderValue(10259) AS OrderAmt
SELECT dbo.orderValue(1111111) AS OrderAmt

--Zadanie 2.(*)
--Korzystając z tabeli Orders i funkcji stworzonej w poprzednim zapytaniu, zaprojektuj zapytanie, które
--zwróci identyfikator zamówienia, identyfikator klienta, datę zamówienia oraz wartość zamówienia.
--Wynik posortuj po identyfikatorze zamówienia (rosnąco).

SELECT	OrderID, 
		CustomerID, 
		OrderDate, 
		dbo.orderValue(OrderID) AS OrderAmt
FROM Orders 
ORDER BY OrderID

--Zadanie 3.
--Korzystając z tabel Orders oraz Employees zaprojektuj funkcję employeeInfo, która dla podanego
--OrderID (parametr) zwróci imię, nazwisko oraz adres pracownika realizującego dane zamówienie.
--Jeżeli podany numer zamówienia nie istnieje, funkcja nie powinna zwracać żadnego rekordu.

-- sprawdzam na poczatku czy taka funkcja istnieje i jesli tak to usuwam
IF OBJECT_ID (N'dbo.employeeInfo', N'IF') IS NOT NULL
	DROP FUNCTION dbo.employeeInfo;
GO -- wysylam do serwera ten kawalek zapytania
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
--wywolanie tej funkcji:
SELECT FirstName, LastName, Address
FROM dbo.employeeInfo(10249)
UNION ALL
SELECT FirstName, LastName, Address
FROM dbo.employeeInfo(98753435)
UNION ALL
SELECT FirstName, LastName, Address FROM dbo.employeeInfo(NULL)
UNION ALL
SELECT FirstName, LastName, Address FROM dbo.employeeInfo(0)

--Zadanie 4.
--Korzystając z tabel Orders oraz Employees zaprojektuj funkcję employeeInfoExt, która dla podanego
--OrderID (parametr) zwróci imię, nazwisko, adres pracownika oraz dodatkową kolumnę z uwagami
--(Comments). Jeżeli identyfikator zamówienia istnieje w bazie danych to funkcja powinna zwrócić dane
--pracownika. Jeżeli podany identyfikator nie istnieje w bazie danych lub ma wartość NULL to funkcja
--powinna zwrócić wartość NULL w kolumnach dotyczących danych pracownika. Kolumna Comments
--powinna przyjąć następujące wartości:
-- - Dla istniejącego OrderID: „OrderID: @OrderID”
-- - Dla OrderID – NULL: „Really? NULL ?!”
-- - Dla nieistniejącego OrderID w bazie danych: “There is no such an OrderID”

IF OBJECT_ID (N'dbo.employeeInfoExt', N'TF') IS NOT NULL
	DROP FUNCTION dbo.employeeInfoExt;
GO
CREATE FUNCTION dbo.employeeInfoExt(@OrderID INT)
RETURNS @result TABLE
(
	FirstName NVARCHAR(20), 
	LastName NVARCHAR(10), 
	Address NVARCHAR(60), 
	Comments NVARCHAR(100) 	
)
AS
BEGIN
	DECLARE @test SMALLINT;   

	IF (@OrderID IS NULL)
		INSERT INTO @result (Comments) 
		SELECT 'Really? NULL ?!' 
	ELSE
		BEGIN
			SELECT @test = 1
			FROM Orders
			WHERE OrderID = @OrderID;

			IF (@test = 1)
				INSERT INTO @result (FirstName, LastName, Address, Comments) 	
				SELECT  e.FirstName, e.LastName, e.Address, 'OrderID: ' + CAST(@OrderID AS NVARCHAR(10)) 
				FROM Employees e
				JOIN Orders o ON o.EmployeeID = e.EmployeeID
				WHERE o.OrderID = @OrderID
			ELSE 
				INSERT INTO @result(Comments)
				SELECT 'There is no such an OrderID'
		END
RETURN
END
GO
--wywołanie funkcji:
SELECT FirstName, LastName, Address, Comments FROM dbo.employeeInfoExt(10249) 
UNION ALL 
SELECT FirstName, LastName, Address, Comments FROM dbo.employeeInfoExt(NULL) 
UNION ALL 
SELECT FirstName, LastName, Address, Comments FROM dbo.employeeInfoExt(0) 

--Zadanie 5.
--Zaimplementuj funkcję stringsConcat, która przyjmie 3 parametry:
-- String1 typu NVARCHAR(100)
-- String2 typu NVARCHAR(100)
-- Separator typu NVARCHAR(10)
--Rezultatem funkcji będzie konkatenacja (złączenie) dwóch pierwszych parametrów z uwzględnieniem
--separatora pomiędzy nimi (parametr 3.).

IF OBJECT_ID (N'dbo.stringsConcat', N'FN') IS NOT NULL
	DROP FUNCTION dbo.stringsConcat;
GO
CREATE FUNCTION dbo.stringsConcat(@String1 NVARCHAR(100), @String2 NVARCHAR(100), @Separator NVARCHAR(10))
RETURNS NVARCHAR(210)
AS
BEGIN
	DECLARE @txt NVARCHAR(210);
	SET @txt = CONCAT(@String1, @Separator, @String2) --alternatywnie: SET @txt = @String1 +@Separator+ @String2;
	RETURN @txt;
END;
GO
--wywołanie funkcji
SELECT dbo.stringsConcat('Ala ma', 'kota', ' ') AS Result
UNION ALL
SELECT dbo.stringsConcat('Ten znak: ', ' to jest myślnik', '-') AS Result
UNION ALL
SELECT dbo.stringsConcat('Więcej: ', ' myślników', '---') AS Result
UNION ALL
SELECT dbo.stringsConcat('NULL', 'NULL', ' != ') AS Result
UNION ALL
SELECT dbo.stringsConcat('Prawdziwy NULL', NULL, ': ') AS Result

--Zadanie 6. (*)
--Zaktualizuj utworzoną funkcję, tak, aby w przypadku, gdy dwa pierwsze parametry (łańcuchy znaków
--do złączenia) mają wartość NULL, na wyjściu powinien zostać zwrócony wynik: Serio? NULLe?

IF OBJECT_ID (N'dbo.stringsConcat', N'FN') IS NOT NULL
	DROP FUNCTION dbo.stringsConcat;
GO
CREATE FUNCTION dbo.stringsConcat(@String1 NVARCHAR(100), @String2 NVARCHAR(100), @Separator NVARCHAR(10))
RETURNS NVARCHAR(210)
AS
BEGIN
	DECLARE @txt NVARCHAR(210);
	IF (@String1 IS NULL AND @String2 IS NULL)
		SET @txt = 'Serio? NULLe?'
	ELSE
		SET @txt = CONCAT(@String1, @Separator, @String2) --alternatywnie: SET @txt = @String1 +@Separator+ @String2;
		RETURN @txt;
END;
GO

--wywołanie funkcji:
SELECT dbo.stringsConcat('Prawdziwy NULL', NULL, ': ') AS Result
UNION ALL
SELECT dbo.stringsConcat(NULL, NULL, NULL) AS Result

--Zadanie 7.(*)
--Korzystając z tabeli Employees oraz poprzednio utworzonej funkcji do łączenia łańcuchów znaków,
--napisz zapytanie, które zwróci w jednej kolumnie konkatenacje 3 pól: FirstName, LastName, Title w
--postaci:
--FirstName (spacja) LastName (,spacja) Title.
--Konkatenacja powinna być wykonana jedynie przy użyciu funkcji (bez dodatkowych złączeń na
--poziomie SQL).

SELECT dbo.stringsConcat(dbo.stringsConcat(FirstName, LastName, ' '), Title, ', ') 
FROM Employees 

--Zadanie dodatkowe - Silnia:

CREATE FUNCTION dbo.factorial(@N INT)
RETURNS BIGINT
AS
BEGIN
	DECLARE @factorial BIGINT;
	IF @N = 1
		SET @factorial = 1
	ELSE
		SET @factorial = @N * dbo.factorial(@N-1)
	RETURN @factorial;
END
GO
--wywołanie:
SELECT dbo.factorial(5) AS Factorial

--Zadanie 8.
--Zaimplementuj funkcję fibonacci, które dla podanego N, zwróci N-ty wyraz ciągu Fibonacciego
--opisanego wzorem (źródło: https://pl.wikipedia.org/wiki/Ci%C4%85g_Fibonacciego)

CREATE FUNCTION dbo.fibonacci(@N INT)
RETURNS BIGINT
AS
BEGIN
	DECLARE @fibo BIGINT;
	IF @N = 0 
		SET @fibo = 0
	ELSE 
		IF @N = 1
			SET @fibo = 1
		ELSE 
			SET @fibo = dbo.fibonacci(@N-1) + dbo.fibonacci(@N-2)
	RETURN @fibo;
END
GO
--wywołanie:
SELECT dbo.fibonacci(10) AS Fibo
SELECT dbo.fibonacci(19) AS Fibo
