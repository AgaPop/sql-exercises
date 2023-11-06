--Excercise 1.
--Using the Products and Categories table, display the product name (Products.ProductName) and
--name of the category (Categories.CategoryName) to which the products belong.
--Sort the result by product name (ascending).

SELECT p.ProductName,
       c.CategoryName
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
ORDER  BY ProductName; 

--Exercise 2. (*)
--Using the Suppliers table, extend the previous one to also present the supplier's name
--of a given product (CompanyName) – name the column SupplierName.
--Sort the result descending by the unit price of the product

SELECT p.ProductName,
       c.CategoryName,
       s.CompanyName AS SupplierName
FROM   Products p
       JOIN Categories c
         ON p.CategoryID = c.CategoryID
       JOIN Suppliers s
         ON s.SupplierID = p.SupplierID
ORDER  BY p.UnitPrice DESC; 

--Exercise 3.
--Using the Products table, display the product names (ProductName) WITH the highest unit price
--in a given category (UnitPrice).
--Sort the result by product name (ascending)

SELECT p.ProductName,
       p.UnitPrice
FROM   Products p
WHERE  UnitPrice = (SELECT Max(p2.UnitPrice)
                    FROM   Products p2
                    WHERE  p.CategoryID = p2.CategoryID --adding this condition was necessary to be correlated WITH an external query
                    GROUP  BY p2.CategoryID)
ORDER  BY p.ProductName; 

--Exercise 4.
--Using the Products table, display the names of products whose unit price is greater than
--all average product prices calculated for other categories (other than the one to which it belongs).
--Sort the result by unit price (descending).

SELECT p.ProductName
FROM   Products p
WHERE  p.UnitPrice > ALL (SELECT Avg(p2.UnitPrice)
                          FROM   Products p2
                          WHERE  p.CategoryID != p2.CategoryID
                          GROUP  BY p2.CategoryID)
ORDER  BY p.UnitPrice DESC; 

--Task 5. (*)
--Using the Order Details table, extend the previous query to display 
--the maximum number of ordered pieces (Quantity) of a given product in one order (in a given
--OrderID).

SELECT p.ProductName,
       (SELECT Max(o.Quantity)
        FROM   [Order Details] o
        WHERE  p.ProductID = o.ProductID
        GROUP  BY o.ProductID) --correlated query
FROM   Products p
WHERE  p.UnitPrice > ALL (SELECT Avg(p2.UnitPrice)
                          FROM   Products p2
                          WHERE  p.CategoryID != p2.CategoryID
                          GROUP  BY p2.CategoryID)
ORDER  BY p.UnitPrice DESC; 

--Task 6.
--Using the Products and Order Details tables, display the CategoryID and
--sum of all product order values in a given category ([Order Details].UnitPrice * [Order
--Details].Quantity) without discount. The result should only contain those categories for which
--the sum is greater than 200,000.
--Sort the result by the sum of order values (descending).

SELECT p.CategoryID,
       Sum(o.UnitPrice * o.Quantity) AS ValueOfOrders
FROM   [Products] p
       INNER JOIN [Order Details] o
               ON p.ProductID = o.ProductID
GROUP  BY p.CategoryID
HAVING Sum(o.UnitPrice * o.Quantity) > 200000--execution order does not allow using an alias 
ORDER  BY ValueOfOrders DESC 

--Task 7. (*)
--Using the Categories table, update the previous query to return its name except the category identifier

SELECT p.CategoryID,
       c.CategoryName,
       Sum(o.UnitPrice * o.Quantity) AS ValueOfOrders
FROM   [Products] p
       INNER JOIN [Order Details] o
               ON p.ProductID = o.ProductID
       INNER JOIN Categories c
               ON p.CategoryID = c.CategoryID
GROUP  BY p.CategoryID,
          c.CategoryName
HAVING Sum(o.UnitPrice * o.Quantity) > 200000
ORDER  BY ValueOfOrders DESC 

--The difference between EXISTS and IN:

