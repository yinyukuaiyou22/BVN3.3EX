package net.play5d.game.bvn.stage
{
   import flash.display.MovieClip;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.stage.base.SettingStageBase;
   import net.play5d.game.bvn.ui.SetBtnGroup;
   import net.play5d.game.bvn.utils.ResUtils;
   
   public class SettingStage extends SettingStageBase
   {
      
      public function SettingStage()
      {
         super();
      }
      
      override public function build() : void
      {
         super.build();
         _ui = AssetManager.I.createObject(ResUtils.SETTING,"subswfs/setting.swf") as MovieClip;
         _btnGroup = new SetBtnGroup();
         _btnGroup.startX = 50;
         _btnGroup.startY = 30;
         _btnGroup.endY = 550;
         _btnGroup.gap = 70;
         _btnGroup.initMainSet();
         _btnGroup.initScroll(GameConfig.GAME_SIZE.x,600);
         _btnGroup.addEventListener("SELECT",onBtnSelect);
         _btnGroup.addEventListener("OPTION_CHANGE",onOptionChange);
         _ui.addChild(_btnGroup);
         _man = _ui.ichigo as MovieClip;
         SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
      }
   }
}

