Перем Лог;
Перем мИдентификаторКластера;
Перем мИдентификаторБазы;
Перем ЭтоWindows;
Перем мНастройки;

Процедура УстановитьНастройки(НастройкиКоманды) Экспорт
    мНастройки = НастройкиКоманды;
КонецПроцедуры


Процедура УстановитьСтатусБлокировкиСеансов(Знач Блокировать) Экспорт
	
	КлючиАвторизацииВБазе = КлючиАвторизацииВБазе();
	
	ИдентификаторКластера = ИдентификаторКластера();
	ИдентификаторБазы = ИдентификаторБазы();
	
	КлючРазрешенияЗапуска = ?(ПустаяСтрока(мНастройки.КлючРазрешенияЗапуска), ИдентификаторБазы, мНастройки.КлючРазрешенияЗапуска);
	ВремяБлокировки = мНастройки.ВремяСтратаБлокировки;
	Если ПустаяСтрока(ВремяБлокировки) И Не ПустаяСтрока(мНастройки.ВремяСтратаБлокировкиЧерез) Тогда
		Секунды = 0;
		Попытка
			Секунды = Число(мНастройки.ВремяСтратаБлокировкиЧерез);
		Исключение
		КонецПопытки;
		
		ВремяБлокировки = Формат(ТекущаяДата()+Секунды,"ДФ='yyyy-MM-ddTHH:mm:ss'");
	КонецЕсли;
	
	КомандаВыполнения = СтрокаЗапускаКлиента() + СтрШаблон("infobase update --infobase=""%3""%4 --cluster=""%1""%2 --sessions-deny=%5 --denied-message=""%6"" --denied-from=""%8"" --permission-code=""%7""",
		ИдентификаторКластера,
		КлючиАвторизацииВКластере(),
		ИдентификаторБазы,
		КлючиАвторизацииВБазе,
		?(Блокировать, "on", "off"), 
		мНастройки.СообщениеОблокировке, 
		КлючРазрешенияЗапуска, 
		ВремяБлокировки);
		
	ЗапуститьПроцесс(КомандаВыполнения);
	
	Лог.Информация("Сеансы " + ?(Блокировать, "запрещены", "разрешены"));
	
КонецПроцедуры

Функция ПолучитьСписокСеансов() Экспорт
	
	ТаблицаСеансов = Новый ТаблицаЗначений;
	ТаблицаСеансов.Колонки.Добавить("Идентификатор");
	ТаблицаСеансов.Колонки.Добавить("Приложение");
	ТаблицаСеансов.Колонки.Добавить("Пользователь");
	ТаблицаСеансов.Колонки.Добавить("НомерСеанса");
	
	КомандаЗапуска = СтрокаЗапускаКлиента() + СтрШаблон("session list --cluster=""%1""%2 --infobase=""%3""",
		ИдентификаторКластера(), 
		КлючиАвторизацииВКластере(),
		ИдентификаторБазы());
	
	СписокСеансовИБ = ЗапуститьПроцесс(КомандаЗапуска);	
	
	Данные = РазобратьПоток(СписокСеансовИБ);
	
	Для Каждого Элемент Из Данные Цикл
		
		ТекСтрока = ТаблицаСеансов.Добавить();
		ТекСтрока.Идентификатор = Элемент["session"];
		ТекСтрока.Пользователь  = Элемент["user-name"];
		ТекСтрока.Приложение    = Элемент["app-id"];
		ТекСтрока.НомерСеанса   = Элемент["session-id"];

	КонецЦикла;
	
	Возврат ТаблицаСеансов;
	
КонецФункции

Процедура ОтключитьСеанс(Знач Сеанс) Экспорт

	СтрокаВыполнения = СтрокаЗапускаКлиента() + СтрШаблон("session terminate --cluster=""%1""%2 --session=""%3""",
		ИдентификаторКластера(),
		КлючиАвторизацииВКластере(),
		Сеанс.Идентификатор);
	
	Лог.Информация(СтрШаблон("Отключаю сеанс: %1 [%2] (%3)", Сеанс.НомерСеанса, Сеанс.Пользователь, Сеанс.Приложение));
	
	ЗапуститьПроцесс(СтрокаВыполнения);

КонецПроцедуры

Функция ПолучитьСписокРабочихПроцессов() Экспорт
	
	КомандаЗапускаПроцессы = СтрокаЗапускаКлиента() + СтрШаблон("process list --cluster=""%1""%2",
		ИдентификаторКластера(), 
		КлючиАвторизацииВКластере());
		
	Лог.Информация("Получаю список рабочих процессов...");
	СписокПроцессов = ЗапуститьПроцесс(КомандаЗапускаПроцессы);
	
	Возврат РазобратьПоток(СписокПроцессов);
	
КонецФункции

Функция ПолучитьСоединенияРабочегоПроцесса(Знач РабочийПроцесс) Экспорт
	
	КомандаЗапускаСоединения = СтрокаЗапускаКлиента() + СтрШаблон("connection list --cluster=""%1""%2 --infobase=%3%4 --process=%5",
				ИдентификаторКластера(), 
				КлючиАвторизацииВКластере(),
				ИдентификаторБазы(),
				КлючиАвторизацииВБазе(),
				РабочийПроцесс["process"]);
				
	Лог.Информация("Получаю список соединений...");
	Возврат РазобратьПоток(ЗапуститьПроцесс(КомандаЗапускаСоединения));
	
КонецФункции

Функция РазорватьСоединениеСПроцессом(Знач РабочийПроцесс, Знач Соединение)
	
	КомандаРазрывСоединения = СтрокаЗапускаКлиента() + СтрШаблон("connection disconnect --cluster=""%1""%2 --infobase=%3%4 --process=%5 --connection=%6",
						ИдентификаторКластера(), 
						КлючиАвторизацииВКластере(),
						ИдентификаторБазы(),
						КлючиАвторизацииВБазе(),
						РабочийПроцесс["process"],
						Соединение["connection"]);
	
	Сообщение = СтрШаблон("Отключаю соединение %1 [%2] (%3)",
					Соединение["conn-id"],
					Соединение["app-id"],
					Соединение["user-name"]);
					
	Лог.Информация(Сообщение);
	
	Возврат ЗапуститьПроцесс(КомандаРазрывСоединения);
	
КонецФункции

Функция РазобратьПоток(Знач Поток) Экспорт
	
	ТД = Новый ТекстовыйДокумент;
	ТД.УстановитьТекст(Поток);
	
	СписокОбъектов = Новый Массив;
	ТекущийОбъект = Неопределено;
	
	Для Сч = 1 По ТД.КоличествоСтрок() Цикл
		
		Текст = ТД.ПолучитьСтроку(Сч);
		Если ПустаяСтрока(Текст) или ТекущийОбъект = Неопределено Тогда
			Если ТекущийОбъект <> Неопределено и ТекущийОбъект.Количество() = 0 Тогда
				Продолжить; // очередная пустая строка подряд
			КонецЕсли;
			 
			ТекущийОбъект = Новый Соответствие;
			СписокОбъектов.Добавить(ТекущийОбъект);
		КонецЕсли;
		
		СтрокаРазбораИмя      = "";
		СтрокаРазбораЗначение = "";
		
		Если РазобратьНаКлючИЗначение(Текст, СтрокаРазбораИмя, СтрокаРазбораЗначение) Тогда
			ТекущийОбъект[СтрокаРазбораИмя] = СтрокаРазбораЗначение;
		КонецЕсли;
		
	КонецЦикла;
	
	Если ТекущийОбъект <> Неопределено и ТекущийОбъект.Количество() = 0 Тогда
		СписокОбъектов.Удалить(СписокОбъектов.ВГраница());
	КонецЕсли; 
	
	Возврат СписокОбъектов;
	
КонецФункции

