/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT	si.StockItemID, si.StockItemName
FROM	Warehouse.StockItems si
WHERE	si.StockItemName like N'%urgent%'
OR		si.StockItemName like N'Animal%'				

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT	s.SupplierID, s.SupplierName
FROM	Purchasing.Suppliers s
LEFT	JOIN	Purchasing.PurchaseOrders o
	ON	o.SupplierID = s.SupplierID
WHERE	o.PurchaseOrderID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT	o.OrderID,
		FORMAT(o.OrderDate,'dd-MM-yyyy','ru-Ru') AS OrderDate,
		MONTH(o.OrderDate) AS [Month],
		CASE
			WHEN MONTH(o.OrderDate) BETWEEN 1 AND 3 THEN 1
			WHEN MONTH(o.OrderDate) BETWEEN 4 AND 6 THEN 2
			WHEN MONTH(o.OrderDate) BETWEEN 7 AND 9 THEN 3
			ELSE 4
		END AS [Quarter],
		CASE
			WHEN MONTH(o.OrderDate) BETWEEN 1 AND 4 THEN 1
			WHEN MONTH(o.OrderDate) BETWEEN 5 AND 8 THEN 2
			ELSE 3
		END AS Third,
		c.CustomerName
FROM	Sales.Orders o
INNER	JOIN	Sales.OrderLines l
	ON	l.OrderId = o.OrderId
INNER	JOIN	Sales.Customers c
	ON	c.CustomerID = o.CustomerID
WHERE	(l.UnitPrice > 100 
OR		l.Quantity > 20)
AND		l.PickingCompletedWhen IS NOT NULL
ORDER BY			CASE
			WHEN MONTH(o.OrderDate) BETWEEN 1 AND 3 THEN 1
			WHEN MONTH(o.OrderDate) BETWEEN 4 AND 6 THEN 2
			WHEN MONTH(o.OrderDate) BETWEEN 7 AND 9 THEN 3
			ELSE 4
		END,
		CASE
			WHEN MONTH(o.OrderDate) BETWEEN 1 AND 4 THEN 1
			WHEN MONTH(o.OrderDate) BETWEEN 5 AND 8 THEN 2
			ELSE 3
		END,
		o.OrderDate
OFFSET	1000 ROWS FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT	dm.DeliveryMethodName,
		po.ExpectedDeliveryDate,
		s.SupplierName,
		p.FullName
FROM	Purchasing.Suppliers s
INNER	JOIN	Purchasing.PurchaseOrders po
	ON	po.SupplierID  = s.SupplierID
INNER	JOIN	Application.DeliveryMethods dm
	ON	dm.DeliveryMethodID = po.DeliveryMethodID
INNER	JOIN	Application.People p
	ON	p.PersonID = po.ContactPersonID
WHERE	YEAR(po.ExpectedDeliveryDate) = 2013 
AND		MONTH(po.ExpectedDeliveryDate) = 1
AND		(dm.DeliveryMethodName = N'Air Freight'	OR	dm.DeliveryMethodName = N'Refrigerated Air Freight')
AND		po.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT	TOP 10 c.CustomerName, p.FullName
FROM	Sales.Orders o
INNER	JOIN	Sales.Customers c
	ON	o.CustomerID = c.CustomerID
INNER	JOIN	Application.People p
	ON	o.SalespersonPersonID = p.PersonID
ORDER BY	OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT	c.CustomerID,
		c.CustomerName,
		c.PhoneNumber
FROM	Sales.Customers c
INNER	JOIN	Sales.Orders o
	ON	o.CustomerID = c.CustomerID
INNER	JOIN	Sales.OrderLines l
	ON	l.OrderId = o.OrderID
INNER	JOIN	Warehouse.StockItems si
	ON	si.StockItemID = l.StockItemID
WHERE	si.StockItemName = N'Chocolate frogs 250g'
