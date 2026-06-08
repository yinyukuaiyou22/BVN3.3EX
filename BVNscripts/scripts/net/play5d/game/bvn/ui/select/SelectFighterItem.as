package net.play5d.game.bvn.ui.select
{
   import flash.display.DisplayObject;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.SelectCharListItemVO;
   import net.play5d.game.bvn.utils.*;
   
   public class SelectFighterItem extends EventDispatcher
   {
      
      public var selectData:SelectCharListItemVO;
      
      public var fighterData:FighterVO;
      
      public var ui:* = ResUtils.I.createDisplayObject(ResUtils.I.select,"slt_item_mc");
      
      public var position:Point = new Point();
      
      private var faceSize:Point = new Point(50,50);
      
      private var _listeners:Object = {};
      
      public function SelectFighterItem(param1:FighterVO, param2:SelectCharListItemVO)
      {
         super();
         this.selectData = param2;
         this.fighterData = param1;
         var _loc3_:DisplayObject = AssetManager.I.getFighterFace(param1);
         if(Boolean(_loc3_))
         {
            this.ui.ct.addChild(_loc3_);
         }
         this.ui.mouseChildren = false;
         this.ui.buttonMode = true;
      }
      
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(Boolean(this.ui.hasEventListener(param1)))
         {
            return;
         }
         this.ui.addEventListener(param1,this.selfHandler,param3,param4,param5);
         this._listeners[param1] = param2;
      }
      
      public function removeAllEventListener() : void
      {
         var _loc1_:* = undefined;
         for(_loc1_ in this._listeners)
         {
            this.ui.removeEventListener(_loc1_,this._listeners[_loc1_]);
         }
         this._listeners = {};
      }
      
      private function selfHandler(param1:Event) : void
      {
         this._listeners[param1.type](param1.type,this);
      }
      
      public function destory() : void
      {
         if(Boolean(this.ui))
         {
            this.removeAllEventListener();
         }
         if(Boolean(this.ui) && Boolean(this.ui.parent))
         {
            try
            {
               this.ui.parent.removeChild(this.ui);
            }
            catch(e:Error)
            {
            }
            this.ui = null;
         }
      }
   }
}