Функция ПолучитьПутьКRAC(ТекущийПуть, Знач ВерсияПлатформы="")
	
	Если НЕ ПустаяСтрока(ТекущийПуть) Тогда 
		ФайлУтилиты = Новый Файл(ТекущийПуть);
		Если ФайлУтилиты.Существует() Тогда 
			Лог.Отладка("Текущая версия rac "+ФайлУтилиты.ПолноеИмя);
			Возврат ФайлУтилиты.ПолноеИмя;
		КонецЕсли;
	КонецЕсли;
	
	Если ПустаяСтрока(ВерсияПлатформы) Тогда 
		ВерсияПлатформы="8.3";
	КонецЕсли;
	
	Конфигуратор = Новый УправлениеКонфигуратором;
	ПутьКПлатформе = Конфигуратор.ПолучитьПутьКВерсииПлатформы(ВерсияПлатформы);
	Лог.Отладка("Используемый путь для поиска rac "+ПутьКПлатформе);
	КаталогУстановки = Новый Файл(ПутьКПлатформе);
	Лог.Отладка(КаталогУстановки.Путь);
	
	
	ИмяФайла = ?(ЭтоWindows, "rac.exe", "rac");
	
	ФайлУтилиты = Новый Файл(ОбъединитьПути(Строка(КаталогУстановки.Путь), ИмяФайла));
	Если ФайлУтилиты.Существует() Тогда 
		Лог.Отладка("Текущая версия rac "+ФайлУтилиты.ПолноеИмя);
		Возврат ФайлУтилиты.ПолноеИмя;
	КонецЕсли;
	
	Возврат ТекущийПуть;

КонецФункции

Функция РазобратьНаКлючИЗначение(Знач СтрокаРазбора, Ключ, Значение)
	
	ПозицияРазделителя = Найти(СтрокаРазбора,":");
	Если ПозицияРазделителя = 0 Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Ключ     = СокрЛП(Лев(СтрокаРазбора,ПозицияРазделителя-1));
	Значение = СокрЛП(Сред(СтрокаРазбора,ПозицияРазделителя+1));
	
	Возврат Истина;
	
КонецФункции

/////////////////////////////////////////////////////////////////////////////////
// Служебные процедуры

Функция КлючиАвторизацииВБазе()
	КлючиАвторизацииВБазе = "";
	Если ЗначениеЗаполнено(мНастройки.АдминистраторИБ) Тогда
		КлючиАвторизацииВБазе = КлючиАвторизацииВБазе + СтрШаблон(" --infobase-user=""%1""", мНастройки.АдминистраторИБ);
	КонецЕсли;
	
	Если ЗначениеЗаполнено(мНастройки.ПарольАдминистратораИБ) Тогда
		КлючиАвторизацииВБазе = КлючиАвторизацииВБазе + СтрШаблон(" --infobase-pwd=""%1""", мНастройки.ПарольАдминистратораИБ);
	КонецЕсли;
	
	Возврат КлючиАвторизацииВБазе;
	
КонецФункции


Функция ИдентификаторКластера()

	Если мИдентификаторКластера = Неопределено Тогда
		Лог.Информация("Получаю список кластеров");
		
	   КомандаВыполнения = СтрокаЗапускаКлиента() + "cluster list";
	   
	   СписокКластеров = ЗапуститьПроцесс(КомандаВыполнения);
	   
	   УИДКластера = Сред(СписокКластеров,(Найти(СписокКластеров,":")+1),Найти(СписокКластеров,"host")-Найти(СписокКластеров,":")-1);	
	   мИдентификаторКластера = СокрЛП(СтрЗаменить(УИДКластера,Символы.ПС,""));
		
	КонецЕсли;
	
	Если ПустаяСтрока(мИдентификаторКластера) Тогда
		ВызватьИсключение "Кластер серверов отсутствует";
	КонецЕсли;
	
	Возврат мИдентификаторКластера;

КонецФункции

Функция ИдентификаторБазы()
	Если мИдентификаторБазы = Неопределено Тогда
		мИдентификаторБазы = НайтиБазуВКластере();
	КонецЕсли;
	
	Возврат мИдентификаторБазы;
КонецФункции

