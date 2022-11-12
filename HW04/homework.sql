/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "03 - ����������, CTE, ��������� �������".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ��� ���� �������, ��� ��������, �������� ��� �������� ��������:
--  1) ����� ��������� ������
--  2) ����� WITH (��� ����������� ������)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. 
������� �� ���������� � ��� ������ ���. 
������� �������� � ������� Sales.Invoices.
*/

SELECT	P.PersonID, P.FullName
FROM	[Application].People P
WHERE	P.PersonID NOT IN (
						SELECT I.SalespersonPersonID
						FROM	Sales.Invoices I
						WHERE	I.InvoiceDate = '20150704'
					)
AND		P.IsSalesPerson = 1

;WITH PersonInvoiceCTE
AS
(
	SELECT I.SalespersonPersonID
	FROM	Sales.Invoices I
	WHERE	I.InvoiceDate = '20150704'
)

SELECT	P.PersonID, P.FullName
FROM	[Application].People P
LEFT	JOIN	PersonInvoiceCTE I
	ON	I.SalespersonPersonID = P.PersonID
WHERE	I.SalespersonPersonID IS NULL
AND		P.IsSalesPerson = 1

/*
2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.
*/

SELECT	si.StockItemID, si.StockItemName, si.UnitPrice
FROM	Warehouse.StockItems si
WHERE	si.UnitPrice = (
							SELECT	MIN(UnitPrice)
							FROM	Warehouse.StockItems
						)

;WITH MinUnitPriceCTE
AS
(
	SELECT	MIN(UnitPrice) as UnitPrice
	FROM	Warehouse.StockItems
)

SELECT	si.StockItemID, si.StockItemName, si.UnitPrice
FROM	Warehouse.StockItems si
INNER	JOIN	MinUnitPriceCTE p
	ON	P.UnitPrice = si.UnitPrice

/*
3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� 
�� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE). 
*/

SELECT	C.*
FROM	Sales.Customers C
WHERE	C.CustomerID IN 
							(
								SELECT TOP 5 CustomerID
								FROM	Sales.CustomerTransactions T
								ORDER BY	TransactionAmount DESC
							)

;WITH	CustomersCTE
AS
(
	SELECT TOP 5 t.CustomerID
	FROM	Sales.CustomerTransactions	t
	ORDER BY	TransactionAmount DESC
)

SELECT	DISTINCT C.CustomerID, c.CustomerName
FROM	Sales.Customers C
INNER	JOIN	CustomersCTE	t
	ON	t.CustomerID = c.CustomerID	
	

/*
4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, 
�������� � ������ ����� ������� �������, � ����� ��� ����������, 
������� ����������� �������� ������� (PackedByPersonID).
*/

SELECT	c.CityID, c.CityName, p.FullName
FROM	Application.Cities C
INNER	JOIN	Sales.Customers SC
	ON	SC.DeliveryCityID = c.CityID
INNER	JOIN	(
					SELECT TOP	3 i.CustomerID, PackedByPersonID
					FROM	Sales.Invoices i
					INNER	JOIN	Sales.InvoiceLines l
						ON	l.InvoiceID = i.InvoiceID
					ORDER BY	l.UnitPrice DESC
				) I
				ON	I.CustomerID = SC.CustomerID
INNER	JOIN	Application.People p
	ON	p.PersonID = i.PackedByPersonID

;WITH	InvoicesCTE
AS
(				
	SELECT TOP	3 i.CustomerID, PackedByPersonID
	FROM	Sales.Invoices i
	INNER	JOIN	Sales.InvoiceLines l
	ON	l.InvoiceID = i.InvoiceID
	ORDER BY	l.UnitPrice DESC
)

SELECT	c.CityID, c.CityName, p.FullName
FROM	Application.Cities C
INNER	JOIN	Sales.Customers SC
	ON	SC.DeliveryCityID = c.CityID
INNER	JOIN	InvoicesCTE I
	ON	I.CustomerID = SC.CustomerID
INNER	JOIN	Application.People p
	ON	p.PersonID = i.PackedByPersonID


-- ---------------------------------------------------------------------------
-- ������������ �������
-- ---------------------------------------------------------------------------
-- ����� ��������� ��� � ������� ��������� ������������� �������, 
-- ��� � � ������� ��������� �����\���������. 
-- �������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. 
-- ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). 
-- �������� ���� ����������� �� ������ �����������. 

-- 5. ���������, ��� ������ � ������������� ������

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

--TODO: �������� ����� ���� �������
