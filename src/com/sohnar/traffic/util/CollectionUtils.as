package com.sohnar.traffic.util
{
	import com.adobe.cairngorm.contract.Contract;
	
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	
	public class CollectionUtils
	{
		
		/*============================================================================*/
		/*= STATIC PUBLIC METHODS                                                     */
		/*============================================================================*/
		
		/**
		 * <p>Searches through a collection and returns a new collection with the search results included.
		 * It asks the searched items to return a string which concatenates all the values
		 * of the properties and member objects' properties represented by the paths Array of Strings.</p>
		 *
		 * @return ManagedCollection for this collection
		 */
		public static function searchThroughCollection(collection:IList, term:String, paths:Array, caseInsensitive:Boolean = true, limitSearchTo:Number = Number.MAX_VALUE):Array
		{
			var results:Array = [];
			var stringToSearchThrough:String;
			
			if (caseInsensitive)
				term = term.toLowerCase();
			
			for each (var item:Object in collection)
			{
				if (!item)
					continue;
				
				stringToSearchThrough = ClassUtils.getConcatenatedPropertiesString(item, paths, " ");
				
				if (!stringToSearchThrough)
					continue;
				
				if (caseInsensitive)
					stringToSearchThrough = stringToSearchThrough.toLowerCase();
				
				if (stringToSearchThrough.indexOf(term) == -1)
					continue;
				
				
				
				results.push(item);
				
				if (--limitSearchTo <= 0)
					break;
			}
			
			return results;
		}
		
		public static function hasItemByKeyValue(collection:ListCollectionView, key:String, value:*):Boolean
		{
			for each (var item:Object in collection)
			{
				if (item.hasOwnProperty(key) && item[key] == value)
					return true;
			}
			
			return false;
		}
		
		public static function getItemByKeyValue(collection:ListCollectionView, key:String, value:*):Object
		{
			for each (var item:Object in collection)
			{
				if (item.hasOwnProperty(key) && item[key] == value)
					return item;
			}
			
			return null;
		}
		
		public static function getItemsByKeyValue(collection:ListCollectionView, key:String, value:*):Array
		{
			var output:Array = [];
			var item:Object;
			
			for each (item in collection)
			{
				if (item.hasOwnProperty(key) && item[key] == value)
					output.push(item);
			}
			
			return output;
		}
		/**
		 * TFC-9678, TFC-9938 if a collection is the data provider of a Calendar object and we removeAll()
		 * from it, when addItem() is called on that collection we get that same RTE as in the ticket.
		 * This function avoids that issue.
		 */ 
		public static function clearCollectionWithoutReset(collection:IList):void
		{
			while(collection.length)
			{
				collection.removeItemAt(0);
			}
		}
		
		public static function removeItem(item:Object, list:IList):Boolean
		{
			var index:int = list.getItemIndex(item);
			return index != -1 ? list.removeItemAt(index) != null : false;
		}
		
		public static function isSortedOrFiltered(collection:ICollectionView):Boolean
		{
			Contract.precondition(collection != null);
			
			return collection.sort || collection.filterFunction != null;
		}
	}
}
