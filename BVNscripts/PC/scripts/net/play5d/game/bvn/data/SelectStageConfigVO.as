package net.play5d.game.bvn.data
{
   import flash.geom.Point;
   
   public class SelectStageConfigVO
   {
      
      public var x:Number = 0;
      
      public var y:Number = 0;
      
      public var width:Number = 800;
      
      public var height:Number = 600;
      
      public var top:Number = 0;
      
      public var bottom:Number = 0;
      
      public var left:Number = 0;
      
      public var right:Number = 0;
      
      public var charList:SelectCharListConfigVO;
      
      public var assistList:SelectCharListConfigVO;
      
      public var unitSize:Point = new Point(50,50);
      
      public function SelectStageConfigVO()
      {
         super();
      }
      
      private static function newListByXML(param1:XMLList) : SelectCharListConfigVO
      {
         var _loc9_:int = 0;
         var _loc12_:XML = null;
         var _loc16_:Point = null;
         var _loc11_:String = null;
         var _loc18_:Array = null;
         var _loc10_:int = 0;
         var _loc3_:XML = null;
         var _loc13_:Array = null;
         var _loc5_:Array = null;
         var _loc14_:String = null;
         var _loc15_:String = null;
         var _loc17_:String = null;
         var _loc2_:Point = null;
         var _loc6_:String = null;
         var _loc7_:Array = null;
         var _loc8_:SelectCharListItemVO = null;
         var _loc4_:SelectCharListConfigVO = new SelectCharListConfigVO();
         _loc4_.VCount = param1.children().length();
         _loc9_ = 0;
         while(_loc9_ < param1.children().length())
         {
            _loc12_ = param1.children()[_loc9_];
            _loc16_ = null;
            _loc11_ = _loc12_.@offset;
            if(_loc11_ && _loc11_.length > 0)
            {
               _loc18_ = _loc11_.split(",");
               _loc16_ = new Point(_loc18_[0],_loc18_[1]);
            }
            if(_loc4_.HCount < _loc12_.children().length())
            {
               _loc4_.HCount = _loc12_.children().length();
            }
            _loc10_ = 0;
            while(_loc10_ < _loc12_.children().length())
            {
               _loc3_ = _loc12_.children()[_loc10_];
               _loc13_ = null;
               _loc5_ = null;
               _loc14_ = _loc3_.@moreFighter;
               if(_loc14_ && _loc14_.length > 0)
               {
                  _loc13_ = _loc14_.split(",");
               }
               _loc15_ = _loc3_.@alterFighter;
               if(_loc15_ && _loc15_.length > 0)
               {
                  _loc5_ = _loc15_.split(",");
               }
               _loc17_ = _loc3_.toString();
               if(_loc17_ && _loc17_.length < 1)
               {
                  _loc17_ = null;
               }
               _loc2_ = _loc16_ != null ? _loc16_.clone() : null;
               _loc6_ = _loc3_.@offset;
               if(_loc6_ && _loc6_.length > 0)
               {
                  _loc7_ = _loc6_.split(",");
                  if(_loc2_ != null)
                  {
                     _loc2_.x += Number(_loc7_[0]);
                     _loc2_.y += Number(_loc7_[1]);
                  }
                  else
                  {
                     _loc2_ = new Point(_loc7_[0],_loc7_[1]);
                  }
               }
               _loc8_ = new SelectCharListItemVO(_loc10_,_loc9_,_loc17_,_loc2_);
               _loc8_.moreFighterIDs = _loc13_;
               _loc8_.alterFighterIDs = _loc5_;
               _loc4_.list.push(_loc8_);
               _loc10_++;
            }
            _loc9_++;
         }
         return _loc4_;
      }
      
      public function setByXML(param1:XML) : void
      {
         var _loc2_:Object = param1.stage_setting.layout;
         x = Number(_loc2_.@x);
         y = Number(_loc2_.@y);
         width = Number(_loc2_.@width);
         height = Number(_loc2_.@height);
         top = Number(_loc2_.@top);
         bottom = Number(_loc2_.@bottom);
         left = Number(_loc2_.@left);
         right = Number(_loc2_.@right);
         charList = newListByXML(param1.char_list);
         assistList = newListByXML(param1.assist_list);
      }
   }
}

