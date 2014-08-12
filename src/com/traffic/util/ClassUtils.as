package com.sohnar.traffic.util
{
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import mx.utils.DescribeTypeCache;
	
	/**
	 * Some handy class utilities
	 */
	public final class ClassUtils
	{
		/* ==================================================== */
		/* = STATIC METHODS		         	                  = */
		/* ==================================================== */
		
		private static var _classReadWriteHash:Dictionary = new Dictionary(true);
		
		/**
		 * Returns all the properties of an object
		 * @return Array
		 */
		public static function getAllPropertiesFrom(object:Object):Array
		{
			var clazzName:String = getQualifiedClassName(object);
			var cachedProperties:Array = _classReadWriteHash[clazzName] as Array;
			
			if (cachedProperties)
			{
				return cachedProperties as Array;
			}
			
			var properties:Array = getWritePropertiesForObject(object);
			_classReadWriteHash[clazzName] = properties;
			
			return properties;
		}
		
		/**
		 * Returns a dynamic object with the public properties of the source object
		 *
		 * @return Object
		 */
		public static function createObjectFrom(object:Object, lowercaseProps:Boolean = false):Object
		{
			var props:Array = getWritePropertiesForObject(object);
			var objOutput:Object = {};
			var propName:String;
			
			for each (var prop:String in props)
			{
				propName = (!lowercaseProps) ? prop : prop.toLowerCase();
				objOutput[propName] = object[propName];
			}
			
			return objOutput;
		}
		
		
		
		public static function getValuesFromObjectPaths(paths:Array, host:Object):Array
		{
			if (!paths)
				return null;
			
			if (!paths.length)
				return null;
			
			if (!host)
				return null;
			
			
			var values:Array = [];
			
			for each (var searchPath:String in paths)
			{
				if (!searchPath)
					continue;
				
				var valueFromPath:Object = getValueFromObjectPath(searchPath, host);
				
				if (valueFromPath)
					values.push(valueFromPath);
				
			}
			
			return values;
		}
		
		
		public static function setObjectProperty(object:Object, propertyPath:String, newValue:*):Boolean {
			var destinationObject:Object = object;
			var explodedPropertyPath:Array = propertyPath.split(".");
			var nextPropertyName:String;
			while (explodedPropertyPath.length > 1) {
				nextPropertyName = explodedPropertyPath.shift() as String;
				if (destinationObject && destinationObject.hasOwnProperty(nextPropertyName)) {
					try {
						destinationObject = destinationObject[nextPropertyName];
					} catch (e:Error) {
						return false;
					}
				} else {
					return false;
				}
			}
			try {
				destinationObject[explodedPropertyPath[0]] = newValue;
			} catch (e:Error) {
				return false;
			}
			return true;
		}

		
		public static function getValueFromObjectPath(path:String, host:Object):Object
		{
			if (!path)
				return host;
			
			if (!host)
				return null;
			
			var explodedSearchPath:Array;
			var currentValue:Object;
			
			explodedSearchPath = path.split(".");
			
			if (explodedSearchPath.length)
			{
				currentValue = host;
				
				while (explodedSearchPath.length && currentValue)
				{
					currentValue = getSinglePropertyValue(explodedSearchPath.shift() as String, currentValue);
				}
			}
			
			
			return currentValue;
		}
		
		
		public static function getSinglePropertyValue(name:String, host:Object):Object
		{
			if (!name)
				return null;
			
			if (!host)
				host = null;
			
			if (!host.hasOwnProperty(name))
				return null;
			
			
			return host[name];
		}
		
		
		public static function getConcatenatedPropertiesString(fromObject:Object, propertyPaths:Array, separator:String = ""):String
		{
			if (!propertyPaths)
				return "";
			
			if(propertyPaths.length == 1) {
				var path:String = propertyPaths[0] as String;
				if(path && (path.indexOf(".") == -1) && 
								(fromObject.hasOwnProperty(path)))
				{
					return fromObject[path];
				}
				return getValueFromObjectPath(propertyPaths[0], fromObject) as String;
			}
			
			var valuesFromPaths:Array = ClassUtils.getValuesFromObjectPaths(propertyPaths, fromObject);
			
			return valuesFromPaths.join(separator);
		}
		
		
		/**
		 * <p>Updates a destination Object from source Object</p>
		 *
		 * <p>Contributed By: Dan Woolloff</p>
		 *
		 * @param destination Object to update the properties of
		 * @param source Object to get properties from
		 */
		public static function updateObjectProperties(destination:*, source:*):void
		{
			if (destination && source)
			{
				var props:Array = getWritePropertiesForObject(destination);
				
				for each (var i:String in props)
				{
					try
					{
						if (source[i] is Object && !(source[i] is Boolean || source[i] is String || source[i] is Number || source[i] is int || source[i] is uint || source[i] is Date))
						{
							//ObjectUtils.updateObjectProperties(destination[i], source[i]);
						}
						else
						{
							destination[i] = source[i];
						}
					}
					catch (e:Error)
					{
					}
				}
			}
		}
		
		private static function getWritePropertiesForObject(object:Object, includeTransients:Boolean = false):Array
		{
			var properties:Array = new Array();
			
			var classAsXML:XML = mx.utils.DescribeTypeCache.describeType(object).typeDescription;
			var list:XMLList = classAsXML.*;
			var item:XML;
			
			for each (item in list)
			{
				var itemName:String = item.name().toString();
				
				switch (itemName)
				{
					case "variable":
						properties.push(item.@name.toString());
						break;
					case "accessor":
						var access:String = item.@access;
						if (access != "readonly" && access != "writeonly")
						{
							//If false transient flag, ignore.
							if (!includeTransients && !hasTransientMetadata(item))
								properties.push(item.@name.toString());
						}
						break;
				}
			}
			
			return properties;
		}
		
		private static function hasTransientMetadata(item:XML):Boolean
		{
			var metaList:XMLList = item.*;
			
			for each (var meta:XML in metaList)
			{
				var metaName:String = meta.@name.toString();
				
				if (metaName == "Transient")
				{
					return true;
				}
				else
				{
					continue;
				}
			}
			
			return false;
		}
	}
}