package net.play5d.game.bvn.data
{
   import flash.geom.*;
   
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
      
      public function setByXML(param1:XML) : void
      {
         var _loc2_:Object = param1.stage_setting.layout;
         this.x = Number(_loc2_.@x);
         this.y = Number(_loc2_.@y);
         this.width = Number(_loc2_.@width);
         this.height = Number(_loc2_.@height);
         this.top = Number(_loc2_.@top);
         this.bottom = Number(_loc2_.@bottom);
         this.left = Number(_loc2_.@left);
         this.right = Number(_loc2_.@right);
         this.charList = this.newListByXML(param1.char_list);
         this.assistList = this.newListByXML(param1.assist_list);
      }
      
      private function newListByXML(param1:XMLList) : SelectCharListConfigVO
      {
         var _loc2_:int = 0;
         var _loc3_:XML = null;
         var _loc4_:Point = null;
         var _loc5_:String = null;
         var _loc6_:Array = null;
         var _loc7_:int = 0;
         var _loc8_:XML = null;
         var _loc9_:String = null;
         var _loc10_:Point = null;
         var _loc11_:String = null;
         var _loc12_:Array = null;
         var _loc13_:SelectCharListItemVO = null;
         var _loc14_:SelectCharListConfigVO = new SelectCharListConfigVO();
         _loc14_.VCount = param1.children().length();
         while(_loc2_ < param1.children().length())
         {
            _loc3_ = param1.children()[_loc2_];
            _loc4_ = null;
            _loc5_ = _loc3_.@offset;
            if(Boolean(_loc5_) && _loc5_.length > 0)
            {
               _loc6_ = _loc5_.split(",");
               _loc4_ = new Point(_loc6_[0],_loc6_[1]);
            }
            if(_loc14_.HCount < _loc3_.children().length())
            {
               _loc14_.HCount = _loc3_.children().length();
            }
            _loc7_ = 0;
            while(_loc7_ < _loc3_.children().length())
            {
               _loc8_ = _loc3_.children()[_loc7_];
               _loc9_ = _loc8_.toString();
               if(Boolean(_loc9_) && _loc9_.length < 1)
               {
                  _loc9_ = null;
               }
               _loc10_ = _loc4_ ? _loc4_.clone() : null;
               _loc11_ = _loc8_.@offset;
               if(Boolean(_loc11_) && _loc11_.length > 0)
               {
                  _loc12_ = _loc11_.split(",");
                  if(Boolean(_loc10_))
                  {
                     _loc10_.x += Number(_loc12_[0]);
                     _loc10_.y += Number(_loc12_[1]);
                  }
                  else
                  {
                     _loc10_ = new Point(_loc12_[0],_loc12_[1]);
                  }
               }
               _loc13_ = new SelectCharListItemVO(_loc7_,_loc2_,_loc9_,_loc10_);
               _loc14_.list.push(_loc13_);
               _loc7_++;
            }
            _loc2_++;
         }
         return _loc14_;
      }
   }
}

