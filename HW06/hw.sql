/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
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
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
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
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
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
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
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
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
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
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
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
