package com.traffic.util.syncedList
{
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import flexunit.framework.Assert;
	
	/**
	 * To understand the logic of these tests,
	 * just keep in mind that basic fact about
	 * alien nutrition: each decade of their
	 * lives aliens increase their daily caloric
	 * intake by 1000 calories:
	 * 
	 * -between 10 and 19 years they eat 1000 calories / day
	 * -between 20 and 29 years they eat 2000 calories / day
	 * -and so on.
	 */
	public class SyncedListTest
	{
		private var _subject:SyncedList;
		
		[Before]
		public function setUp():void
		{
			
		}
		
		[After]
		public function tearDown():void
		{
			_subject = null;
		}
		
		[Test]
		public function testCreation():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(3), new AlienVO(23), new AlienVO(53)]);
			
			//when
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//then
			caloriesShouldMatch(new ArrayList([0, 2000, 5000]), _subject);
		}
		
		[Test]
		public function testAddingAtTheEnd():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(15), new AlienVO(29), new AlienVO(40)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.addItem(new AlienVO(55));
			aliens.addItem(new AlienVO(61));
			
			//then
			Assert.assertEquals(Math.floor((aliens.getItemAt(aliens.length - 1) as AlienVO).age / 10) * 1000, (_subject.getItemAt(_subject.length - 1) as AlienDietVO).calories);
			Assert.assertEquals(Math.floor((aliens.getItemAt(aliens.length - 2) as AlienVO).age / 10) * 1000, (_subject.getItemAt(_subject.length - 2) as AlienDietVO).calories);
		}

		[Test]
		public function testAddingAtTheEndWithFilteredDestination():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(13), new AlienVO(27), new AlienVO(45)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutSmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 4000;}
			_subject.filterFunction = filterOutSmallEaters;
			_subject.refresh();
			
			//when
			aliens.addItem(new AlienVO(55));
			aliens.addItem(new AlienVO(61));
			
			//then
			caloriesShouldMatch(new ArrayList([4000, 5000, 6000]), _subject);
			Assert.assertEquals(Math.floor((aliens.getItemAt(aliens.length - 1) as AlienVO).age / 10) * 1000, (_subject.getItemAt(_subject.length - 1) as AlienDietVO).calories);
			Assert.assertEquals(Math.floor((aliens.getItemAt(aliens.length - 2) as AlienVO).age / 10) * 1000, (_subject.getItemAt(_subject.length - 2) as AlienDietVO).calories);
		}
		
		[Test]
		public function testAddingAtMiddle():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(13), new AlienVO(27), new AlienVO(43)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.addItemAt(new AlienVO(58), 2);
			
			//then
			Assert.assertEquals(58, AlienVO(aliens.getItemAt(2)).age);
			Assert.assertEquals(Math.floor((aliens.getItemAt(2) as AlienVO).age / 10) * 1000, (_subject.getItemAt(2) as AlienDietVO).calories);
		}
		
		[Test]
		public function testAddingAtMiddleWithFilteredDestination():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(12), new AlienVO(25), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutSmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 4000;}
			_subject.filterFunction = filterOutSmallEaters;
			_subject.refresh();
			
			//when
			aliens.addItemAt(new AlienVO(52), 1);
			
			//then
			caloriesShouldMatch(new ArrayList([5000, 4000]), _subject);
			Assert.assertEquals(52, AlienVO(aliens.getItemAt(1)).age);
			Assert.assertEquals(Math.floor((aliens.getItemAt(1) as AlienVO).age / 10) * 1000, (_subject.getItemAt(0) as AlienDietVO).calories);
		}
		
		[Test]
		public function testRemovingOneItem():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(13), new AlienVO(25), new AlienVO(49)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.removeItemAt(1);
			
			//then
			caloriesShouldMatch(new ArrayList([1000, 4000]), _subject);
		}
		
		[Test]
		public function testRemovingOneItemWithFilteredDestination():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(20), new AlienVO(30), new AlienVO(40)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutVerySmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 2000;}
			_subject.filterFunction = filterOutVerySmallEaters;
			_subject.refresh();
			
			//when
			aliens.removeItemAt(0);
			aliens.removeItemAt(2);
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 3000]), _subject);
		}
		
		[Test]
		public function testRemovingFilteredOutItemShouldMeanItsNotThereEvenAfterFilterRemoved():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(20), new AlienVO(30), new AlienVO(40)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutVerySmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 2000;}
			_subject.filterFunction = filterOutVerySmallEaters;
			_subject.refresh();
			
			//when
			aliens.removeItemAt(0);
			_subject.filterFunction = null;
			_subject.refresh();
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 3000, 4000]), _subject);
		}
		
		[Test]
		public function testRemovingFirstItem():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(22), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.removeItemAt(0);
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 4000]), _subject);
		}
		
		
		[Test]
		public function testRemovingAll():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(22), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.removeAll();
			
			//then
			Assert.assertEquals(0, _subject.length);
			caloriesShouldMatch(new ArrayList([]), _subject);
		}
		
		[Test]
		public function testRemovingAllWithFilteredDestination():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutVerySmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 2000;}
			_subject.filterFunction = filterOutVerySmallEaters;
			_subject.refresh();
			
			//when
			aliens.removeAll();
			
			//then
			Assert.assertEquals(0, _subject.length);
			caloriesShouldMatch(new ArrayList([]), _subject);
		}
		
		[Test]
		public function testNothingHappensWhenSourceRecreated():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(22), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens = new ArrayList([new AlienVO(61), new AlienVO(78), new AlienVO(98)]);
			
			//then
			caloriesShouldMatch(new ArrayList([1000, 2000, 4000]), _subject);
		}
		
		[Test]
		public function testMoveRightToLeftOneItem():void
		{
			//given
			const secondAlien:AlienVO = new AlienVO(25);
			var aliens:IList = new ArrayList([new AlienVO(11), secondAlien, new AlienVO(30), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.dispatchEvent(new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.MOVE, 0, 1, [secondAlien]));
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 1000, 3000, 4000]), _subject);
		}
		
		[Test]
		public function testMoveRightToLeftOneItemShouldDoNothingForFilteredDestination():void
		{
			//given
			const firstAlien:AlienVO = new AlienVO(11);
			const secondAlien:AlienVO = new AlienVO(24);
			var alienAgeDecades:IList = new ArrayList([firstAlien, secondAlien, new AlienVO(30), new AlienVO(40)]);
			_subject = new SyncedList(new AlienDietVORobot(alienAgeDecades, new AlienDietVOFactory()));
			
			const filterOutVerySmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 2000;}
			_subject.filterFunction = filterOutVerySmallEaters;
			_subject.refresh();
			
			//when
			alienAgeDecades.dispatchEvent(new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.MOVE, 0, 1, [secondAlien] ));
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 3000, 4000]), _subject);
		}
		
		[Test]
		public function testMoveRightToLeftMoreItems():void
		{
			//given
			const secondAlien:AlienVO = new AlienVO(25);
			const thirdAlien:AlienVO = new AlienVO(30);
			const fourthAlien:AlienVO = new AlienVO(47);
			var aliens:IList = new ArrayList([new AlienVO(11), secondAlien, thirdAlien, fourthAlien]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.dispatchEvent(new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.MOVE, 0, 1, [secondAlien, thirdAlien, fourthAlien] ));
			
			//then
			var alienCalorieIntakesAfterMove:IList = new ArrayList([2000, 3000, 4000, 1000]);
			caloriesShouldMatch(alienCalorieIntakesAfterMove, _subject);
		}
		
		[Test]
		public function testMoveLeftToRightOneItem():void
		{
			//given
			const secondAlien:AlienVO = new AlienVO(25);
			var aliens:IList = new ArrayList([new AlienVO(11), secondAlien, new AlienVO(30), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.dispatchEvent(new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.MOVE, 3, 1, [secondAlien] ));
			
			//then
			caloriesShouldMatch(new ArrayList([1000, 3000, 4000, 2000]), _subject);
		}
		
		[Test]
		public function testMoveLeftToRightMoreItems():void
		{
			//given
			const firstAlien:AlienVO = new AlienVO(15);
			const secondAlien:AlienVO = new AlienVO(25);
			const thirdAlien:AlienVO = new AlienVO(30);
			const fourthAlien:AlienVO = new AlienVO(47);
			var aliens:IList = new ArrayList([firstAlien, secondAlien, thirdAlien, fourthAlien]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.dispatchEvent(new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.MOVE, 1, 0, [firstAlien, secondAlien, thirdAlien] ));
			
			//then
			caloriesShouldMatch(new ArrayList([4000, 1000, 2000, 3000]), _subject);
		}
		
		[Test]
		public function testSetSource():void
		{
			//given
			var aliens:ArrayList = new ArrayList([new AlienVO(12), new AlienVO(29), new AlienVO(32), new AlienVO(44)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.source = [new AlienVO(99), new AlienVO(88), new AlienVO(77), new AlienVO(66)];
			
			//then
			caloriesShouldMatch(new ArrayList([9000, 8000, 7000, 6000]), _subject);
		}
		
		[Test]
		public function testSetItemAt():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.setItemAt(new AlienVO(99), 1);
			
			//then
			caloriesShouldMatch(new ArrayList([1000, 9000, 3000, 4000]), _subject);
		}
		
		[Test]
		public function testSetItemAtWithFilteredDestination():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutVerySmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 2000;}
			_subject.filterFunction = filterOutVerySmallEaters;
			_subject.refresh();
			
			//when
			aliens.setItemAt(new AlienVO(52), 0);
			
			//then
			caloriesShouldMatch(new ArrayList([5000, 2000, 3000, 4000]), _subject);
		}
		
		[Test]
		public function testSetItemAtReplacingNonFilteredItemWithFilteredDestination():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutVerySmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 2000;}
			_subject.filterFunction = filterOutVerySmallEaters;
			_subject.refresh();
			
			//when
			aliens.setItemAt(new AlienVO(50), 2);
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 5000, 4000]), _subject);
		}
		
		[Test]
		public function testFilterSource():void
		{
			//given
			var aliens:ListCollectionView = new ListCollectionView(new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]));
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			aliens.filterFunction = function(item:Object):Boolean {return (item.age >= 20 && item.age <= 30);}
			aliens.refresh();
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 3000]), _subject);
		}
		
		[Test]
		public function testSortSource():void
		{
			//given
			var aliens:ListCollectionView = new ListCollectionView(new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]));
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			//when
			var sortInfo:Sort = new Sort();
			sortInfo.fields = [new SortField("age", true)];
			aliens.sort = sortInfo;
			aliens.refresh();
			
			//then
			caloriesShouldMatch(new ArrayList([4000, 3000, 2000, 1000]), _subject);
		}
		
		[Test]
		public function testUpdate():void
		{
			//given
			var syncFrom:IList = new ArrayList([new AlienVO(11), new AlienVO(20), new AlienVO(39), new AlienVO(44)]);
			_subject = new SyncedList(new AlienDietVORobot(syncFrom, new AlienDietVOFactory()));
			
			//when
			(syncFrom.getItemAt(0) as AlienVO).age = 9;
			(syncFrom.getItemAt(1) as AlienVO).age = 18;
			
			//then
			caloriesShouldMatch(new ArrayList([0, 1000, 3000, 4000]), _subject);
		}
		
		[Test]
		public function testUpdateWithFilteredDestination():void
		{
			//given
			var aliens:IList = new ArrayList([new AlienVO(11), new AlienVO(20), new AlienVO(30), new AlienVO(40)]);
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			const filterOutVerySmallEaters:Function = function(item:Object):Boolean {return AlienDietVO(item).calories >= 2000;}
			_subject.filterFunction = filterOutVerySmallEaters;
			_subject.refresh();
			
			//when
			AlienVO(aliens.getItemAt(0)).age = 22;
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 2000, 3000, 4000]), _subject);
		}
		
		[Test]
		public function testDeleteFromSortedList():void
		{
			//given
			var aliens:ListCollectionView = new ListCollectionView(new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]));
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			var sortInfo:Sort = new Sort();
			sortInfo.fields = [new SortField("age", true)];
			aliens.sort = sortInfo;
			aliens.refresh();
			
			//when
			aliens.removeItemAt(1); //removes AlienVO(30)
			
			//then
			caloriesShouldMatch(new ArrayList([4000, 2000, 1000]), _subject);
		}
		
		[Test]
		public function testDeleteFromFilteredList():void
		{
			//given
			var aliens:ListCollectionView = new ListCollectionView(new ArrayList([new AlienVO(11), new AlienVO(25), new AlienVO(30), new AlienVO(47)]));
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			aliens.filterFunction = function(item:Object):Boolean {return (item.age >= 20 && item.age <= 50);}
			aliens.refresh();
			
			//when
			aliens.removeItemAt(1); //removes AlienVO(30)
			
			//then
			caloriesShouldMatch(new ArrayList([2000, 4000]), _subject);
		}
		
		[Test]
		public function testDeleteFromSortedAndFilteredList():void
		{
			//given
			var aliens:ListCollectionView = new ListCollectionView(new ArrayList([new AlienVO(12), new AlienVO(25), new AlienVO(30), new AlienVO(47), new AlienVO(54), new AlienVO(66), new AlienVO(61)]));
			_subject = new SyncedList(new AlienDietVORobot(aliens, new AlienDietVOFactory()));
			
			var sortInfo:Sort = new Sort();
			sortInfo.fields = [new SortField("age", true)];
			aliens.sort = sortInfo;
			aliens.refresh(); //[AlienVO(66), AlienVO(61), AlienVO(54), AlienVO(47), AlienVO(30), AlienVO(25), AlienVO(12)]
			
			aliens.filterFunction = function(item:Object):Boolean {return item.age % 2 == 0;}
			aliens.refresh(); //makes it [AlienVO(66), AlienVO(54), AlienVO(30), AlienVO(12)]
			
			//when
			aliens.removeItemAt(1); //removes AlienVO(54)
			aliens.removeItemAt(0); //removes AlienVO(66)
			
			//then
			caloriesShouldMatch(new ArrayList([3000, 1000]), _subject);
		}
		
		
		
		
		
		
		
		private function listsShouldMatchExactly(source:IList, destination:IList):void
		{
			for (var i:int = 0; i < source.length; i++)
				Assert.assertEquals(source.getItemAt(i), destination.getItemAt(i));
		}
		
		private function caloriesShouldMatch(calories:IList, dietVOs:IList):void
		{
			Assert.assertEquals(calories.length, dietVOs.length);
			
			for (var i:int = 0; i < calories.length; i++)
				Assert.assertEquals(calories.getItemAt(i), (dietVOs.getItemAt(i) as AlienDietVO).calories);
		}
	}
}
import com.adobe.cairngorm.contract.Contract;
import com.traffic.util.syncedList.AbstractSyncedListItemFactory;
import com.traffic.util.syncedList.IDataToObjectFactory;
import com.traffic.util.syncedList.SyncedListRobot;