SELECT Count(*)
FROM   Orders
WHERE  ShipRegion IN (SELECT ShipRegion
                      FROM   Orders
                      WHERE  CustomerID = 'HANAR'); 

SELECT Count(*)
FROM   Orders o
WHERE  EXISTS (SELECT 1
               FROM   Orders p
               WHERE  p.CustomerID = 'HANAR'
                      AND o.ShipRegion = p.ShipRegion); 

-- the same queries WITH NOT:

SELECT ShipRegion
FROM   Orders
WHERE  ShipRegion NOT IN (SELECT ShipRegion
                          FROM   Orders
                          WHERE  CustomerID = 'HANAR'); 


SELECT ShipRegion
FROM   Orders o
WHERE  NOT EXISTS (SELECT 1
                   FROM   Orders p
                   WHERE  p.CustomerID = 'HANAR'
                          AND o.ShipRegion = p.ShipRegion); 
--NULL occurs WITH NOT EXISTS, but WITH NOT IN only non-NULL records are displayed

--Task 8.
--Using the Orders and Employees tables, display the number of orders that have been shipped
--(ShipRegion) to regions other than those in orders handled by a Robert King employee
--(FirstName -> Robert; LastName -> King).

--CTE:

WITH iloscProdwKategorii
     AS (SELECT c.CategoryName,
                Count(*) AS iloscProduktow
         FROM   Products p
                JOIN Categories c
                  ON p.CategoryID = c.CategoryID
         GROUP  BY c.CategoryID,
                   c.CategoryName)
SELECT CategoryName,
       iloscProduktow,
       CASE iloscProduktow
         WHEN (SELECT Max(iloscProduktow)
               FROM   iloscProdwKategorii) THEN 'najwiecej'
         WHEN (SELECT Min(iloscProduktow)
               FROM   iloscProdwKategorii) THEN 'najmniej'
         ELSE 'srednio'
       END AS Ranking
FROM   iloscProdwKategorii; 

--alternatively:

SELECT Count(o.orderID) AS cnt
FROM   Orders o
WHERE  NOT EXISTS (SELECT 1
                   FROM   Orders p
                          JOIN Employees e
                            ON p.EmployeeID = e.EmployeeID
                   WHERE  e.FirstName = 'Robert'
                          AND e.LastName = 'King'
                          AND p.ShipRegion = o.ShipRegion)

SELECT Count(o.orderID) AS cnt
FROM   Orders o
WHERE  o.ShipRegion NOT IN (SELECT DISTINCT o.ShipRegion
                            FROM   Orders o
                                   JOIN Employees e
                                     ON o.EmployeeID = e.EmployeeID
                            WHERE  e.FirstName = 'Robert'
                                   AND e.LastName = 'King'
                                   AND ShipRegion IS NOT NULL)--to include orders handled by Robert King that have Null in ShipRegion
        OR o.ShipRegion IS NULL -- this condition added for remaining records from ShipRegion having Null (i.e. employees other than Robert King)
		
--Task 9.
--Using the Orders table, display all shipping countries (ShipCountry) for which there exist
--records (orders) that have a value in the ShipRegion field as well as records with NULL.

SELECT DISTINCT ShipCountry
FROM   Orders
WHERE  ShipRegion IS NOT NULL
INTERSECT
SELECT DISTINCT ShipCountry
FROM   Orders
WHERE  ShipRegion IS NULL 

--Alternatively using EXISTS:

SELECT ShipCountry
FROM   Orders o
WHERE  EXISTS (SELECT 1
               FROM   Orders p
               WHERE  ShipRegion IS NOT NULL
                      AND o.OrderID = p.OrderID)
INTERSECT
SELECT ShipCountry
FROM   Orders o
WHERE  EXISTS (SELECT 1
               FROM   Orders p
               WHERE  ShipRegion IS NULL
                      AND o.OrderID = p.OrderID) 

--Alternatively using IN:

