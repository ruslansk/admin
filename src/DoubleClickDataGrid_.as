package
{
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	//import itemRenderers.RollOverItemRenderer;
	
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.listClasses.IDropInListItemRenderer;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.events.DataGridEvent;
	
	/** 
	 *  DataGrid that only allows editing if you double click
	 *  Component sourced from: http://blogs.adobe.com/aharui/2008/03/datagrid_doubleclick_to_edit.html
	 */
	public class DoubleClickDataGrid_ extends DataGrid
	{
		private var currentItemRenderer:IListItemRenderer;
		
		public function DoubleClickDataGrid_()
		{
			super();
			doubleClickEnabled = true;
			addEventListener(KeyboardEvent.KEY_UP, handleKeyUp); 
		}
		
		private function handleKeyUp(event:KeyboardEvent):void
		{
			var dataGridEvent:DataGridEvent;
			var r:IListItemRenderer;
			var dgColumn:DataGridColumn;
			
			r = currentItemRenderer;
			if (r && r != itemEditorInstance)
			{
				var dilr:IDropInListItemRenderer = IDropInListItemRenderer(r);
				if (columns[dilr.listData.columnIndex].editable)
				{
					dgColumn = columns[dilr.listData.columnIndex];
					dataGridEvent = new DataGridEvent(DataGridEvent.ITEM_EDIT_BEGINNING, false, true);
					// ITEM_EDIT events are cancelable
					dataGridEvent.columnIndex = dilr.listData.columnIndex;
					dataGridEvent.dataField = dgColumn.dataField;
					dataGridEvent.rowIndex = dilr.listData.rowIndex + verticalScrollPosition;
					dataGridEvent.itemRenderer = r;
					dispatchEvent(dataGridEvent);
				}
			}
		}
		
		override protected function mouseDoubleClickHandler(event:MouseEvent):void
		{
			var dataGridEvent:DataGridEvent;
			var r:IListItemRenderer;
			var dgColumn:DataGridColumn;
			
			r = mouseEventToItemRenderer(event);
			if (r && r != itemEditorInstance)
			{
				var dilr:IDropInListItemRenderer = IDropInListItemRenderer(r);
				if (columns[dilr.listData.columnIndex].editable)
				{
					dgColumn = columns[dilr.listData.columnIndex];
					dataGridEvent = new DataGridEvent(DataGridEvent.ITEM_EDIT_BEGINNING, false, true);
					// ITEM_EDIT events are cancelable
					dataGridEvent.columnIndex = dilr.listData.columnIndex;
					dataGridEvent.dataField = dgColumn.dataField;
					dataGridEvent.rowIndex = dilr.listData.rowIndex + verticalScrollPosition;
					dataGridEvent.itemRenderer = r;
					dispatchEvent(dataGridEvent);
				}
			}
			
			super.mouseDoubleClickHandler(event);
		}
		
		override protected function mouseUpHandler(event:MouseEvent):void
		{
			var r:IListItemRenderer;
			var dgColumn:DataGridColumn;
			
			r = mouseEventToItemRenderer(event);
			currentItemRenderer = r;
			if (r)
			{
				var dilr:IDropInListItemRenderer = IDropInListItemRenderer(r);
				if (dilr.listData!=null && columns[dilr.listData.columnIndex].editable)
				{
					dgColumn = columns[dilr.listData.columnIndex];
					dgColumn.editable = false;
				}
			}
			
			super.mouseUpHandler(event);
			
			if (dgColumn)
				dgColumn.editable = true;
		}
		
		
		
		
		
	}
	
}