import mx.collections.IList;


class AlienVO
{
	[Bindable]
	public var age:Number = NaN;
	
	public function AlienVO(ageInput:Number)
	{
		age = ageInput;
	}
}

class AlienDietVO
{
	[Bindable]
	public var calories:Number = NaN;
	public var alien:AlienVO;
	
	public function AlienDietVO(caloriesInput:Number, alienVO:AlienVO)
	{
		calories = caloriesInput;
		alien = alienVO;
	}
}

class AlienDietVOFactory extends AbstractSyncedListItemFactory
{
	override public function newInstance(alienVO:Object):Object
	{
		Contract.precondition(alienVO is AlienVO);
		
		return new AlienDietVO(Math.floor(AlienVO(alienVO).age / 10) * 1000, AlienVO(alienVO));
	}
}

class AlienDietVORobot extends SyncedListRobot
{
	public function AlienDietVORobot(source:IList, factory:IDataToObjectFactory)
	{
		super(source, factory, true);
	}
	
	override public function locateDestinationBySource(sourceObject:Object, inList:IList):Object
	{
		Contract.precondition(sourceObject is AlienVO);
		var alienVO:AlienVO = sourceObject as AlienVO;
		
		for each(var diet:AlienDietVO in inList)
		{
			if(diet.alien == alienVO)
				return diet;
		}
		
		return null;
	}
}