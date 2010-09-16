package
{
	import air.net.ServiceMonitor;
	import air.net.SocketMonitor;
	import air.net.URLMonitor;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemTrayIcon;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Timer;
	import flash.xml.XMLDocument;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.controls.DataGrid;
	import mx.controls.List;
	import mx.controls.Text;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.Application;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.core.WindowedApplication;
	import mx.events.DataGridEvent;
	import mx.events.FlexEvent;
	
	public class Admin extends UIComponent //extends Sprite
	{
		//[IconFile("icon16.png")]
		
		[Embed(source="icon16.png")] 
		private static const Icon16 : Class;

		private var _windowedApplication : WindowedApplication;
		private var showCommand : NativeMenuItem = new NativeMenuItem("Открыть");
		private	var siteCommand : NativeMenuItem = new NativeMenuItem("О программе");
		private	var exitCommand : NativeMenuItem = new NativeMenuItem("Выход");
		
		private var trn:Torneo = new Torneo();
		private var ldb:LiteDB = new LiteDB();
		
		private var log_usr:String;  // логин
		private var pas_usr:String;  // пароль
		private var id_usr:int;      // код пользователя
		private var vhod_var:URLVariables = new URLVariables(); //хранилище переменных для передачи в скрипт
		private var vhod_req:URLRequest = new URLRequest("http://localhost/admin/flex/vhod.php");
		private var vhod_ldr:URLLoader = new URLLoader();
		// шаблон для проверки почтового адреса
		private var mail_mask:RegExp= /([a-zA-Z]?[0-9a-zA-Z]+[-._+&])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,6}/;
		private var login_mask:RegExp = /[a-zA-Z]?[0-9a-zA-Z]*/;
		// шаблон для проверки формата пароля
		private var pass_mask:RegExp = /[a-zA-Z]?[0-9a-zA-Z]*/;
		private var words:Array = new Array;            // массив для хранения разбитых строк
		private var win_tmr:Timer = new Timer(4000, 1); //таймер - определяет как долго будет висеть окно ошибок
		
		public function Admin()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler);
			//_windowedApplication = Application.application as WindowedApplication;
			_windowedApplication = FlexGlobals.topLevelApplication as WindowedApplication;

			FlexGlobals.topLevelApplication.addEventListener(FlexEvent.CREATION_COMPLETE, onCreate);
		}
		
		private function onAddedToStageHandler(event : Event) : void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler);
			if(NativeApplication.supportsSystemTrayIcon) {
				var sysTrayIcon : SystemTrayIcon = NativeApplication.nativeApplication.icon as SystemTrayIcon;
				sysTrayIcon.tooltip = "Админка"; 
				sysTrayIcon.addEventListener(MouseEvent.CLICK, onShowCommand);  
				//////sysTrayIcon.menu = createIconMenu();
				var iconMenu : NativeMenu = new NativeMenu();
				iconMenu.addItem(showCommand);
				showCommand.addEventListener(Event.SELECT, onShowCommand);
				iconMenu.addItem(siteCommand);
				siteCommand.addEventListener(Event.SELECT, onSiteCommand);
				iconMenu.addItem(new NativeMenuItem("", true));
				iconMenu.addItem(exitCommand);
				exitCommand.addEventListener(Event.SELECT, onExitCommand);
				sysTrayIcon.menu = iconMenu;
				////// loadWinIcon();
				NativeApplication.nativeApplication.icon.bitmaps = [new Icon16().bitmapData];
			}
			undock();
		}
		private function onShowCommand(event : Event) : void {
			if(stage.nativeWindow.visible) {
				dock();
			} else {
				undock();
			}
		}
		public function dock(event : Event = null) : void
		{
			stage.nativeWindow.visible = false;
			showCommand.label = "Развернуть";
		} 
		public function undock(event : Event = null) : void
		{
			stage.nativeWindow.visible = true;
			stage.nativeWindow.alwaysInFront = true;
			stage.nativeWindow.x = Capabilities.screenResolutionX - stage.nativeWindow.width - 5;
			stage.nativeWindow.y = Capabilities.screenResolutionY - stage.nativeWindow.height - 35;        
			showCommand.label = "Свернуть";
		}
		private function onSiteCommand(event : Event) : void { /*navigateToURL(new URLRequest("http://drag-n-drop.ru"))*/; }
		private function onExitCommand(event : Event) : void { NativeApplication.nativeApplication.exit(); } 
		
		
		private function onCreate(e:FlexEvent):void {
			//onAddedToStageHandler(e);
			
			vhod_req.method = URLRequestMethod.POST;    //метод POST
			FlexGlobals.topLevelApplication.vhod_btn.addEventListener(MouseEvent.CLICK, onclickiVhod, false, 0, true);    // обработчик нажатия кнопки Вход

			FlexGlobals.topLevelApplication.btnLogin.addEventListener(MouseEvent.CLICK, onClickBtnLogin, false, 0, true);
			FlexGlobals.topLevelApplication.btnList.addEventListener(MouseEvent.CLICK, onClickBtnList, false, 0, true);
			FlexGlobals.topLevelApplication.btnLogout.addEventListener(MouseEvent.CLICK, onClickBtnLogout, false, 0, true);

			trn.addEventListener(Torneo.COMPLETE, trnComplete);
			FlexGlobals.topLevelApplication.dtgr.editable = true;
		}

		private function onClickBtnLogin(e:MouseEvent):void {
			trnDGClear();
			trn.Login();
		}
		
		private function onClickBtnLogout(e:MouseEvent):void {
			trnDGClear();
			trn.Logout();
		}
		
		private function onClickBtnList(e:MouseEvent):void {
			trnDGClear();
			trn.List();
		}
		
		private function trnDGClear():void {
			var dg:DataGrid = FlexGlobals.topLevelApplication.dtgr;
			//dg.removeEventListener(MouseEvent.CLICK, trnDGClick); 
			dg.removeEventListener(DataGridEvent.ITEM_EDIT_END, trnDGDblClick); 
			dg.columns = new Array();
			dg.dataProvider = new ArrayCollection();
			dg.validateNow();
		}

		private function trnComplete(e:Event):void {
			var dg:DataGrid = FlexGlobals.topLevelApplication.dtgr;
			//dg.addEventListener(MouseEvent.CLICK, trnDGClick); 
			dg.addEventListener(DataGridEvent.ITEM_EDIT_END, trnDGDblClick);
			
			var yyy:Array = new Array();
			for(var i:uint=0; i<trn.cols.length; i++) {
				var dgc:DataGridColumn = new DataGridColumn(trn.cols[i]);
				if(i==0) dgc.editable = false;
				yyy.push(dgc);
			}
			dg.columns = yyy;
			dg.dataProvider = trn.list;
			dg.validateNow();

			trace("data loaded sucessfull");
		}

		private function trnDGClick(e:MouseEvent):void {
			trace("clicked");
		}

		private function trnDGDblClick(e:DataGridEvent):void {
			trace("double clicked");
		}
		
		private function onclickiVhod(e:MouseEvent):void {    // обработка нажатия кнопки вход
			if ((FlexGlobals.topLevelApplication.log_it.text == "")||(FlexGlobals.topLevelApplication.uid.text == "")) {        //если какое то поле пустое, то...
				error(-3);
				return;
			}
			/*-----Проверка правильности ввода логина (адреса почты)-----*/    
			words = FlexGlobals.topLevelApplication.log_it.text.split(" ");        // выделяем первое слово из строки (авось ввели 2 или больше)
			log_usr = words[0];
			if (!/*mail_mask*/ login_mask.test(log_usr)) {        // проверка формата
				error(-4);
				return;
			}
			/*-----Проверка правильности пароля (1-я буква и содержит только цыфры и буквы латыни)-----*/
			words = FlexGlobals.topLevelApplication.uid.text.split(" ");        // выделяем первое слово из строки (авось ввели 2 или больше)
			pas_usr = words[0];
			if (!pass_mask.test(pas_usr)) {        // проверка формата
				error(-5);
				return;
			}
			if ((pas_usr.length < 4)||(pas_usr.length > 20)) { // проверка на длинну пароля
				error(-6);
				return;                   
			}
			vhod_ldr.addEventListener(Event.COMPLETE, completeHandler, false, 0, true);     // обработчик загрузки данных из скрипта
			vhod_var.log_usr = log_usr;        //загрузка переменных
			vhod_var.pas_usr = pas_usr;
			vhod_req.data = vhod_var;
			vhod_ldr.dataFormat = URLLoaderDataFormat.TEXT;        // определяем формат получения данных
			try { 
				vhod_ldr.load(vhod_req);     // передаем переменные в скрипт и получаем результат
			} 
			catch (err:Error) { 
				error(-7);     //если неудачно то ошибка
			} 
		}
		
		private function completeHandler(e:Event):void { //обработка результатов от скрипта
			vhod_ldr.removeEventListener(Event.COMPLETE, completeHandler);
			id_usr = int(Number(e.target.data));    //записываем результат как номер пользователя (число больше 0) или код ошибки (- число)
			if (id_usr < 0) {        // обработка кодов ошибок
				error(id_usr); 
				return;
			}
			/*-------- тут будет загрузка и открытие основной swf-игры ---------*/
		}
		
		private function error(cod:int):void {    // вывод сообщений об ошибке
			FlexGlobals.topLevelApplication.vhod_btn.removeEventListener(MouseEvent.CLICK, onclickiVhod);  //отключаем обработку кнопки Вход
			var t:String = "";
			switch (cod) {
				case -1:
					t = "Неудалось подключиться к базе данных. Попробуйте позже.";
					break;
				case -2:
					t = "Такого пользователя не существует. Возможно вы допустили ошибку при вводе данных.";
					break;
				case -3:
					t = "Одно из полей ввода не заполнено. Логин и пароль не должны быть незаполненными.";
					break;
				case -4:
					t = "Неправильный формат адреса почты";
					break;
				case -5:
					t = "Неправильный формат пароля. Только латинские буквы и цифры";
					break;
				case -6:
					t = "Некорректная длинна пароля. Допустимая длинна от 4 до 20 символов.";
					break;
				case -7:
					t = "Сервер не доступен.";
					break;
			}
			win_tmr.addEventListener(TimerEvent.TIMER, closeWin, false, 0, true);
			win_tmr.start(); //запускаем таймер для стирания окна ошибок
			FlexGlobals.topLevelApplication.err_txt.text = t;
		}
		
		private function closeWin(e:TimerEvent):void { //убираем окно ошибок
			win_tmr.removeEventListener(TimerEvent.TIMER, closeWin);
			FlexGlobals.topLevelApplication.vhod_btn.addEventListener(MouseEvent.CLICK, onclickiVhod, false, 0, true); // включаем обработку кнопки Вход
			FlexGlobals.topLevelApplication.err_txt.text = "";
		}
	}
}