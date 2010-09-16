//http://habrahabr.ru/blogs/adobe_air/73311/

package
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.FlexGlobals;

      // Необходима для указания пути к файлу БД
	
	public class LiteDB
	{
		private var cnam:String = FlexGlobals.topLevelApplication.className;
		// Указываем путь к файлу БД (В нашем случае это рабочий стол)
		private var dbFile:File = File.applicationDirectory.resolvePath(cnam + ".dat");
		private var DBConnection:SQLConnection = null;
		
		public function LiteDB()
		{
			DBConnection = new SQLConnection();          // Коннектимся к базе
			DBConnection.addEventListener(SQLErrorEvent.ERROR, DBError);   // Добавляем обработчик события возникающего при соединении
			DBConnection.addEventListener(SQLEvent.OPEN, DBOpen);          // Добавляем обработчик события возникающего при удачном соединении
			DBConnection.open(dbFile);                                     // Собственно инициализируем открытие базы
		}			
		
		public function TestCreateDB():void {
			var GroupsTable:String = "CREATE TABLE IF NOT EXISTS groups (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT)";
			
			var statement:SQLStatement = new SQLStatement();          // Создаем объект
			statement.sqlConnection = DBConnection;                   // Указываем базу по отношению к которой будем выполнять запрос
			statement.text = GroupsTable;                             // Указываем текст запроса
			statement.addEventListener(SQLErrorEvent.ERROR, DBError); // Добавляем обработчик события возникающего при соединении
			statement.addEventListener(SQLEvent.RESULT, TableResult); // Добавляем обработчик события возникающего при успешном создании таблицы
			statement.execute();                                      // Инициализируем обработку запроса
			
			var PeoplesTable:String = "CREATE TABLE peoples (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, lname TEXT, fname TEXT, ffname TEXT, date TEXT, group_id INTEGER)";
			
			var statement1:SQLStatement = new SQLStatement();            // Создаем объект
			statement1.sqlConnection = DBConnection;                     // Указываем базу по отношению к которой будем выполнять запрос
			statement1.text = PeoplesTable;                              // Указываем текст запроса
			statement1.addEventListener(SQLErrorEvent.ERROR, DBError);   // Добавляем обработчик события возникающего при соединении
			statement1.addEventListener(SQLEvent.RESULT, TableResult);   // Добавляем обработчик события возникающего при успешном создании таблицы
			statement1.execute();                                        // Инициализируем обработку запроса

			var InsertIntoPeoples:String = "INSERT INTO peoples (lname, fname, ffname, date, group_id) VALUES (@column0, @column1, @column2, @column3, @column4)";
			
			var LNameArray :Array = ["Иванов", "Сидоров", "Козлов", "Игнатенко", "Борьщев", "Кольченко", "Бузякин"];
			var FNameArray :Array = ["Иван", "Николай", "Артем", "Игорь", "Сергей", "Борис", "Алексей"];
			var FFNameArray:Array = ["Алексеевич", "Борисович", "Игоревич", "Артемович", "Николаевич", "Иванович", "Сергеевич"];
			
			var statement2:SQLStatement = new SQLStatement();
			statement2.sqlConnection = DBConnection;
			statement2.text = InsertIntoPeoples;
			statement2.addEventListener(SQLErrorEvent.ERROR, DBError);
			statement2.addEventListener(SQLEvent.RESULT, InsertResult);
			
			for(var j:Number = 0; j < 100; j++)
			{
				statement2.parameters["@column0"] = LNameArray[Math.round(Math.random() * 6)];
				statement2.parameters["@column1"] = FNameArray[Math.round(Math.random() * 6)];
				statement2.parameters["@column2"] = FFNameArray[Math.round(Math.random() * 6)];
				statement2.parameters["@column3"] = (Math.round(Math.random() * 30) + 1) + ':' + (Math.round(Math.random() * 11) + 1) + ':' + (Math.round(Math.random() * 2009) + 1);
				statement2.parameters["@column4"] = Math.round(Math.random() * 3);
				statement2.execute();
			}
			
			var q:String = "SELECT * FROM groups ORDER BY name";
			
			var getGroupStat:SQLStatement = new SQLStatement();
			getGroupStat.sqlConnection = DBConnection;
			getGroupStat.text = q;
			getGroupStat.addEventListener(SQLErrorEvent.ERROR, DBError);
			getGroupStat.addEventListener(SQLEvent.RESULT, GetGroupResult);
			getGroupStat.execute();			
		}
		
		/**
		 * Эта функция обрабатывает ошибки соединения
		 */
		private function DBError(e:SQLErrorEvent):void
		{
			trace("Error message: ", e.error.message);
			trace("Details: ", e.error.details);
		}
		
		/**
		 * Эта функция обрабатывает удачное соединение
		 */
		private function DBOpen(e:SQLEvent):void
		{
			trace(e.type /*"The database was created successfully"*/);
		}
		
		/**
		 * Эта функция обрабатывает удачное создание таблицы
		 */
		private function TableResult(e:SQLEvent):void
		{
			trace("Table created");
		}

		/**
		 * Эта функция обрабатывает удачное добавление данных в таблицу
		 */
		private function InsertResult(e:SQLEvent):void
		{
			trace("Add to table successfully");
		}		

		/**
		 * Обрабатывает результат выполнения функции GetGroup().
		 */
		private function GetGroupResult(e:SQLEvent):void
		{
			var result:SQLResult = e.target.getResult();
			
			var GroupArray:ArrayCollection = new ArrayCollection();
			
			if(result.data)
				for(var i:Number = 0; i < result.data.length; i++)
					GroupArray.addItem(result.data[i]);
		}	
	}
}
