package net.play5d.game.bvn.data
{
   public class MapVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var inRandom:String;
      
      public var fileUrl:String;
      
      public var picUrl:String;
      
      public var bgm:String;
      
      public function MapVO()
      {
         super();
      }
      
      public function initByXML(param1:XML) : void
      {
         id = param1.@id;
         name = GetLangText("name.map." + id);
         inRandom = param1.@inRandom;
         fileUrl = param1.file.@url;
         picUrl = param1.img.@url;
         bgm = param1.bgm.@url;
      }
   }
}

