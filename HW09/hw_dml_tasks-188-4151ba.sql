/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO Sales.Customers([CustomerID]
      ,[CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
SELECT TOP 5
		(MAX(CustomerID) OVER() + ROW_NUMBER() OVER(ORDER BY [CustomerName])) AS [CustomerID]
      ,[CustomerName] + ' (Test)'
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
FROM	Sales.Customers
ORDER BY CustomerID DESC

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/
DELETE	FROM C
FROM	Sales.Customers C
WHERE	c.CustomerName = 'Yves Belisle (Test)'

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE	C
SET		CustomerName = 'Wingtip Toys (Yaak) (Test)'
FROM	Sales.Customers C
WHERE	CustomerName = 'Wingtip Toys (Yaak, MT) (Test)'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
;WITH SourceTable
AS
(
	SELECT 
		CASE WHEN	CustomerID  = MAX(CustomerID) OVER()
			THEN	[CustomerId] + 1
			ELSE	[CustomerId]	  
		END AS   CustomerId
      ,CASE WHEN	CustomerID  = MAX(CustomerID) OVER()
			THEN [CustomerName] + '_INS'
			ELSE	  [CustomerName] + '_UPD'
	  END AS   [CustomerName] 
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
FROM	Sales.Customers
WHERE	CustomerName LIKE '%test%'
)


MERGE Sales.Customers AS TargetTable
USING SourceTable
ON	SourceTable.[CustomerID] = TargetTable.[CustomerID]
WHEN	MATCHED THEN
UPDATE	SET	TargetTable.CustomerName = SourceTable.CustomerNAme
WHEN	NOT MATCHED THEN INSERT(
									CustomerId
									,[CustomerName] 
									,[BillToCustomerID]
									,[CustomerCategoryID]
									,[BuyingGroupID]
									,[PrimaryContactPersonID]
									,[AlternateContactPersonID]
									,[DeliveryMethodID]
									,[DeliveryCityID]
									,[PostalCityID]
									,[CreditLimit]
									,[AccountOpenedDate]
									,[StandardDiscountPercentage]
									,[IsStatementSent]
									,[IsOnCreditHold]
									,[PaymentDays]
									,[PhoneNumber]
									,[FaxNumber]
									,[DeliveryRun]
									,[RunPosition]
									,[WebsiteURL]
									,[DeliveryAddressLine1]
									,[DeliveryAddressLine2]
									,[DeliveryPostalCode]
									,[DeliveryLocation]
									,[PostalAddressLine1]
									,[PostalAddressLine2]
									,[PostalPostalCode]
									,[LastEditedBy])
								VALUES
								(
									SourceTable.CustomerId
									,SourceTable.[CustomerName] 
									,SourceTable.[BillToCustomerID]
									,SourceTable.[CustomerCategoryID]
									,SourceTable.[BuyingGroupID]
									,SourceTable.[PrimaryContactPersonID]
									,SourceTable.[AlternateContactPersonID]
									,SourceTable.[DeliveryMethodID]
									,SourceTable.[DeliveryCityID]
									,SourceTable.[PostalCityID]
									,SourceTable.[CreditLimit]
									,SourceTable.[AccountOpenedDate]
									,SourceTable.[StandardDiscountPercentage]
									,SourceTable.[IsStatementSent]
									,SourceTable.[IsOnCreditHold]
									,SourceTable.[PaymentDays]
									,SourceTable.[PhoneNumber]
									,SourceTable.[FaxNumber]
									,SourceTable.[DeliveryRun]
									,SourceTable.[RunPosition]
									,SourceTable.[WebsiteURL]
									,SourceTable.[DeliveryAddressLine1]
									,SourceTable.[DeliveryAddressLine2]
									,SourceTable.[DeliveryPostalCode]
									,SourceTable.[DeliveryLocation]
									,SourceTable.[PostalAddressLine1]
									,SourceTable.[PostalAddressLine2]
									,SourceTable.[PostalPostalCode]
									,SourceTable.[LastEditedBy]
								);


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

SELECT	CustomerId
		,[CustomerName] 
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[BuyingGroupID]
		,[PrimaryContactPersonID]
		,[AlternateContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[CreditLimit]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[DeliveryRun]
		,[RunPosition]
		,[WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryAddressLine2]
		,[DeliveryPostalCode]
		,[DeliveryLocation]
		,[PostalAddressLine1]
		,[PostalAddressLine2]
		,[PostalPostalCode]
		,[LastEditedBy]
		,[ValidFrom]
		,[ValidTo]
INTO	Sales.Customers_temp 
FROM	Sales.Customers
WHERE	1 = 2

EXEC master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "C:\Nastya\otus\ms sql developer\Customers.txt" -T -w -t ; -r \n -S DESKTOP-RO3GDKA'

BULK INSERT [WideWorldImporters].[Sales].Customers_temp
				FROM "C:\Nastya\otus\ms sql developer\Customers.txt"
				WITH 
					(
					BATCHSIZE = 1000, 
					DATAFILETYPE = 'widechar',
					FIELDTERMINATOR = ';',
					ROWTERMINATOR ='\n',
					KEEPNULLS,
					TABLOCK        
					);

