/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "06 - ������� �������".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. ������� ������ ����� ������ ����������� ������ �� ������� � 2015 ���� 
(� ������ ������ ������ �� ����� ����������, ��������� ����� � ������� ������� �������).
��������: id �������, �������� �������, ���� �������, ����� �������, ����� ����������� ������

������:
-------------+----------------------------
���� ������� | ����������� ���� �� ������
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
������� ����� ����� �� ������� Invoices.
����������� ���� ������ ���� ��� ������� �������.
*/

;WITH TableSumCTE
AS
(
	SELECT	SUM(ExtendedPrice) AS ExtendedPrice, 
			InvoiceDate
	FROM	sales.Invoices i
	INNER	JOIN	sales.InvoiceLines l
		ON	l.InvoiceID = i.InvoiceID
	WHERE	i.InvoiceDate >= '20150101'
	GROUP BY	InvoiceDate
),
CamulativeCTE
AS
(
	SELECT	s.InvoiceDate, 
			Sum(t.ExtendedPrice) AS ExtendedPrice
	FROM	TableSumCTE s
	INNER	JOIN	TableSumCTE t
		ON	t.InvoiceDate <= s.InvoiceDate	
	GROUP BY s.InvoiceDate
)

SELECT	c.InvoiceDate,
		t.ExtendedPrice
FROM	CamulativeCTE c
INNER	JOIN	CamulativeCTE t
	ON	MONTH(c.InvoiceDate) = MONTH(t.InvoiceDate)
	AND	YEAR(c.InvoiceDate) = YEAR(t.InvoiceDate)
WHERE	t.InvoiceDate = EOMONTH(t.InvoiceDate)
ORDER	BY	c.InvoiceDate

/*
2. �������� ������ ����� ����������� ������ � ���������� ������� � ������� ������� �������.
   �������� ������������������ �������� 1 � 2 � ������� set statistics time, io on
*/

;WITH	DaySumCTE
AS
(
SELECT	DISTINCT i.InvoiceDate,
		SUM(l.ExtendedPrice) OVER (ORDER BY i.InvoiceDate) TotalSum
FROM	sales.Invoices i
INNER	JOIN	Sales.InvoiceLines l
	ON	l.InvoiceID = i.InvoiceID
WHERE	i.InvoiceDate >= '20150101'
)

SELECT d.InvoiceDate, m.TotalSum	
FROM	DaySumCTE d
INNER	JOIN	DaySumCTE M
	ON	MONTH(d.InvoiceDate) = MONTH(m.InvoiceDate)
	AND	YEAR(d.InvoiceDate) = YEAR(m.InvoiceDate)
WHERE	M.InvoiceDate = EOMONTH(m.InvoiceDate)
ORDER BY	InvoiceDate


/*
3. ������� ������ 2� ����� ���������� ��������� (�� ���������� ���������) 
� ������ ������ �� 2016 ��� (�� 2 ����� ���������� �������� � ������ ������).
*/
;WITH SumCTE
AS
(
SELECT DISTINCT 
	l.StockItemID,
	MONTH(InvoiceDate) [Month],
	SUM(l.Quantity) OVER (PARTITION BY l.StockItemId, MONTH(InvoiceDate)) as TotalSum
FROM	Sales.Invoices i
INNER	JOIN	Sales.InvoiceLines l
	ON	l.InvoiceID = i.InvoiceID
WHERE	YEAR(InvoiceDate) = 2016
),
SumOrderCTE
AS
(
SELECT	StockItemID,
		[Month],
		TotalSum,
		Row_Number() OVER (Partition by [month] order by [month], totalsum desc) AS OrderPos
FROM	SumCTE
)

SELECT	si.StockItemID,
		si.StockItemName,
		[MONTH],
		TotalSum
FROM	SumOrderCTE so
INNER	JOIN	Warehouse.StockItems si
	ON	si.StockItemID = so.StockItemID
