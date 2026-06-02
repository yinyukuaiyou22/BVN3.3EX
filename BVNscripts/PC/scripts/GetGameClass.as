package
{
   import flash.utils.getDefinitionByName;
   
   public function GetGameClass(param1:String = "") : Class
   {
      if(param1 == "")
      {
         return null;
      }
      var _loc2_:Class = null;
      try
      {
         _loc2_ = getDefinitionByName(param1) as Class;
      }
      catch(e:Error)
      {
      }
      return _loc2_;
   }
}

