/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

SELECT	si.StockItemID, si.StockItemName
FROM	Warehouse.StockItems si
WHERE	si.StockItemName like N'%urgent%'
OR		si.StockItemName like N'Animal%'				

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

SELECT	s.SupplierID, s.SupplierName
FROM	Purchasing.Suppliers s
LEFT	JOIN	Purchasing.PurchaseOrders o
	ON	o.SupplierID = s.SupplierID
WHERE	o.PurchaseOrderID IS NULL

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
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
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
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
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/

SELECT	TOP 10 c.CustomerName, p.FullName
FROM	Sales.Orders o
INNER	JOIN	Sales.Customers c
	ON	o.CustomerID = c.CustomerID
INNER	JOIN	Application.People p
	ON	o.SalespersonPersonID = p.PersonID
ORDER BY	OrderDate desc

/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
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