SELECT DISTINCT ShipCountry
FROM   Orders
WHERE  ShipCountry IN (SELECT ShipCountry
                       FROM   Orders
                       WHERE  ShipRegion IS NOT NULL)
       AND ShipCountry IN (SELECT ShipCountry
                           FROM   Orders
                           WHERE  ShipRegion IS NULL) 

--Task 10.
--Using the appropriate tables, display the product ID (Products.ProductID), name
--product (Products.ProductName), supplier's country and city (Suppliers.Country, Suppliers.City – name
--them respectively: SupplierCountry and SupplierCity) and the country and the city of delivery 
--(Orders.ShipCountry, Orders.ShipCity). Limit the result to products that have been shipped
--at least once to the same country their supplier comes from. Additionally, 
--add the information whether the city where the product supplier is based also agrees
--with the city to which the product was sent - name the column FullMatch with the values
--Y/N.
--Sort the result alphabetically so that products fully consistent with each other will be displayed first.

SELECT DISTINCT p.ProductID,
                p.ProductName,
                s.Country AS 'SupplierCountry',
                s.City    AS 'SupplierCity',
                o.ShipCountry,
                o.ShipCity,
                CASE
                  WHEN s.City = o.ShipCity
                       AND s.Country = o.ShipCountry THEN 'Y'
                  ELSE 'N'
                END AS FullMatch
FROM   Products p
       JOIN Suppliers s
         ON p.SupplierID = s.SupplierID
       JOIN [Order Details] od
         ON od.ProductID = p.ProductID
       JOIN Orders o
         ON o.OrderID = od.OrderID
WHERE  o.ShipCountry IN (SELECT s.Country
                         FROM   Suppliers s
                         WHERE  p.SupplierID = s.SupplierID)
ORDER  BY FullMatch DESC,
          p.ProductName 

--alternatively using ANY (instead of IN):

SELECT DISTINCT p.ProductID,
                p.ProductName,
                s.Country AS 'SupplierCountry',
                s.City    AS 'SupplierCity',
                o.ShipCountry,
                o.ShipCity,
                CASE
                  WHEN s.City = o.ShipCity
                       AND s.Country = o.ShipCountry THEN 'Y'
                  ELSE 'N'
                END AS FullMatch
FROM   Products p
       JOIN Suppliers s
         ON p.SupplierID = s.SupplierID
       JOIN [Order Details] od
         ON od.ProductID = p.ProductID
       JOIN Orders o
         ON o.OrderID = od.OrderID
WHERE  o.ShipCountry = ANY (SELECT DISTINCT s.Country
                            FROM   Suppliers s
                            WHERE  p.SupplierID = s.SupplierID)
ORDER  BY FullMatch DESC,
          p.ProductName 

--Task 11. (*)
--Extend the previous query to add the region from which the shipment comes
--as well as the shipping region. The FullMatch column should have the following set of values:
--• Y – for full compliance of the three values
--• N (the region doesn't match) – for country and city compatibility, but not region
--• N – for lack of compliance
--Also add region fields to the result: Suppliers.Region (name them SupplierRegion) and
--Orders.ShipRegion)

SELECT p.ProductID,
       p.ProductName,
       s.Country AS 'SupplierCountry',
       s.City    AS 'SupplierCity',
       s.Region  AS 'SupplierRegion',
       o.ShipCountry,
       o.ShipCity,
       o.ShipRegion,
       CASE
         WHEN s.City = o.ShipCity
              AND s.Country = o.ShipCountry
              AND ISNULL(s.Region, 0) = ISNULL(o.ShipRegion, 0) THEN 'Y'
         WHEN s.City = o.ShipCity
              AND s.Country = o.ShipCountry THEN 'N (the region doesn''t match)'
         ELSE 'N'
       END AS FullMatch
FROM   Products p
       JOIN Suppliers s
         ON p.SupplierID = s.SupplierID
       JOIN [Order Details] od
         ON od.ProductID = p.ProductID
       JOIN Orders o
         ON o.OrderID = od.OrderID
WHERE  o.ShipCountry IN (SELECT s.Country
                         FROM   Suppliers s
                         WHERE  p.SupplierID = s.SupplierID)
