package com.traffic.util.syncedList
{
    import com.adobe.cairngorm.contract.Contract;
    import com.traffic.interfaces.IDisposable;
    import com.traffic.util.CollectionUtils;

    import mx.collections.ArrayList;
    import mx.collections.ICollectionView;
    import mx.collections.IList;
    import mx.collections.ListCollectionView;
    import mx.events.CollectionEvent;
    import mx.events.CollectionEventKind;
    import mx.events.PropertyChangeEvent;

    public class SyncedListRobot implements IDisposable
	{
		private var _source:IList;
		private var _factory:IDataToObjectFactory;
		private var _destination:SyncedList;
		private var _recreateObjectInDestinationOnSourceObjectUpdate:Boolean = true;
		private var _canUniquelyLocateDestinationBySource:Boolean = false;
		
		public function SyncedListRobot(source:IList, factory:IDataToObjectFactory, canFindDestinationBySource:Boolean = false)
		{
			sourceList = source;
			_factory = factory;
			_canUniquelyLocateDestinationBySource = canFindDestinationBySource;
		}

		public function get canUniquelyLocateDestinationBySource():Boolean
		{
			return _canUniquelyLocateDestinationBySource;
		}

		public function set recreateObjectInDestinationOnSourceObjectUpdate(value:Boolean):void
		{
			_recreateObjectInDestinationOnSourceObjectUpdate = value;
		}

		public function set sourceList(value:IList):void
		{
			if(_source == value)
				return;
			
			if(_source)
				_source.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onSourceChanged);
			
			_source = value;
			
			if(_source)
				_source.addEventListener(CollectionEvent.COLLECTION_CHANGE, onSourceChanged);
		}
		
		sync_internal function set destination(value:SyncedList):void
		{
			_destination = value;
		}
		
		public function sync():void
		{
			reset();
		}
		
		private function onSourceChanged(event:CollectionEvent):void
		{
			switch(event.kind)
			{
				case CollectionEventKind.ADD:
					addItems(event.items, event.location);
					break;
				
				case CollectionEventKind.MOVE:
					moveItems(event.items, event.oldLocation, event.location);                        
					break;
				
				case CollectionEventKind.RESET:
					reset();
					break;
				
				case CollectionEventKind.REMOVE:
					removeItems(event.items, event.location);
					break;
				
				case CollectionEventKind.REPLACE:
					replaceItems(event.items, event.location);
					break;
				
				case CollectionEventKind.REFRESH:
					reset();
					break;
				
				case CollectionEventKind.UPDATE:
					handlePropertyChangeEvents(event.items);
					break;
			}
		}
		
		public function dispose():void
		{
			sourceList = null;
			_factory = null;
			_destination = null;
		}
		
		private function removeItems(items:Array, location:int):void
		{
			if(!canUniquelyLocateDestinationBySource)
			{
				const indexesDifferentInSourceAndDestination:Boolean = _destination is ICollectionView && CollectionUtils.isSortedOrFiltered(ICollectionView(_destination));
				if(!indexesDifferentInSourceAndDestination)
					removeItemsFromDestination(items, location);
			}
			else
				removeItemsByTracingThemInDestination(items, location);
		}
		
		private function removeItemsFromDestination(items:Array, location:int):void
		{
			Contract.precondition(items != null);
			Contract.precondition(!(_destination is ICollectionView) || !CollectionUtils.isSortedOrFiltered(ICollectionView(_destination)));
			
			var i:int = items.length;
			if(!i)
				return;
			
			while(--i >= 0)
			{
				if((_destination.length > location) && (_destination.getItemAt(location) != -1))
					_destination.removeItemAt(location);
			}
		}
		
		private function removeItemsByTracingThemInDestination(items:Array, location:int):void
		{
			Contract.precondition(items != null);
			
			var i:int = items.length;
			if(!i)
				return;
			
			while(--i >= 0)
			{
				var destinationIndex:int = _destination.getItemIndex(locateDestinationBySourceImpl(items[i]));
				if(destinationIndex != -1)
					_destination.removeItemAt(destinationIndex);
				else
				{
					destinationIndex = _destination.list.getItemIndex(locateDestinationBySourceInUnfilteredList(items[i]));
					if(destinationIndex != -1)
						_destination.list.removeItemAt(destinationIndex);
				}
			}
		}
		
		/**
		 * Override this in your implementation of the SyncedListRobot to
		 * enable synced deletions.
		 */
		public function locateDestinationBySource(sourceObject:Object, inIerableList:IList):Object
		{
			return null;
		}
		
		/**
		 * Due to https://issues.apache.org/jira/browse/FLEX-15159 we cannot iterate ArrayLists with for..each
		 */
		private function locateDestinationBySourceInUnfilteredList(sourceObject:Object):Object
		{
			return locateDestinationBySource(sourceObject, _destination.list is ArrayList ? new ListCollectionView(_destination.list) : _destination.list);
		}
		
		private function locateDestinationBySourceImpl(sourceObject:Object):Object
		{
			return locateDestinationBySource(sourceObject, _destination);
		}
		
		private function addItems(items:Array, location:int):void
		{
			Contract.precondition(items != null);
			const indexesDifferentInSourceAndDestination:Boolean = _destination is ICollectionView && CollectionUtils.isSortedOrFiltered(ICollectionView(_destination));
			
			for (var i:int = 0; i < items.length; i++)
			{
				var newItem:Object = _factory.newInstance(items[i]);
				if(indexesDifferentInSourceAndDestination)
					_destination.list.addItemAt(newItem, location);
				else
					_destination.addItemAt(newItem, location);
			}
		}
		
		private function moveItems(items:Array, oldLocation:int, newLocation:int):void
		{
			Contract.precondition(items != null);
			const indexesDifferentInSourceAndDestination:Boolean = _destination is ICollectionView && CollectionUtils.isSortedOrFiltered(ICollectionView(_destination));
			
			if(!indexesDifferentInSourceAndDestination)
			{
				var i:int = 0;
				if(oldLocation > newLocation)
				{
					for (i = 0; i < items.length; i++)
						if(_destination.getItemAt(oldLocation + i))
							_destination.addItemAt(_destination.removeItemAt(oldLocation + i), newLocation + i);
				}
				else if(oldLocation < newLocation)
					for (i = items.length - 1; i >= 0; i--)
						if(_destination.getItemAt(oldLocation + i))
							_destination.addItemAt(_destination.removeItemAt(oldLocation + i), newLocation + i);
			}
		}
		
		private function handlePropertyChangeEvents(events:Array):void
		{
			Contract.precondition(events != null);
			
			if(!_recreateObjectInDestinationOnSourceObjectUpdate)
				return;
			
			const indexesDifferentInSourceAndDestination:Boolean = _destination is ICollectionView && CollectionUtils.isSortedOrFiltered(ICollectionView(_destination));
			
			if(indexesDifferentInSourceAndDestination && !canUniquelyLocateDestinationBySource)
				return;
			
			for each(var event:PropertyChangeEvent in events)
			{
				var oldSourceItem:Object = event.source;
				var newDestinationItem:Object = _factory.newInstance(getFactoryInputFromObject(oldSourceItem));
				
				replaceItem(_source.getItemIndex(oldSourceItem), newDestinationItem, oldSourceItem);
			}
		}
		
		/**
		 * (From ListCollectionView.replaceItemsInView)
		 * Items is an array of PropertyChangeEvents so replace the oldValues with the new
		 * newValues.  Start at the location specified and move forward, it's unlikely
		 * that the length of items is > 1.
		 */
		private function replaceItems(events:Array, locationInSource:int):void
		{
			Contract.precondition(events != null);
			
			const indexesDifferentInSourceAndDestination:Boolean = _destination is ICollectionView && CollectionUtils.isSortedOrFiltered(ICollectionView(_destination));
			
			if(indexesDifferentInSourceAndDestination && !canUniquelyLocateDestinationBySource)
				return;
			
			for (var i:int = 0; i < events.length; i++)
			{
				var oldSourceItem:Object = PropertyChangeEvent(events[i]).oldValue;
				var newSourceItem:Object = PropertyChangeEvent(events[i]).newValue;
				var newDestinationItem:Object = _factory.newInstance(getFactoryInputFromObject(newSourceItem));
				
				replaceItem(locationInSource, newDestinationItem, oldSourceItem);
			}
		}
		
		private function replaceItem(locationInSource:int, newDestinationItem:Object, oldSourceItem:Object):void
		{
			var locationInDestination:int = locationInSource;
			const indexesDifferentInSourceAndDestination:Boolean = _destination is ICollectionView && CollectionUtils.isSortedOrFiltered(ICollectionView(_destination));
			
			if(indexesDifferentInSourceAndDestination && !canUniquelyLocateDestinationBySource)
				return;
			
			var destinationItemCurrentlyFilteredOut:Boolean = false;
			
			if(indexesDifferentInSourceAndDestination && canUniquelyLocateDestinationBySource)
			{
				var oldDestinationItem:Object = locateDestinationBySourceImpl(oldSourceItem) || locateDestinationBySourceInUnfilteredList(oldSourceItem);
				
				locationInDestination = _destination.getItemIndex(oldDestinationItem);
				if(locationInDestination == -1)
				{
					destinationItemCurrentlyFilteredOut = true;
					locationInDestination = _destination.list.getItemIndex(oldDestinationItem);
				}
			}
			
			if(locationInDestination != -1)
			{
				if(destinationItemCurrentlyFilteredOut)
					_destination.list.setItemAt(newDestinationItem, locationInDestination);
				else
					_destination.setItemAt(newDestinationItem, locationInDestination);
			}
			else
				_destination.addItem(newDestinationItem);
		}
		
		private function reset():void
		{
			Contract.precondition(_source != null);
			Contract.precondition(_destination != null);
			Contract.precondition(_factory != null);
			
			_destination.removeAll();
			
			for (var i:int = 0; i < _source.length; i++)
				_destination.addItem(_factory.newInstance(getFactoryInputFromObject(_source.getItemAt(i))));
		}
		
		
		/**
		 * You can override this in your robot implementation to select the information which
		 * your factory needs. E.g. subsets of the input object, or calculations of one or
		 * more of its properties.
		 */
		protected function getFactoryInputFromObject(object:Object):Object
		{
			return object;
		}
	}
}