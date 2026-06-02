package net.play5d.game.bvn.ui.select
{
   import com.greensock.TweenLite;
   import com.greensock.easing.Back;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.SelectCharListItemVO;
   import net.play5d.kyo.display.BitmapText;
   
   public class SelectFighterItem extends EventDispatcher
   {
      
      public var selectData:SelectCharListItemVO;
      
      public var fighterData:FighterVO;
      
      public var ui:MovieClip;
      
      public var position:Point;
      
      public var isMore:Boolean = false;
      
      private var faceSize:Point;
      
      private var _moreText:BitmapText;
      
      private var _alterText:BitmapText;
      
      private var _listeners:Object;
      
      private var _tweenFrom:Point;
      
      private var _tweenTo:Point;
      
      private var _destoryed:Boolean = false;
      
      private var _banPickMc:MovieClip;
      
      public function SelectFighterItem(param1:FighterVO, param2:SelectCharListItemVO, param3:Boolean = false)
      {
         var _loc5_:ColorTransform = null;
         ui = AssetManager.I.createObject("slt_item_mc","subswfs/select.swf") as MovieClip;
         position = new Point();
         faceSize = new Point(50,50);
         _listeners = {};
         super();
         this.isMore = param3;
         this.selectData = param2;
         this.fighterData = param1;
         var _loc4_:DisplayObject = AssetManager.I.getFighterFace(param1);
         if(_loc4_ != null)
         {
            ui.ct.addChild(_loc4_);
         }
         ui.mouseChildren = false;
         ui.buttonMode = true;
         if(param2 != null && param2.moreFighterIDs)
         {
            initMoreUI();
         }
         if(param2 != null && param2.alterFighterIDs)
         {
            initAlterUI();
         }
         if(ui.more_bg)
         {
            ui.more_bg.visible = param3;
            ui.more_bg.mouseChildren = false;
            ui.more_bg.mouseEnabled = false;
            _loc5_ = new ColorTransform();
            _loc5_.redOffset = 255;
            _loc5_.blueOffset = -255;
            ui.more_bg.transform.colorTransform = _loc5_;
         }
      }
      
      public static function getIdByPoint(param1:int, param2:int) : String
      {
         return param1 + "," + param2;
      }
      
      private static function int2Roman(param1:int) : String
      {
         var _loc2_:Array = ["I","II","III","IV","V","VI","VII","VIII","IX"];
         if(param1 >= 0 && param1 <= 8)
         {
            return _loc2_[param1];
         }
         return "Error";
      }
      
      public function get x() : Number
      {
         return _tweenTo ? _tweenTo.x : ui.x;
      }
      
      public function get y() : Number
      {
         return _tweenTo ? _tweenTo.y : ui.y;
      }
      
      public function setBan(param1:Boolean = false, param2:Boolean = false) : void
      {
         if(_banPickMc == null)
         {
            _banPickMc = AssetManager.I.createObject("ban_pick","subswfs/select.swf") as MovieClip;
            ui.addChild(_banPickMc);
         }
         var _loc5_:MovieClip = _banPickMc.getChildByName("p1ban") as MovieClip;
         var _loc4_:MovieClip = _banPickMc.getChildByName("p2ban") as MovieClip;
         var _loc3_:MovieClip = _banPickMc.getChildByName("allban") as MovieClip;
         if(!_loc5_ || !_loc4_ || !_loc3_)
         {
            return;
         }
         _loc3_.visible = param1 && param2;
         _loc5_.visible = param1;
         _loc4_.visible = param2;
         _banPickMc.visible = param1 || param2;
      }
      
      public function get positionId() : String
      {
         return getIdByPoint(position.x,position.y);
      }
      
      private function initMoreUI() : void
      {
         var _loc1_:BitmapText = new BitmapText(false,16776960,[new GlowFilter(0,1,5,5,3)]);
         _loc1_.width = 50;
         _loc1_.defaultTextFormat.bold = true;
         _loc1_.defaultTextFormat.color = 16776960;
         _loc1_.defaultTextFormat.size = 16;
         _loc1_.align = "right";
         _loc1_.y = -3;
         _loc1_.text = selectData.moreFighterIDs.length + "+";
         _loc1_.update();
         ui.addChild(_loc1_);
         _moreText = _loc1_;
      }
      
      private function initAlterUI() : void
      {
         var _loc1_:BitmapText = new BitmapText(false,11393254,[new GlowFilter(0,1,5,5,3)]);
         _loc1_.width = 50;
         _loc1_.defaultTextFormat.bold = true;
         _loc1_.defaultTextFormat.color = 11393254;
         _loc1_.defaultTextFormat.size = 16;
         _loc1_.align = "center";
         _loc1_.x = 15;
         _loc1_.y = 30;
         _loc1_.text = int2Roman(0);
         _loc1_.update();
         ui.addChild(_loc1_);
         _alterText = _loc1_;
      }
      
      public function setMoreNumberVisible(param1:Boolean) : void
      {
         if(_moreText == null)
         {
            return;
         }
         _moreText.visible = param1;
      }
      
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(ui.hasEventListener(param1))
         {
            return;
         }
         ui.addEventListener(param1,selfHandler,param3,param4,param5);
         _listeners[param1] = param2;
      }
      
      public function removeAllEventListener() : void
      {
         for(var _loc1_ in _listeners)
         {
            ui.removeEventListener(_loc1_,_listeners[_loc1_]);
         }
         _listeners = {};
      }
      
      private function selfHandler(param1:Event) : void
      {
         _listeners[param1.type](param1.type,this);
      }
      
      public function initMoreTween(param1:Point, param2:Point) : void
      {
         _tweenFrom = param1;
         _tweenTo = param2;
      }
      
      public function showMore(param1:Number = 0.1) : void
      {
         var delay:Number;
         if(_destoryed)
         {
            return;
         }
         delay = param1;
         ui.x = _tweenFrom.x;
         ui.y = _tweenFrom.y;
         ui.mouseEnabled = false;
         TweenLite.to(ui,0.2,{
            "x":_tweenTo.x,
            "y":_tweenTo.y,
            "ease":Back.easeOut,
            "delay":delay,
            "onComplete":function():void
            {
               ui.mouseEnabled = true;
            }
         });
      }
      
      public function hideMore() : void
      {
         if(_destoryed)
         {
            return;
         }
         TweenLite.to(ui,0.1,{
            "x":_tweenFrom.x,
            "y":_tweenFrom.y,
            "onComplete":function():void
            {
               try
               {
                  ui.parent.removeChild(ui);
               }
               catch(e:Error)
               {
               }
            }
         });
      }
      
      public function updateAlter() : FighterVO
      {
         var _loc3_:String = null;
         if(selectData.alterFighterIDs.indexOf(fighterData.id) == -1)
         {
            selectData.alterFighterIDs.unshift(fighterData.id);
         }
         var _loc4_:int = selectData.alterFighterIDs.indexOf(fighterData.id);
         if(_loc4_ != -1 && _loc4_ < selectData.alterFighterIDs.length - 1)
         {
            _loc3_ = selectData.alterFighterIDs[_loc4_ + 1];
         }
         else
         {
            _loc3_ = selectData.alterFighterIDs[0];
         }
         var _loc1_:FighterVO = FighterModel.I.getFighter(_loc3_);
         fighterData = _loc1_;
         var _loc2_:DisplayObject = AssetManager.I.getFighterFace(fighterData);
         if(_loc2_ != null)
         {
            while(ui.ct.length > 0)
            {
               ui.ct.removeChildAt(0);
            }
            ui.ct.addChild(_loc2_);
         }
         _alterText.text = int2Roman(selectData.alterFighterIDs.indexOf(fighterData.id));
         _alterText.update();
         return _loc1_;
      }
      
      public function destory() : void
      {
         _destoryed = true;
         if(ui)
         {
            removeAllEventListener();
         }
         if(ui && ui.parent)
         {
            try
            {
               ui.parent.removeChild(ui);
            }
            catch(e:Error)
            {
            }
            ui = null;
         }
      }
   }
}