Функция НайтиБазуВКластере()
	
	КомандаВыполнения = СтрокаЗапускаКлиента() + СтрШаблон("infobase summary list --cluster=""%1""%2",
		ИдентификаторКластера(), 
		КлючиАвторизацииВКластере());

	Лог.Информация("Получаю список баз кластера");
	
	СписокБазВКластере = ЗапуститьПроцесс(КомандаВыполнения);    
	ЧислоСтрок = СтрЧислоСтрок(СписокБазВКластере);
	НайденаБазаВКластере = Ложь;
	Для К = 1 По ЧислоСтрок Цикл
		
		СтрокаРазбора = СтрПолучитьСтроку(СписокБазВКластере,К);   
		ПозицияРазделителя = Найти(СтрокаРазбора,":");
		Если Найти(СтрокаРазбора,"infobase")>0 Тогда						
			УИДИБ =  СокрЛП(Сред(СтрокаРазбора,ПозицияРазделителя+1));	
		ИначеЕсли Найти(СтрокаРазбора,"name")>0 Тогда 
			 ИмяБазы = СокрЛП(Сред(СтрокаРазбора,ПозицияРазделителя+1));
			 Если Нрег(ИмяБазы) = НРег(мНастройки.ИмяБазыДанных) Тогда
				Лог.Информация("Получен УИД базы");
				НайденаБазаВКластере = Истина;
				Прервать;
			 КонецЕсли;
		КонецЕсли;
		
	КонецЦикла;
	Если Не НайденаБазаВКластере Тогда
		ВызватьИсключение "База "+мНастройки.ИмяБазыДанных +" не найдена в кластере";
	КонецЕсли;
	
	Возврат УИДИБ;
	
КонецФункции

Функция КлючиАвторизацииВКластере()
	КомандаВыполнения = "";
	Если ЗначениеЗаполнено(мНастройки.АдминистраторКластера) Тогда
		КомандаВыполнения = КомандаВыполнения + СтрШаблон(" --cluster-user=""%1""", мНастройки.АдминистраторКластера);
	КонецЕсли;
	
	Если ЗначениеЗаполнено(мНастройки.ПарольАдминистратораКластера) Тогда
		КомандаВыполнения = КомандаВыполнения + СтрШаблон(" --cluster-pwd=""%1""", мНастройки.ПарольАдминистратораКластера);
	КонецЕсли;
	Возврат КомандаВыполнения;
КонецФункции

Функция СтрокаЗапускаКлиента()
	Перем ПутьКлиентаАдминистрирования;
	Если ЭтоWindows Тогда 
		ПутьКлиентаАдминистрирования = ЗапускПриложений.ОбернутьВКавычки(мНастройки.ПутьКлиентаАдминистрирования);
	Иначе
		ПутьКлиентаАдминистрирования = мНастройки.ПутьКлиентаАдминистрирования;
	КонецЕсли;
	
	Возврат  ПутьКлиентаАдминистрирования + " " + 
			мНастройки.АдресСервераАдминистрирования + " "; 
КонецФункции

Функция ЗапуститьПроцесс(Знач СтрокаВыполнения)
	Перем ПаузаОжиданияЧтенияБуфера;
	
	ПаузаОжиданияЧтенияБуфера = 10;
	
	Лог.Отладка(СтрокаВыполнения);
	Процесс = СоздатьПроцесс(СтрокаВыполнения,,Истина);
	Процесс.Запустить();
	
	ТекстБазовый = "";
	Счетчик = 0; МаксСчетчикЦикла = 100000;
	
	Пока Истина Цикл 
		Текст = Процесс.ПотокВывода.Прочитать();
		Лог.Отладка("Цикл ПотокаВывода "+Текст);
		Если Текст = Неопределено ИЛИ ПустаяСтрока(СокрЛП(Текст))  Тогда 
			Прервать;
		КонецЕсли;
		Счетчик = Счетчик + 1;
		Если Счетчик > МаксСчетчикЦикла Тогда 
			Прервать;
		КонецЕсли;
		ТекстБазовый = ТекстБазовый + Текст;
		
		sleep(ПаузаОжиданияЧтенияБуфера); //Подождем, надеюсь буфер не переполнится. 
		
	КонецЦикла;
	
	Процесс.ОжидатьЗавершения();
	
	Если Процесс.КодВозврата = 0 Тогда
		Текст = Процесс.ПотокВывода.Прочитать();
		ТекстБазовый = ТекстБазовый + Текст;
		Лог.Отладка(ТекстБазовый);
		Возврат ТекстБазовый;
	Иначе
		ВызватьИсключение "Сообщение от RAS/RAC 
		|" + Процесс.ПотокОшибок.Прочитать();
	КонецЕсли;	

КонецФункции

/////////////////////////////////////////////////////////////////////////////////
СистемнаяИнформация = Новый СистемнаяИнформация;
ЭтоWindows = Найти(НРег(СистемнаяИнформация.ВерсияОС), "windows") > 0;
Лог = Логирование.ПолучитьЛог("vanessa.app.deployka");