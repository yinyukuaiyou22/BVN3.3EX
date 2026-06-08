package net.play5d.game.bvn.ui.select
{
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.utils.*;
   
   public class SelecterItemUI
   {
      
      public var ui:*;
      
      public var currentFighter:FighterVO;
      
      public var selectTimes:int;
      
      public var selectTimesCount:int = 1;
      
      public var inputType:String;
      
      public var group:SelectedFighterGroup;
      
      public var selectVO:SelectVO;
      
      public var isSelectAssist:Boolean;
      
      public var x:int;
      
      public var y:int;
      
      public var enabled:Boolean = true;
      
      public var randoms:Vector.<FighterVO> = null;
      
      public var randFrame:int;
      
      private var _playerType:int;
      
      public function SelecterItemUI(param1:int = 1)
      {
         super();
         this._playerType = param1;
         this.ui = ResUtils.I.createDisplayObject(ResUtils.I.select,"select_item_mc");
         this.ui.mouseEnabled = this.ui.mouseChildren = false;
         this.ui.mc.gotoAndStop(param1 == 1 ? 1 : 2);
      }
      
      public function selectFinish() : Boolean
      {
         return this.selectTimes >= this.selectTimesCount;
      }
      
      public function getCurrentSelectes() : Array
      {
         if(this.isSelectAssist)
         {
            return [this.selectVO.fuzhu];
         }
         return [this.selectVO.fighter1,this.selectVO.fighter2,this.selectVO.fighter3];
      }
      
      public function setCurrentSelect(param1:Array) : void
      {
         if(this.isSelectAssist)
         {
            this.selectVO.fuzhu = param1[0];
            this.group.updateFighter(AssisterModel.I.getAssister(this.selectVO.fuzhu));
         }
         else
         {
            this.selectVO.fighter1 = param1[0];
            this.selectVO.fighter2 = param1[1];
            this.selectVO.fighter3 = param1[2];
            this.group.updateFighter(FighterModel.I.getFighter(this.selectVO.fighter1));
            this.group.addFighter(FighterModel.I.getFighter(this.selectVO.fighter2));
            this.group.addFighter(FighterModel.I.getFighter(this.selectVO.fighter3));
         }
         this.selectTimes = this.selectTimesCount;
         this.enabled = false;
      }
      
      public function isSelected(param1:String) : Boolean
      {
         if(!this.selectVO)
         {
            return false;
         }
         if(this.isSelectAssist)
         {
            return this.selectVO.fuzhu == param1;
         }
         return this.selectVO.fighter1 == param1 || this.selectVO.fighter2 == param1 || this.selectVO.fighter3 == param1;
      }
      
      public function select(param1:Function = null) : void
      {
         var _this:* = undefined;
         var back:Function = null;
         back = param1;
         if(!this.selectVO)
         {
            throw new Error("未设置selectVO!");
         }
         if(this.isSelectAssist)
         {
            this.selectVO.fuzhu = this.currentFighter.id;
         }
         else
         {
            switch(this.selectTimes)
            {
               case 0:
                  this.selectVO.fighter1 = this.currentFighter.id;
                  break;
               case 1:
                  this.selectVO.fighter2 = this.currentFighter.id;
                  break;
               case 2:
                  this.selectVO.fighter3 = this.currentFighter.id;
            }
         }
         ++this.selectTimes;
         if(!this.selectFinish())
         {
            this.group.addFighter(this.currentFighter);
         }
         this.enabled = false;
         _this = this;
         this.ui.gotoAndPlay("select");
         this.updateRandom();
         KyoUtils.addFrameScript(this.ui,function():void
         {
            if(!selectFinish())
            {
               enabled = true;
            }
            if(back != null)
            {
               back(_this);
            }
         });
      }
      
      public function moveTo(param1:Number, param2:Number) : void
      {
         this.ui.x = param1;
         this.ui.y = param2;
      }
      
      public function destory() : void
      {
         this.enabled = false;
         this.removeSelecter();
         this.removeGroup();
      }
      
      public function removeSelecter() : void
      {
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
      
      public function removeGroup() : void
      {
         if(Boolean(this.group) && Boolean(this.group.parent))
         {
            try
            {
               this.group.parent.removeChild(this.group);
            }
            catch(e:Error)
            {
            }
            this.group = null;
         }
      }
      
      private function updateRandom() : void
      {
         if(!this.randoms)
         {
            return;
         }
         if(!this.selectVO)
         {
            return;
         }
         this.selectVO.fighter1 && this.removeRand(this.selectVO.fighter1);
         this.selectVO.fighter2 && this.removeRand(this.selectVO.fighter2);
         this.selectVO.fighter3 && this.removeRand(this.selectVO.fighter3);
      }
      
      private function removeRand(param1:String) : void
      {
         var _loc2_:int = 0;
         var _loc3_:* = -1;
         while(_loc2_ < this.randoms.length)
         {
            if(this.randoms[_loc2_].id == param1)
            {
               _loc3_ = _loc2_;
               break;
            }
            _loc2_++;
         }
         if(_loc3_ != -1)
         {
            this.randoms.splice(_loc3_,1);
         }
      }
   }
}

