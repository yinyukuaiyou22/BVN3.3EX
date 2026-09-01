package net.play5d.game.bvn.data
{
   import flash.geom.Point;
   
   public class SelectCharListItemVO
   {
      
      public var x:int;
      
      public var y:int;
      
      public var fighterID:String;
      
      public var offset:Point;

      // 批次6：人物子框 plugin ID 列表（默认 null，由 select.xml 解析时填充；null 表示未配置子框）
      public var pluginIDs:Array;

      public function SelectCharListItemVO(param1:int, param2:int, param3:String, param4:Point = null)
      {
         super();
         this.x = param1;
         this.y = param2;
         this.fighterID = param3;
         this.offset = param4;
         this.pluginIDs = null;
      }
   }
}

