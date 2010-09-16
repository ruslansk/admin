package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.system.System;
	
	import mx.collections.ArrayCollection;

	public class Torneo extends EventDispatcher
	{
		private var uldr:URLLoader = new URLLoader();
		private var cookie:String = "";
		public  var cols:Array = new Array();
		public  var list:ArrayCollection = new ArrayCollection();
		public static const COMPLETE:String = "trnComplete";
		
		[Event(name="complete", type="Torneo")]
		
		public function Torneo()
		{
			uldr.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onStatus);
			uldr.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
			System.useCodePage = true;
		}

		public function Login():void {
			cookie = "";
			uldr.dataFormat = URLLoaderDataFormat.TEXT;
			var uReq:URLRequest = new URLRequest("http://localhost/admin/phone.php?area=login");
			uReq.manageCookies = false;
			uReq.followRedirects = false;
			uReq.data = "username=rus&password=zse&login=true";
			uReq.method = URLRequestMethod.POST;
			uldr.load(uReq);
		}
		
		public function Logout():void {
			uldr.dataFormat = URLLoaderDataFormat.TEXT;
			var uReq:URLRequest = new URLRequest("http://localhost/admin/phone.php?area=logout");
			uReq.manageCookies = false;
			uReq.followRedirects = false;
			//uReq.useCache = false;
			//uReq.cacheResponse = false;
			if(cookie!="") {
				var cookie2:String = new String(cookie); 
				uReq.requestHeaders.push(new URLRequestHeader("Cookie", cookie2));
				cookie = "";
			}
			uldr.load(uReq);
		}
		
		public function List():void {
			uldr.dataFormat = URLLoaderDataFormat.TEXT;
			var uReq:URLRequest = new URLRequest("http://localhost/admin/phone.php?action=list_phone&srch=*");
			uReq.manageCookies = false;
			if(cookie!="") {
				uReq.requestHeaders.push(new URLRequestHeader("Cookie", cookie));
			}
			uldr.load(uReq);
		}
		
		private function onComplete(e:Event):void {
			trace("onComplete");
			trace(e.target.data);
			if(e.target.data=="") return;
			
			var x:XML = new XML(e.target.data);
			var xxx:XMLList = x.data.table.thead.tr.th;
			if(xxx.length()==0) return;
			
			cols = new Array();
			for(var k:uint=0; k<xxx.length(); k++) {
				cols.push(xxx[k].toString());
			}
			
			var xx:XMLList = x.data.table.tbody.tr;

			list.removeAll();
			for(var i:uint=0; i<xx.length(); i++) {
				var yy:Object = new Object();
				var xxxx:XMLList = xx[i].td;
				for(var j:uint=0; j<xxxx.length(); j++) {
					yy[xxx[j].toString()] = xxxx[j].toString();
				}
				list.addItem(yy);
			}
			
			dispatchEvent(new Event(COMPLETE));
		}
		
		private function onStatus(event:HTTPStatusEvent):void {
			trace("onStatus");
			for(var i:uint=0; i<event.responseHeaders.length; i++) {
				if(event.responseHeaders[i].name == "Set-Cookie") {
					var ss:String = event.responseHeaders[i].value;
					var aa:Array = ss.split(";");
					if(aa.length>0) {
						var aaa:Array = aa[0].split("=");
						if(aaa[1]!="deleted") {
							if(cookie!="") cookie += "; ";
							cookie += aa[0];
							trace(cookie);
						} else {
							cookie = "";
							trace("cookie is cleared");
						}
					}
				}
			}
		}
	}
}