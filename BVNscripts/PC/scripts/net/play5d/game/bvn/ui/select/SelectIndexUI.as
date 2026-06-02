package net.play5d.game.bvn.ui.select
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.utils.setTimeout;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   
   public class SelectIndexUI extends Sprite
   {
      
      public static var SHOW_MODE:int = 0;
      
      public var onFinish:Function;
      
      private var _p1Group:SelectIndexUIGroup;
      
      private var _p2Group:SelectIndexUIGroup;
      
      public function SelectIndexUI()
      {
         super();
         buildItems();
         initSelect();
      }
      
      public function getP1Order() : Array
      {
         return _p1Group.getOrder();
      }
      
      public function getP2Order() : Array
      {
         return _p2Group.getOrder();
      }
      
      public function setP1Order(param1:Array) : void
      {
         _p1Group.setOrder(param1);
      }
      
      public function setP2Order(param1:Array) : void
      {
         _p2Group.setOrder(param1);
      }
      
      public function p1Finish() : Boolean
      {
         return _p1Group.isFinish;
      }
      
      public function p2Finish() : Boolean
      {
         return _p2Group.isFinish;
      }
      
      public function isFinish() : Boolean
      {
         return _p1Group.isFinish && _p2Group.isFinish;
      }
      
      public function destory() : void
      {
         if(_p1Group)
         {
            _p1Group.destory();
            _p1Group = null;
         }
         if(_p2Group)
         {
            _p2Group.destory();
            _p2Group = null;
         }
         onFinish = null;
      }
      
      private function buildItems() : void
      {
         _p1Group = new SelectIndexUIGroup();
         _p2Group = new SelectIndexUIGroup();
         if(SHOW_MODE == 1)
         {
            _p1Group.x = 35;
            _p2Group.x = 535;
            _p1Group.setFighterScale(0.75);
            _p2Group.setFighterScale(0.75);
            _p1Group.fighterOffset.x = -5;
            _p2Group.fighterOffset.x = 40;
            _p1Group.setFZScale(0.8);
            _p2Group.setFZScale(0.8);
            _p1Group.fzx = -5;
            _p2Group.fzx = 34;
         }
         else
         {
            _p1Group.x = 70;
            _p2Group.x = 480;
            _p1Group.fzx = -30;
            _p2Group.fzx = 25;
         }
         _p1Group.y = 85;
         _p2Group.y = 85;
         var _loc1_:Class = AssetManager.I.getSWFEffectClass("selected_item_p1_mc","subswfs/select.swf");
         var _loc2_:Class = AssetManager.I.getSWFEffectClass("selected_item_p2_mc","subswfs/select.swf");
         _p1Group.build(_loc1_,GameData.I.p1Select);
         _p2Group.build(_loc2_,GameData.I.p2Select);
         addChild(_p1Group);
         addChild(_p2Group);
      }
      
      private function initSelect() : void
      {
         switch(GameMode.currentMode)
         {
            case 10:
               initP1Group();
               initP2Group(null,true);
               break;
            case 11:
            case 101:
               initP1Group();
               initP2Group("P2",false);
               break;
            case 12:
            case 13:
            case 102:
            case 103:
            case 104:
               initP1Group(function():void
               {
                  initP2Group("P1",false);
               });
               break;
            default:
               _p1Group.isFinish = true;
               _p2Group.isFinish = true;
         }
      }
      
      private function initP1Group(param1:Function = null) : void
      {
         var finishBack:Function = param1;
         var arrow:MovieClip = AssetManager.I.createObject("select_arrow_mc_1","assets/subswfs/loading.swf") as MovieClip;
         _p1Group.initArrow(arrow,new Point(-10,30));
         _p1Group.setKey("P1");
         if(finishBack != null)
         {
            _p1Group.onFinish = function():void
            {
               finishBack();
               finishBack = null;
               onSelectFinish();
            };
         }
         else
         {
            _p1Group.onFinish = onSelectFinish;
         }
      }
      
      private function initP2Group(param1:String, param2:Boolean) : void
      {
         var _loc3_:MovieClip = AssetManager.I.createObject("select_arrow_mc_2","assets/subswfs/loading.swf") as MovieClip;
         if(SHOW_MODE == 1)
         {
            _p2Group.initArrow(_loc3_,new Point(230,30));
         }
         else
         {
            _p2Group.initArrow(_loc3_,new Point(260,30));
         }
         if(param2)
         {
            _p2Group.autoSelect();
         }
         else
         {
            _p2Group.setKey(param1);
         }
         _p2Group.onFinish = onSelectFinish;
      }
      
      private function onSelectFinish() : void
      {
         var delayCall:* = function():void
         {
            if(onFinish == null)
            {
               return;
            }
            onFinish();
            onFinish = null;
         };
         if(_p1Group.isFinish && _p2Group.isFinish)
         {
            if(onFinish != null)
            {
               setTimeout(delayCall,1000);
            }
            return;
         }
      }
   }
}