GROUP  BY p.ProductID,--grouping is to avoid repeated lines (alternative to using distinct)
          p.ProductName,
          s.Country,
          s.City,
          s.Region,
          o.ShipCountry,
          o.ShipCity,
          o.ShipRegion
ORDER  BY FullMatch DESC,
          p.ProductName 
		  
--Task 12.
--Using the Products table, verify that there are two (or more) products with the same name.
--The query should return a Yes or No value in the DuplicatedProductsFlag column

WITH NumberOfProductNames
     AS (SELECT ProductName,
                Count(ProductID) AS Duplicates
         FROM   Products
         GROUP  BY ProductName)
SELECT CASE
         WHEN (SELECT Max(Duplicates)
               FROM   NumberOfProductNames) > 1 THEN 'Yes'
         ELSE 'No'
       END AS DuplicatedProductsFlag 

--Task 13.
--Using the Products and Order Details tables, display the product names along with information on how many orders 
--the given products appeared on.
--Sort the result so that the products that appear most frequently on orders will be first

SELECT p.ProductName,
       Count(od.orderId) AS NumberOfOrders
FROM   Products p
       JOIN [Order Details] od
         ON p.ProductID = od.ProductID
GROUP  BY p.ProductName
ORDER  BY NumberOfOrders DESC 

--Task 14. (*)
--Using the Orders table, extend the previous query to present the above analysis
--in the context of years (Orders.OrderDate) – name the column OrderYear.
--This time, sort the result to display first the most frequently appearing products 
--in the context of a given year, i.e. we are primarily interested in the year: 1996,
--later 1997 etc.

SELECT p.ProductName,
       Datepart(year, o.OrderDate) AS OrderYear,
       Count(od.orderId)           AS NumberOfOrders
FROM   Products p
       JOIN [Order Details] od
         ON p.ProductID = od.ProductID
       JOIN orders o
         ON od.OrderID = o.OrderID
GROUP  BY Datepart(year, o.OrderDate),
          p.ProductName --grouping takes place before select, so it is impossible to use aliases at this stage
ORDER  BY OrderYear,
          NumberOfOrders DESC -- possibility of using aliases

--Task 15. (*)
--Using the Suppliers table, extend the previous query to display additionally for each product:
--name of the supplier (Suppliers.CompanyName) – name the column SupplierName.

SELECT p.ProductName,
       Datepart(year, o.OrderDate) AS OrderYear,
       Count(od.orderId)           AS NumberOfOrders,
       s.CompanyName               AS SupplierName
FROM   Products p
       JOIN [Order Details] od
         ON p.ProductID = od.ProductID
       JOIN orders o
         ON od.OrderID = o.OrderID
       JOIN Suppliers s
         ON s.SupplierID = p.SupplierID
GROUP  BY Datepart(year, o.OrderDate),
          p.ProductName,
          s.CompanyName --forces CompanyName to be added to group by
ORDER  BY OrderYear,
          NumberOfOrders DESC 

------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------GROUPING AND AGGREGATION FUNCTIONS------------------------------

--Excercise 1.
--Using the Products table, display the maximum unit price of available products
--(UnitPrice).

SELECT Max(UnitPrice)
FROM   Products 

--Exercise 2.
--Using the Products and Categories table, display the total value of products
--(UnitPrice * UnitsInStock) divided into categories (in the result include the name of the category and
--product assigned to a category). Sort the result by category (ascending).

SELECT CategoryName,
       Sum(p.UnitPrice * p.UnitsInStock) AS SumValueOfProductsInStocks
FROM   Products p
       JOIN Categories c
         ON c.CategoryID = p.CategoryID
GROUP  BY CategoryName
ORDER  BY CategoryName 

--Exercise 3. (*)
--Extend the query from task 2 so that only categories for which the product value exceeds 10,000 are presented.
--Sort the result descending by product value.

SELECT CategoryName,
       Sum(p.UnitPrice * p.UnitsInStock) AS SumValueOfProductsInStocks
