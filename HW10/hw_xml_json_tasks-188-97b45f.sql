/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
--OPENXML
DECLARE @xmlDocument XML

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\Nastya\otus\ms sql developer\otus-mssql-Nastassia\HW10\StockItems-188-1fb5df.XML', 
 SINGLE_CLOB)
AS DATA 

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

DROP TABLE IF EXISTS #StockItems

SELECT *
INTO #StockItems
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH(
		StockItemName			NVARCHAR(100)	'@Name', 
		SupplierID				INT				'SupplierID', 
		UnitPackageID			INT				'Package/UnitPackageID',
		OuterPackageID			INT				'Package/OuterPackageID',	
		QuantityPerOuter		INT				'Package/QuantityPerOuter',
		TypicalWeightPerUnit	DECIMAL(18,3)	'Package/TypicalWeightPerUnit',
		LeadTimeDays			INT				'LeadTimeDays', 
		IsChillerStock			BIT				'IsChillerStock', 
		TaxRate					DECIMAL(18,3)	'TaxRate', 
		UnitPrice				DECIMAL(18,2)	'UnitPrice'
	)

EXEC sp_xml_removedocument @docHandle


MERGE Warehouse.StockItems trg
	USING #StockItems src
	ON	trg.StockItemName = src.StockItemName
	WHEN MATCHED THEN
	UPDATE
	SET	StockItemName = src.StockItemName, 
		SupplierID = src.SupplierID, 
		UnitPackageID = src.UnitPackageID,
		OuterPackageID = src.OuterPackageID,	
		QuantityPerOuter = src.QuantityPerOuter,
		TypicalWeightPerUnit = src.TypicalWeightPerUnit,
		LeadTimeDays = src.TypicalWeightPerUnit, 
		IsChillerStock = src.IsChillerStock, 
		TaxRate	= src.IsChillerStock, 
		UnitPrice = src.UnitPrice,
		LastEditedBy = 1
	WHEN NOT MATCHED THEN 
	INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
	VALUES (src.StockItemName, src.SupplierID, src.UnitPackageID, src.OuterPackageID, src.QuantityPerOuter, src.TypicalWeightPerUnit, src.LeadTimeDays, src.IsChillerStock, src.TaxRate, src.UnitPrice, 1);

--XQUERY
;WITH XMLData
AS
(
	SELECT	t.Item.value('(@Name)[1]', 'NVARCHAR(100)') AS StockItemName, 
			t.Item.value('(SupplierID)[1]', 'INT') AS SupplierID, 
			t.Item.value('(Package/UnitPackageID)[1]', 'INT') AS UnitPackageID,
			t.Item.value('(Package/OuterPackageID)[1]', 'INT') AS OuterPackageID,	
			t.Item.value('(Package/QuantityPerOuter)[1]', 'INT') AS QuantityPerOuter,
			t.Item.value('(Package/TypicalWeightPerUnit)[1]', 'DECIMAL(18,3)') AS TypicalWeightPerUnit,
			t.Item.value('(LeadTimeDays)[1]', 'INT') AS LeadTimeDays,
			t.Item.value('(IsChillerStock)[1]', 'BIT') AS IsChillerStock,
			t.Item.value('(TaxRate)[1]', 'DECIMAL(18,3)') AS TaxRate,
			t.Item.value('(UnitPrice)[1]', 'DECIMAL(18,2)') AS UnitPrice
	FROM	@xmlDocument.nodes('/StockItems/Item') AS t(Item)

)

MERGE Warehouse.StockItems trg
	USING XMLData src
	ON	trg.StockItemName = src.StockItemName
	WHEN MATCHED THEN
	UPDATE
	SET	StockItemName = src.StockItemName, 
		SupplierID = src.SupplierID, 
		UnitPackageID = src.UnitPackageID,
		OuterPackageID = src.OuterPackageID,	
		QuantityPerOuter = src.QuantityPerOuter,
		TypicalWeightPerUnit = src.TypicalWeightPerUnit,
		LeadTimeDays = src.TypicalWeightPerUnit, 
		IsChillerStock = src.IsChillerStock, 
		TaxRate	= src.IsChillerStock, 
		UnitPrice = src.UnitPrice,
		LastEditedBy = 1
	WHEN NOT MATCHED THEN 
	INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
	VALUES (src.StockItemName, src.SupplierID, src.UnitPackageID, src.OuterPackageID, src.QuantityPerOuter, src.TypicalWeightPerUnit, src.LeadTimeDays, src.IsChillerStock, src.TaxRate, src.UnitPrice, 1);

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT
	StockItemName AS [@Name], 
	SupplierID AS [SupplierID], 
	UnitPackageID AS [Package/UnitPackageID],
	OuterPackageID AS [Package/OuterPackageID],	
	QuantityPerOuter AS [Package/QuantityPerOuter],
	TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
	LeadTimeDays AS [LeadTimeDays], 
	IsChillerStock AS [IsChillerStock], 
	TaxRate AS [TaxRate], 
	UnitPrice AS [UnitPrice]
FROM	Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT 
StockItemID,
StockItemID,
CountryOfManufacture, 
FirstTag,
CustomFields
FROM	Warehouse.StockItems
CROSS	APPLY OPENJSON (CustomFields)
WITH
(
CountryOfManufacture NVARCHAR(50) '$.CountryOfManufacture',
FirstTag NVARCHAR(50) '$.Tags[0]'
)

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT 
	StockItemID,
	StockItemID
FROM	Warehouse.StockItems
CROSS	APPLY	OPENJSON (CustomFields, '$.Tags') FTag
WHERE	FTag.value = 'Vintage'
