/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
;WITH InfoCTE
AS
(
SELECT 	
	DATEFROMPARTS(YEAR(i.InvoiceDate), MONTH(i.InvoiceDate), 1) AS FirstDayOfMonth,
	--SUM(Quantity) OVER (PARTITION BY i.CustomerId, MONTH(i.InvoiceDate), YEAR(i.InvoiceDate)) as TotalQuantity,
	Quantity,
	SUBSTRING(p.CustomerName, CHARINDEX('(',p.CustomerName) + 1, CHARINDEX(')', p.CustomerName) - CHARINDEX('(',p.CustomerName) - 1) AS CustomerName
FROM	Sales.Invoices i
INNER	JOIN	Sales.InvoiceLines il
	ON	il.InvoiceLineID = i.InvoiceID
INNER	JOIN	Sales.Customers P
	ON	P.CustomerId = i.CustomerID
WHERE	i.CustomerId between 2 and 6
)

SELECT
		FirstDayOfMonth AS InvoiceMonth,
		[Peeples Valley, AZ],
		[Medicine Lodge, KS],
		[Gasport, NY],
		[Sylvanite, MT],
		[Jessie, ND]
FROM
	InfoCTE
	PIVOT (SUM(Quantity) FOR CustomerName IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])) as PivotTable
ORDER BY InvoiceMonth
/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT	CustomerName, AddressLine
FROM	Sales.Customers
UNPIVOT (AddressLine FOR [Column] IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2) ) UnpivotTable
WHERE CustomerName like '%Tailspin Toys%'

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT CountryId, CountryName, Code
FROM 
( 
SELECT	CountryId, CountryName, IsoAlpha3Code, CAST(IsoNumericCode AS NVARCHAR(3)) AS IsoNumericCode
FROM	Application.Countries
) SourceTable
UNPIVOT( Code FOR ColumnName IN (IsoAlpha3Code, IsoNumericCode)) AS UnpivotTable
ORDER BY CountryId

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT CustomerID,
		CustomerName,
		si.StockItemName, 
		si.StockItemID,
		goods.UnitPrice
FROM	Sales.Customers c
OUTER APPLY	(
				SELECT DISTINCT TOP 2 il.StockItemID, UnitPrice
				FROM	Sales.Invoices i
				LEFT	JOIN	Sales.InvoiceLines il
					ON	il.InvoiceID = i.InvoiceID
				where i.CustomerID = c.CustomerID
				Order by UnitPrice DESC
			) Goods
LEFT	JOIN	Warehouse.StockItems si
	ON	si.StockItemID = goods.StockItemID
ORDER BY	CustomerID

