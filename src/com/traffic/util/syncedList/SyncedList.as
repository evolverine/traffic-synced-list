package com.traffic.util.syncedList
{
	import mx.collections.ArrayCollection;
	import mx.collections.ISort;
	
	public class SyncedList extends ArrayCollection
	{
		protected var _syncRobot:SyncedListRobot;
		
		public function SyncedList(robot:SyncedListRobot)
		{
			super(null);
			syncRobot = robot;
		}

		private function set syncRobot(value:SyncedListRobot):void
		{
			_syncRobot = value;
			
			if(_syncRobot)
			{
				_syncRobot.sync_internal::destination = this;
				_syncRobot.sync();
			}
		}
		
		override public function set sort(s:ISort):void
		{
			if(_syncRobot && !_syncRobot.canUniquelyLocateDestinationBySource)
				throw new Error("Untraceable SyncedList cannot be sorted because deletions won't work.");
			
			super.sort = s;
		}
		
		public function dispose():void
		{
			_syncRobot.dispose();
		}
	}
}