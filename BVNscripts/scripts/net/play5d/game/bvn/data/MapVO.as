package net.play5d.game.bvn.data
{
   public class MapVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var fileUrl:String;
      
      public var picUrl:String;
      
      public var bgm:String;
      
      public function MapVO()
      {
         super();
      }
      
      public function initByXML(param1:XML) : void
      {
         this.id = param1.@id;
         this.name = param1.@name;
         this.fileUrl = param1.file.@url;
         this.picUrl = param1.img.@url;
         this.bgm = param1.bgm.@url;
      }
   }
}

