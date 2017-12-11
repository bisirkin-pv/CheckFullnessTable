# Check Fullness Table v1.0
> Процедура проверки наполненности таблиц.
Текущая версия реализована на T-SQL, для работы требуется MS SQL Server 2012 или выше.

## Установка:
* [Скачать архив с github](https://github.com/bisirkin-pv/CheckFullnessTable/archive/master.zip)
* Открыть скрипт `deploy.sql`
* Произвести начальные настройки:
```sql
USE TOOLS /* База для установки */
GO
DECLARE @DEBUG BIT = 0;		/* Только отобразить текст */
DECLARE @REBILD BIT = 1;	/* пересоздавать объекты */
DECLARE @SHCHEMA VARCHAR(5) = 'cft';
DECLARE @TABLE_VERIFICATION VARCHAR(100) = 'tVerification';		/* Хранит данные по таблицам к проверке */
DECLARE @VIEW_VERIFICATION VARCHAR(100) = 'vVerification';		/* Отображает сравнение проверок */
DECLARE @PRC_SET_VERIFY VARCHAR(100) = 'prcSetVerefyObject';	/* Добавление новой таблицы и подсчет строк в таблице */
DECLARE @PRC_AUTO_VERIFY VARCHAR(100) = 'prcAutoVerifyTable';	/* Проверка источников на наполнность */
```
* Выполнить скрипт (Результат начальной установки)
```sql
[Info] Срипт запущен в режиме deploy
[Info] Схема [cft] уже существует
[Success] Создан объект:TOOLS.cft.tVerification
[Success] Создан объект:TOOLS.cft.vVerification
[Success] Создан объект:TOOLS.cft.prcSetVerefyObject
[Success] Создан объект:TOOLS.cft.prcAutoVerifyTable
```

## Добавление объектов для проверки
> Для добавление объектов нужно выполнить процедуру (@PRC_SET_VERIFY), передав полное название объекта, остальные параметры не обязательные.

```sql
/*
    @FULL_NAME VARCHAR(200)         -- Полное название объекта
	,@DIFF_PERC DECIMAL(8,3) = 0.75 -- Процент различия между проверками
	,@DEBUG BIT = 0                 -- Вывести код добавления, не вставлять данные
*/

EXECUTE TOOLS.cft.prcSetVerefyObject 'pubs.dbo.authors', 0.80
```

## Проверка объектов
> Для запуска проверки запустите процедуру (@PRC_AUTO_VERIFY) без параметров, в данной процедуре реализована отправка отчета на почту о результате проверки.
**Если вы хотите использовать данную возможность незабудьте заменить `@recipients` на свой адрес и раскоментировать блок отправки письма.**
## Отображение результата проверки
> Для отображения результата выполните запрос к представлению (@VIEW_VERIFICATION):
```sql
SELECT 
	 fullName		AS [Имя объекта]
	,lastCountRows	AS [Предыдущее кол-во строк]
	,lastLoadDtm	AS [Предыдущее время проверки]
	,nowCountRows	AS [Последнее кол-во строк]
	,nowLoadDtm		AS [Последнее время проверки]
	,diffPerc		AS [Предельный процент расхождений]
	,nowPerc		AS [Текущий процент расхождений]
SELECT TOOLS.cft.vVerification
```
## Удаление
> Для удаления объектов воспользуйтесь скриптом `rollback.sql`
Для настройки используйте такие же имена что и при установке
**Примечание:** схема нужно удалять вручную.

## Пример отображения результатов проверки
> Одним из возможных способов слежения за результатами проверки может служить веб-сайт. В директории `www` рпозитория расположен тестовый вариант веб-страницы на которой отображаются данные. 
В качетве веб-сервера используется Apache 2.4 + PHP 7 с подключеным модулем [sqlsrv](https://www.microsoft.com/en-us/download/details.aspx?id=20098)
