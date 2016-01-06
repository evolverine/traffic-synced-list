package com.traffic.util
{
	import com.adobe.cairngorm.contract.Contract;

	import mx.collections.ICollectionView;

	public class CollectionUtils
	{
		public static function isSortedOrFiltered(collection:ICollectionView):Boolean
		{
			Contract.precondition(collection != null);
			
			return collection.sort || collection.filterFunction != null;
		}
	}
}