FROM   Products p
       JOIN Categories c
         ON c.CategoryID = p.CategoryID
GROUP  BY CategoryName
HAVING Sum(p.UnitPrice * p.UnitsInStock) > 10000
ORDER  BY SumValueOfProductsInStocks DESC 

--Task 4.
--Using the Suppliers, Products and Order Details table, display information on how many unique orders
-- appeared products from a given supplier. Sort the results alphabetically by suppliers
 
SELECT s.CompanyName,
       Count(DISTINCT od.OrderID) -- it is important to use DISTINCT here, we count unique orders
FROM   Suppliers s
       JOIN Products p
         ON s.SupplierID = p.SupplierID
       JOIN [Order Details] od
         ON od.ProductID = p.ProductID
GROUP  BY s.CompanyName
ORDER  BY s.CompanyName 

--Task 5.
--Using the Orders, Customers and Order Details tables, present the average, minimum and
--maximum order value (rounded to two decimal places, without taking into account
--discounts) for each customer (Customers.CustomerID). Sort the results according to the average orders value
--descending. Remember to enter the average, minimum and maximum order value
--calculated based on its value, i.e. the sum of the products of unit prices and the order size.

SELECT S.CustomerID,
       Round(Avg(S.OrderSum), 2) AS AverageOrder,
       Round(Min(S.OrderSum), 2) AS MinOrder,
       Round(Max(S.OrderSum), 2) AS MaxOrder
FROM   (SELECT o.CustomerID,
               o.OrderID,
               Sum(od.UnitPrice * od.Quantity) AS OrderSum
        FROM   Orders o
               JOIN Customers c
                 ON c.CustomerID = o.CustomerID
               JOIN [Order Details] od
                 ON od.OrderID = o.OrderID
        GROUP  BY o.CustomerID,
                  o.OrderID) S --before we calculate MAX, MIN and AVG, we should sum up all UnitPrice*Quantity products for a given customer and order. Only this will give us the value on which we do analytics.
GROUP  BY S.CustomerID
ORDER  BY Round(Avg(S.OrderSum), 2) DESC 

--Task 6.
--Using the Orders table, display the dates (OrderDate) on which there was more than one order
--taking into account the exact number of orders. Display the order date in the format YYYY-MM-DD. Result
--sort descending by number of orders.

SELECT CONVERT(date, OrderDate, 102) OrderDate,
       Count(*) AS CNT
FROM   Orders
GROUP  BY OrderDate
HAVING Count(*) > 1
ORDER  BY CNT DESC 

--Task 7.
--Using the Orders table, analyze the number of orders in 3 dimensions: Year and month, year and
--overall summary. Sort the result by the "Year-month" field (descending).

SELECT Datepart(year, OrderDate)           year,
       CONVERT(VARCHAR(7), OrderDate, 126) [Year-Month],--VARCHAR(7) ucina string do 7 znaków
       Count(*)                            AS CNT
FROM   Orders
GROUP  BY ROLLUP ( Datepart(year, OrderDate), CONVERT(VARCHAR(7), OrderDate, 126) )
ORDER  BY [Year-Month] DESC 

--Task 8.
--Using the Orders table, analyze the number of orders according to dimensions:
--• Country, region and city of delivery
--• Country and region of delivery
--• Delivery country
--• Summary
--Add a GroupingLevel column explaining the level of grouping, which will take 
--the following values for individual dimensions:
--• Country & Region & City
--• Country & Region
--•Country
--• Total
--The region field may have empty values - mark such values as "Not Provided"
--Sort the result alphabetically according to the country of delivery.

--I solution using GROUPING_ID
SELECT ShipCountry,
       CASE
         WHEN Grouping(ShipRegion) = 0
              AND ShipRegion IS NULL THEN 'Not Provided'
         ELSE ShipRegion
       END            AS ShipRegion,
       ShipCity,
       Count(orderid) AS CNT,
       CASE GROUPING_ID(ShipCountry, ShipRegion, ShipCity)-- I convert the Grouping_Id bit vector into text strings
         WHEN 0 THEN 'Country & Region & City'
         WHEN 1 THEN 'Country & Region'
         WHEN 3 THEN 'Country'
         WHEN 7 THEN 'Total'
       END            AS GroupingLevel
