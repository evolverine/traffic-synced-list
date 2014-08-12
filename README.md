traffic-synced-list
===================

traffic-synced-list is a utility for Flex applications which maps an existing list to an ArrayCollection with items which are created by a factory based on the original items. When the source list changes, so does the SyncedList.

# Usage situations
SyncedList is useful whenever you have a list of, say TOs, and your view / model / controller requires VOs which wrap those TOs. It's also useful when you need a list which is the result of any computation on the items of an existing list (say, generating the tax information for each employee from a list of EmployeeTOs).
SyncedList is *not* useful in situations where your list needs to be mapped to a list of different length, or whose items do not map one-to-one to a single item in the SyncedList.

# Usage example
```
view.employeeAvailabilities = new SyncedList(new EmployeeAvailabilitySyncRobot(model.employees, new EmployeeAvailabilityWrapperFactory()));
```

```
public class EmployeeAvailabilitySyncRobot extends SyncedListRobot
{
	public function EmployeeAvailabilitySyncRobot(source:IList, factory:IDataToObjectFactory)
	{
		super(source, factory, true);
	}
	
	override public function locateDestinationBySource(sourceObject:Object, inList:IList):Object
	{
		Contract.precondition(sourceObject == null || sourceObject is TrafficEmployeeTO);
		
		if(!sourceObject)
			return null;
		
		for each(var employeeWrapper:EmployeeAvailabilityWrapper in inList)
		{
			if(employeeWrapper.employee == sourceObject)
				return employeeWrapper;
		}
		
		return null;
	}
}
```

```
public class EmployeeAvailabilityWrapperFactory implements IDataToObjectFactory
{
	public function newInstance(input:Object):Object
	{
		Contract.precondition(input is TrafficEmployeeTO);
		
		return new EmployeeAvailabilityWrapper(TrafficEmployeeTO(input));
	}
}
```