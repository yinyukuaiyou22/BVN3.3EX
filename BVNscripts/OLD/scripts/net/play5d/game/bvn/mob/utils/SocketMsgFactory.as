package net.play5d.game.bvn.mob.utils
{
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.mob.ctrls.LANServerCtrl;
   
   public class SocketMsgFactory
   {
      
      public function SocketMsgFactory()
      {
         super();
      }
      
      public static function createFindHostMsg() : ByteArray
      {
         var _loc1_:ByteArray = new ByteArray();
         _loc1_.writeByte(20);
         return _loc1_;
      }
      
      public static function createFindHostBackMsg() : ByteArray
      {
         var _loc1_:ByteArray = new ByteArray();
         _loc1_.writeByte(21);
         _loc1_.writeBytes(LANServerCtrl.I.host.toByteArray());
         return _loc1_;
      }
      
      public static function createJoinMsg() : Object
      {
         var _loc1_:Object = {};
         _loc1_.type = "JOIN";
         _loc1_.name = "mobile_user";
         return _loc1_;
      }
      
      public static function createJoinSuccMsg() : Object
      {
         var _loc1_:Object = {};
         _loc1_.type = "JOIN_BACK";
         _loc1_.success = true;
         return _loc1_;
      }
      
      public static function createJoinInMsg() : Object
      {
         var _loc1_:Object = {};
         _loc1_.type = "JOIN_IN";
         _loc1_.name = "mobile_user";
         return _loc1_;
      }
      
      public static function createJoinFailMsg(param1:String = null) : Object
      {
         var _loc2_:Object = {};
         _loc2_.type = "JOIN_BACK";
         _loc2_.success = false;
         _loc2_.msg = param1;
         return _loc2_;
      }
      
      public static function createKickOutMsg(param1:String = null) : Object
      {
         var _loc2_:Object = {};
         _loc2_.type = "KICK_OUT";
         _loc2_.msg = param1;
         return _loc2_;
      }
      
      public static function createChart(param1:String, param2:String) : Object
      {
         var _loc3_:Object = {};
         _loc3_.type = "CHART";
         _loc3_.msg = param1;
         _loc3_.name = param2;
         return _loc3_;
      }
      
      public static function createStartGame() : Object
      {
         var _loc1_:Object = {};
         _loc1_.type = "START_GAME";
         return _loc1_;
      }
   }
}

