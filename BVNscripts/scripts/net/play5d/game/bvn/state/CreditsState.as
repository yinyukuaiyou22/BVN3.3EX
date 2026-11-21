package net.play5d.game.bvn.state
{
   import flash.display.*;
   import flash.text.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   public class CreditsState implements Istage
   {
      
      private var _ui:Sprite;
      
      private var _btngroup:SetBtnGroup;
      
      private var _createsSp:DisplayObject;
      
      public function CreditsState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
         this._ui = new Sprite();
         var _loc1_:BitmapData = ResUtils.I.createBitmapData(ResUtils.I.common_ui,"cover_bgimg",GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         var _loc2_:Bitmap = new Bitmap(_loc1_);
         this._ui.addChild(_loc2_);
         var _loc3_:String = this.getCreditsText();
         this._createsSp = GameInterface.instance.getCreadits(_loc3_);
         if(!this._createsSp)
         {
            this._createsSp = this.getDefaultCredits(_loc3_);
         }
         this._ui.addChild(this._createsSp);
         this._btngroup = new SetBtnGroup();
         this._btngroup.y = GameConfig.GAME_SIZE.y - 150;
         this._btngroup.setBtnData([{
            "label":"BACK",
            "cn":"返回"
         }]);
         this._btngroup.addEventListener("SELECT",this.selectBtnHandler);
         this._ui.addChild(this._btngroup);
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         if(Boolean(this._btngroup))
         {
            this._btngroup.destory();
            this._btngroup.removeEventListener("SELECT",this.selectBtnHandler);
            this._btngroup = null;
         }
      }
      
      private function selectBtnHandler(param1:SetBtnEvent) : void
      {
         MainGame.I.goMenu();
      }
      
      private function getCreditsText() : String
      {
         // 2026-11-21：人员名单整块删除（用户要求只保留原作者署名）。
         // 官网/反馈/邮箱/仓库/免费声明由 GameInterfaceManager.getCreadits() 追加在本段之后。
         return "原作者：剑jian<br/>";
      }
      
      private function getDefaultCredits(param1:String) : Sprite
      {
         var _loc2_:Sprite = new Sprite();
         var _loc3_:TextField = new TextField();
         var _loc4_:TextFormat = new TextFormat();
         _loc4_.font = "微软雅黑";
         _loc4_.size = 20;
         _loc4_.color = 16776960;
         _loc4_.leading = 15;
         _loc3_.defaultTextFormat = _loc4_;
         _loc3_.multiline = true;
         _loc3_.htmlText = param1;
         _loc3_.autoSize = "left";
         _loc3_.x = 50;
         _loc3_.y = 30;
         _loc2_.addChild(_loc3_);
         return _loc2_;
      }
   }
}