FROM   Orders
GROUP  BY ROLLUP ( ShipCountry, ShipRegion, ShipCity )
ORDER  BY ShipCountry 

-- II solution using GROUPING
SELECT ShipCountry,
       ISNULL(ShipRegion, 'Not Provided') AS ShipRegion,
       ShipCity,
       Count(orderid)                     AS CNT,
       CASE
         WHEN Grouping(ShipCountry) = 1 THEN 'Total'
         WHEN Grouping(ISNULL(ShipRegion, 'Not Provided')) = 1 THEN 'Country'
         WHEN Grouping(ShipCity) = 1 THEN 'Country & Region'
         ELSE 'Country & Region & City'
       END                                AS GroupingLevel
FROM   Orders
GROUP  BY ROLLUP ( ShipCountry, ISNULL(ShipRegion, 'Not Provided'), ShipCity )
ORDER  BY ShipCountry 

--Task 9.
--Using the Orders, Order Details, Customers tables, present an analysis of the sum of order values (without
--taking into account the discount) as a full analysis (all combinations) of dimensions:
--• Year (Order.OrderDate)
--• Customer (Customers.CompanyName)
--• Overall summary
--Only include records that have all the required information.
--Sort the result by customer name (alphabetically)

SELECT Datepart(YYYY, o.OrderDate)     AS Year,
       c.CompanyName                   AS Customer,
       Sum(od.UnitPrice * od.Quantity) AS OrdersValue
FROM   Orders o
       JOIN [Order Details] od
         ON o.OrderID = od.OrderID
       JOIN Customers c
         ON c.CustomerID = o.CustomerID
WHERE  Datepart(YYYY, o.OrderDate) IS NOT NULL
       AND c.CompanyName IS NOT NULL
       AND od.Quantity IS NOT NULL
       AND od.UnitPrice IS NOT NULL
GROUP  BY CUBE( Datepart(YYYY, o.OrderDate), c.CompanyName )
ORDER  BY Customer 

--Alternatively, if we do not know whether CompanyName is unique 
--and we want to base the analysis on the key and display the name:

SELECT Datepart(YYYY, o.OrderDate)           AS Year,
       (SELECT CompanyName
        FROM   Customers c1
        WHERE  c.CustomerID = c1.CustomerID) AS Customer,
       Sum(od.UnitPrice * od.Quantity)       AS OrdersValue
FROM   Orders o
       JOIN [Order Details] od
         ON o.OrderID = od.OrderID
       JOIN Customers c
         ON c.CustomerID = o.CustomerID
WHERE  Datepart(YYYY, o.OrderDate) IS NOT NULL
       AND c.CompanyName IS NOT NULL
       AND od.Quantity IS NOT NULL
       AND od.UnitPrice IS NOT NULL
GROUP  BY CUBE( Datepart(YYYY, o.OrderDate), c.CustomerID )--grouping by CustomerID
ORDER  BY Customer 

--Task 10. (*)
--Modify the query created in task 9 to include country instead of name
--(Customers.Country) and region (Customers.Region) of the customer (the dimension should consist of two: country
--and the region; summary should not be counted separately for country and region). Sort results by
--name of the country (alphabetically).

SELECT Datepart(YYYY, o.OrderDate)     AS Year,
       c.Country,
       c.Region,
       Sum(od.UnitPrice * od.Quantity) AS OrdersValue
FROM   Orders o
       JOIN [Order Details] od
         ON o.OrderID = od.OrderID
       JOIN Customers c
         ON c.CustomerID = o.CustomerID
GROUP  BY cube( Datepart(YYYY, o.OrderDate), ( c.Country, c.Region ) )
ORDER  BY c.Country,
          Year 

