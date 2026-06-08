package net.play5d.game.bvn.mob.views.lan
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.text.*;
   import net.play5d.game.bvn.mob.utils.*;
   
   public class HostDialogItem
   {
      
      public var ui:Sprite;
      
      private var _txt:TextField;
      
      private var _enTxt:TextField;
      
      private var _data:Object;
      
      private var _checkGroup:InsCheckGroup;
      
      public function HostDialogItem(param1:Object)
      {
         super();
         this._data = param1;
         this.ui = UIAssetUtil.I.createDisplayObject("check_line_mc");
         this._txt = this.ui.getChildByName("txt") as TextField;
         this._enTxt = this.ui.getChildByName("txt_en") as TextField;
         this._txt.text = param1.title;
         this._txt.width = this._txt.textWidth + 50;
         this._enTxt.text = param1.en;
         this._enTxt.width = this._enTxt.textWidth + 50;
         this.buildCheckGroup();
         this.updateEnText();
      }
      
      public function getSelectData() : Object
      {
         return {
            "key":this._data.key,
            "value":this._checkGroup.selectData.value
         };
      }
      
      private function buildCheckGroup() : void
      {
         var _loc1_:InsCheckGroup = new InsCheckGroup(this._data.key,this._data.options);
         _loc1_.x = this._txt.width;
         _loc1_.addEventListener("change",this.groupChangeHandler);
         this.ui.addChild(_loc1_);
         this._checkGroup = _loc1_;
      }
      
      private function updateEnText() : void
      {
         this._enTxt.text = this._data.en + " : " + this._checkGroup.selectData.en;
         this._enTxt.width = this._enTxt.textWidth + 50;
      }
      
      private function groupChangeHandler(param1:Event) : void
      {
         this.updateEnText();
      }
   }
}

import flash.display.*;
import flash.events.*;
import net.play5d.game.bvn.ctrl.*;
import net.play5d.game.bvn.mob.screenpad.*;
import net.play5d.game.bvn.mob.utils.*;

class InsCheckGroup extends Sprite
{
   
   private var _checkMcs:Array;
   
   public var key:String;
   
   public var selectData:Object;
   
   public function InsCheckGroup(param1:String, param2:Array)
   {
      var _loc3_:int = 0;
      var _loc4_:InsCheckMc = null;
      super();
      this._checkMcs = [];
      this.mouseEnabled = this.mouseChildren = false;
      this.key = param1;
      while(_loc3_ < param2.length)
      {
         _loc4_ = new InsCheckMc(param2[_loc3_]);
         if(_loc3_ == 0)
         {
            _loc4_.selected(true);
            this.selectData = param2[_loc3_];
         }
         this._checkMcs.push(_loc4_);
         _loc4_.ui.x = _loc3_ * 130;
         addChild(_loc4_.ui);
         ScreenPadManager.addTouchListener(_loc4_.ui,this.touchHandler);
         _loc3_++;
      }
   }
   
   private function touchHandler(param1:DisplayObject) : void
   {
      var _loc3_:* = undefined;
      var _loc2_:Object = null;
      SoundCtrl.I.sndSelect();
      for each(_loc3_ in this._checkMcs)
      {
         if(_loc3_.ui == param1)
         {
            _loc2_ = _loc3_.data;
            _loc3_.selected(true);
         }
         else
         {
            _loc3_.selected(false);
         }
      }
      if(this.selectData != _loc2_)
      {
         this.selectData = _loc2_;
         dispatchEvent(new Event("change"));
      }
   }
}

class InsCheckMc
{
   
   public var ui:MovieClip;
   
   public var data:Object;
   
   public function InsCheckMc(param1:Object)
   {
      super();
      this.data = param1;
      this.ui = UIAssetUtil.I.createDisplayObject("ckmc");
      this.ui.txtmc.txt.text = param1.name;
   }
   
   public function selected(param1:Boolean) : void
   {
      this.ui.gotoAndStop(param1 ? 2 : 1);
   }
}