WHERE	OrderPos <= 2
ORDER BY	[Month], OrderPos

/*
4. ������� ����� ��������
���������� �� ������� ������� (� ����� ����� ������ ������� �� ������, ��������, ����� � ����):
* ������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������
* ���������� ����� ���������� ������� � �������� ����� � ���� �� �������
* ���������� ����� ���������� ������� � ����������� �� ������ ����� �������� ������
* ���������� ��������� id ������ ������ �� ����, ��� ������� ����������� ������� �� ����� 
* ���������� �� ������ � ��� �� �������� ����������� (�� �����)
* �������� ������ 2 ������ �����, � ������ ���� ���������� ������ ��� ����� ������� "No items"
* ����������� 30 ����� ������� �� ���� ��� ������ �� 1 ��

��� ���� ������ �� ����� ������ ������ ��� ������������� �������.
*/

SELECT	StockItemID, 
		StockItemName, 
		Brand, 
		UnitPrice,
		ROW_NUMBER() OVER (Partition BY substring(StockItemName,1,1) order by StockItemName) AS RowNumber,
		COUNT(StockItemID) OVER () AS [AllCount],
		COUNT(StockItemID) OVER (Partition BY substring(StockItemName,1,1)) AS CountLetter,
		LEAD(StockItemID) OVER (Order by StockItemName) NextStockItemID,
		LAG(StockItemID) OVER (Order by StockItemName) PreviousStockItemID,
		LAG(cast(StockItemID as nvarchar(15)), 2, 'No items') OVER (Order by StockItemName) PreviousStockItemID,
		NTILE(30) OVER (Order by [TypicalWeightPerUnit]) AS Groups
FROM
	Warehouse.StockItems
ORDER BY	StockItemName

/*
5. �� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������.
   � ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������.
*/
;WITH SalesInvoiceCTE
AS
(
SELECT DISTINCT i.SalespersonPersonID, 
		LAST_VALUE(i.InvoiceID) OVER(PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate) AS InvoiceID
FROM	Sales.Invoices I
)

SELECT	DISTINCT p.PersonID AS SalespersonPersonID, p.FullName AS SalespersonPersonName, 
		c.PersonID AS CustomerId, c.FullName AS CustomerName, i.InvoiceDate, 
		SUM(ExtendedPrice) OVER (PARTITION BY i.InvoiceId) AS ExtendedPrice
FROM	SalesInvoiceCTE ct
INNER	JOIN	Sales.Invoices i
	ON	i.InvoiceID = ct.InvoiceId
INNER	JOIN	Sales.InvoiceLines il
	ON	il.InvoiceID = i.InvoiceID
INNER	JOIN	[Application].People p
	ON	p.PersonID = ct.SalespersonPersonID
INNER	JOIN	[Application].People c
	ON	c.PersonID = i.CustomerID	
/*
6. �������� �� ������� ������� ��� ����� ������� ������, ������� �� �������.
� ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������.
*/
;WITH GoodsCTE
AS
(
SELECT DISTINCT 
	I.CustomerID,
	IL.StockItemId,
	i.InvoiceID,
	IL.InvoiceLineId,
	ROW_NUMBER() OVER(PARTITION BY CustomerId ORDER BY ExtendedPrice DESC) Number
FROM	Sales.Invoices I
INNER	JOIN	Sales.InvoiceLines IL
	ON	IL.InvoiceID = I.InvoiceID
)

SELECT	ct.CustomerID, p.FullName, ct.StockItemID, i.InvoiceDate, il.ExtendedPrice 
FROM	GoodsCTE ct
INNER	JOIN	[Application].People p
	ON	p.PersonId = ct.CustomerID
INNER	JOIN	Sales.Invoices i
	ON	i.InvoiceId = ct.InvoiceID
INNER	JOIN	Sales.InvoiceLines IL
	ON	IL.InvoiceLineID = ct.InvoiceLineID
WHERE	Number <= 2
ORDER BY CustomerID
