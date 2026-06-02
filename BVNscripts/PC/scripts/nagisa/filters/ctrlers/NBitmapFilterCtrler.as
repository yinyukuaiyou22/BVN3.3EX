package nagisa.filters.ctrlers
{
   import flash.filters.BitmapFilter;
   import nagisa.interfaces.Instance;
   
   public class NBitmapFilterCtrler extends Instance
   {
      
      public var name:String;
      
      public var isAdapt:Boolean = true;
      
      public function NBitmapFilterCtrler()
      {
         super();
      }
      
      public function get filter() : BitmapFilter
      {
         return null;
      }
      
      public function adapt(param1:Number, param2:Number) : void
      {
      }
   }
}