--Task 11.
--Using the Orders, Orders Details, Customers, Products, Suppliers and Categories tables, present
--analysis of the sum of order values (without taking into account the discount) for specific dimensions:
--• Category (Cateogires.CategoryName)
--• Supplier country (Suppliers.Country)
--• Customer country and region (Customers.Country, Customers.Region)

--Dimensions consisting of more than one attribute should be treated as a whole (without
--groupings for subsets). Don't generate additional summaries - carefully take into account the dimensions mentioned above.

--Only include records that have all the required information.
--Add a GroupingLevel field to the result explaining the grouping level that the values will take
--according to individual dimensions:
--• Category
--• Country - Supplier
--• Country & Region – Customer
--Sort the result alphabetically by the GroupingLevel column (ascending), then
--by the column with the sum of order values - OrdersValue (descending).

SELECT ct.CategoryName,
       s.Country,
       c.Country,
       c.Region,
       Sum(od.UnitPrice * od.Quantity) AS OrdersValue,
       CASE Grouping_id (ct.CategoryName, s.Country, c.Country, c.Region)
         WHEN 7 THEN 'Category'
         WHEN 11 THEN 'Country - Supplier'
         WHEN 12 THEN 'Country & Region – Customer'
       END                             AS GroupingLevel
FROM   Categories ct
       JOIN Products p
         ON p.CategoryID = ct.CategoryID
       JOIN Suppliers s
         ON s.SupplierID = p.SupplierID
       JOIN [Order Details] od
         ON od.ProductID = p.ProductID
       JOIN Orders o
         ON o.OrderID = od.OrderID
       JOIN Customers c
         ON c.CustomerID = o.CustomerID
GROUP  BY GROUPING SETS ( ct.CategoryName, s.Country, ( c.Country, c.Region ) )
ORDER  BY GroupingLevel,
          OrdersValue DESC 
--Task 12.
--Using the Orders and Shippers tables, present a table containing the number of completed orders
--to a given (ShipCountry) by a given shipping company. Present the country of delivery as the rows 
--and the suppliers as the columns. Sort the result by the name of the delivery country (alphabetically). 

--1st stage - code for the source pivot table
SELECT o.ShipCountry,
       Count(o.orderid) AS cnt,
       s.CompanyName
FROM   Orders o
       JOIN Shippers s
         ON o.ShipVia = s.ShipperID
GROUP  BY o.ShipCountry,
          s.CompanyName 

--2nd stage - I check the pivot headers
SELECT DISTINCT CompanyName,
                ShipperID
FROM   Shippers 

--3rd stage - I create a pivot from the first table:
SELECT ShipCountry,
       [Federal Shipping],
       [Speedy Express],
       [United Package]
FROM   (SELECT o.ShipCountry,
               ( o.orderid ) AS cnt,
               s.CompanyName AS CompanyName
        FROM   Orders o
               JOIN Shippers s
                 ON o.ShipVia = s.ShipperID) AS zrodlo
       PIVOT ( Count(zrodlo.cnt)
             FOR CompanyName IN ([Federal Shipping],
                                 [Speedy Express],
                                 [United Package]) ) AS Transp
ORDER  BY ShipCountry 

--Task 13. (*)
--Taking into account the Order Details table, update the previous query so that instead of the number of
--completed orders, the total value of orders handled by a given shipping company
--shipped to a given country appears.

SELECT ShipCountry,
       [Federal Shipping],
       [Speedy Express],
       [United Package]
FROM   (SELECT o.ShipCountry,
               ( od.UnitPrice * od.Quantity ) AS OrderValue,
               s.CompanyName                  AS CompanyName
        FROM   Orders o
               JOIN Shippers s
                 ON o.ShipVia = s.ShipperID
               JOIN [Order Details] od
                 ON od.OrderID = o.OrderID) AS zrodlo
       PIVOT ( Sum(zrodlo.OrderValue)
             FOR CompanyName IN ([Federal Shipping],
                                 [Speedy Express],
                                 [United Package]) ) AS Transp
ORDER  BY ShipCountry 