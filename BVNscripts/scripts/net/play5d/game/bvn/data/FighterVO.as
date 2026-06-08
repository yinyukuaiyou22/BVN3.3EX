package net.play5d.game.bvn.data
{
   import net.play5d.kyo.utils.*;
   
   public class FighterVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var comicType:int;
      
      public var fileUrl:String;
      
      public var startFrame:int;
      
      public var faceUrl:String;
      
      public var faceBigUrl:String;
      
      public var faceBarUrl:String;
      
      public var faceWinUrl:String;
      
      public var contactFriends:Array;
      
      public var contactEnemys:Array;
      
      public var says:Array;
      
      public var bgm:String;
      
      public var bgmRate:Number = 1;
      
      private var _cloneKey:Array = ["id","name","comicType","fileUrl","AIUrl","startFrame","faceUrl","contactFriends","contactEnemys","says","faceBigUrl","faceBarUrl","bgm","bgmRate"];
      
      public function FighterVO()
      {
         super();
      }
      
      public function initByXML(param1:XML) : void
      {
         var _loc2_:* = undefined;
         this.id = param1.@id;
         this.name = param1.@name;
         this.comicType = int(param1.@comic_type);
         this.fileUrl = param1.file.@url;
         this.startFrame = int(param1.file.@startFrame);
         this.faceUrl = param1.face.@url;
         this.faceBigUrl = param1.face.@big_url;
         this.faceBarUrl = param1.face.@bar_url;
         this.faceWinUrl = param1.face.@win_url;
         this.contactFriends = param1.contact.friend.toString().split(",");
         this.contactEnemys = param1.contact.enemy.toString().split(",");
         this.bgm = param1.bgm.@url;
         this.bgmRate = param1.bgm.@rate / 100;
         this.says = [];
         for each(_loc2_ in param1.says.say_item)
         {
            this.says.push(_loc2_.children().toString());
         }
         if(this.startFrame != 0 && !this.bgm)
         {
            trace(this.id + "没有定义bgm!");
         }
      }
      
      public function getRandSay() : String
      {
         return KyoRandom.getRandomInArray(this.says);
      }
      
      public function clone() : FighterVO
      {
         var _loc1_:* = undefined;
         var _loc2_:FighterVO = new FighterVO();
         for each(_loc1_ in this._cloneKey)
         {
            _loc2_[_loc1_] = this[_loc1_];
         }
         return _loc2_;
      }
   }
}

