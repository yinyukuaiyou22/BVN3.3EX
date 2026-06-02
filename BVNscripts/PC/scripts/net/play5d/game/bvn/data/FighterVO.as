package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.win.utils.MultiLangUtils;
   import net.play5d.kyo.utils.KyoRandom;
   import net.play5d.patchouli.utils.ClassUtil;
   
   public class FighterVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var nameCn:String;
      
      public var comicType:int;
      
      public var fileUrl:String;
      
      public var startFrame:int;
      
      public var faceUrl:String;
      
      public var faceBigUrl:String;
      
      public var faceBarUrl:String;
      
      public var faceWinUrl:String;
      
      public var says:Array = [];
      
      public var bgm:String;
      
      public var bgmRate:Number = 1;
      
      public var isAlive:Boolean;
      
      public var money:int = 0;
      
      public var level:int = -1;
      
      public var isGodLevel:Boolean = false;
      
      public var isOld:Boolean = false;
      
      public var isZako:Boolean = false;
      
      public var isActivities:Boolean = false;
      
      public var isPlaceholder:Boolean = false;
      
      public var isBan:Boolean = false;
      
      public var hurtless:int;
      
      private var _cloneKey:Array = ["id","name","nameCn","comicType","fileUrl","startFrame","faceUrl","says","faceBigUrl","faceBarUrl","bgm","bgmRate","money","level","isGodLevel","isOld","isZako","isActivities","isPlaceholder","isBan","hurtless"];
      
      public function FighterVO()
      {
         super();
      }
      
      public function initByXML(param1:XML) : void
      {
         var _loc2_:String = null;
         var _loc3_:Object = null;
         id = param1.@id;
         name = "";
         nameCn = "";
         comicType = int(param1.@comic_type);
         fileUrl = param1.file.@url;
         startFrame = int(param1.file.@startFrame);
         faceUrl = param1.face.@url;
         faceBigUrl = param1.face.@big_url;
         faceBarUrl = param1.face.@bar_url;
         faceWinUrl = param1.face.@win_url;
         if(fileUrl.indexOf("fz/") > -1)
         {
            name = GetLangText("name.assist." + id);
            nameCn = MultiLangUtils.I.getCnLangText("name.assist." + id);
         }
         else
         {
            name = GetLangText("name.fighter." + id + ".name");
            nameCn = MultiLangUtils.I.getCnLangText("name.fighter." + id + ".name");
            _loc2_ = "name.fighter." + id + ".says";
            _loc3_ = MultiLangUtils.I.getLangObj();
            says = ClassUtil.continuousAccess(_loc3_,_loc2_.split(".")) as Array;
         }
         money = param1.@money == undefined ? 5000 : int(param1.@money);
         level = param1.@level == undefined ? -1 : int(param1.@level);
         isGodLevel = level == 0;
         bgm = param1.bgm.@url;
         bgmRate = param1.bgm.@rate * 0.01;
         isOld = id.indexOf("_old") != -1;
         isZako = id.indexOf("xb_") != -1;
         isActivities = param1.@is_activities == undefined ? false : int(param1.@is_activities) == 1;
         isPlaceholder = id.indexOf("placeholder") != -1;
         hurtless = int(param1.@hurtless);
      }
      
      public function getRandSay() : String
      {
         return KyoRandom.getRandomInArray(says);
      }
      
      public function clone() : FighterVO
      {
         var _loc1_:FighterVO = new FighterVO();
         for each(var _loc2_ in _cloneKey)
         {
            _loc1_[_loc2_] = this[_loc2_];
         }
         return _loc1_;
      }
   }
}

