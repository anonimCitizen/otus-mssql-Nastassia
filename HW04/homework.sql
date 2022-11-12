/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
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
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
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
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
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
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
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
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

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

--TODO: напишите здесь свое решение
