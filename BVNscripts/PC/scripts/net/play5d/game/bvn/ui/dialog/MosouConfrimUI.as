package net.play5d.game.bvn.ui.dialog
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ui.Text;
   import net.play5d.game.bvn.utils.BtnUtils;
   
   public class MosouConfrimUI extends BaseDialog
   {
      
      public function MosouConfrimUI()
      {
         super();
         width = 495;
         height = 240;
         _ui = AssetManager.I.createObject("dialog_confrim","subswfs/dialog_ui.swf") as MovieClip;
         _dialogUI = _ui;
         build();
      }
      
      override protected function onDestory() : void
      {
         super.onDestory();
         if(_cnTxt)
         {
            _cnTxt.destory();
            _cnTxt = null;
         }
         BtnUtils.destoryBtn(_noBtn);
         BtnUtils.destoryBtn(_yesBtn);
      }
      
      protected function build() : void
      {
         _cnTxt = new Text();
         _cnTxt.font = "Microsoft YaHei";
         _cnTxt.leading = 12;
         _cnTxt.x = 15;
         _cnTxt.y = 35;
         _cnTxt.width = 460;
         _cnTxt.height = 140;
         _cnTxt.multiLine(true);
         _cnTxt.align = "center";
         _ui.addChild(_cnTxt);
         _noBtn = _ui.getChildByName("no") as SimpleButton;
         _yesBtn = _ui.getChildByName("yes") as SimpleButton;
         BtnUtils.initBtn(_noBtn,okHandler);
         BtnUtils.initBtn(_yesBtn,okHandler);
      }
      
      private function okHandler(param1:SimpleButton) : void
      {
         switch(param1)
         {
            case _yesBtn:
               if(yesBack != null)
               {
                  yesBack();
               }
               break;
            case _noBtn:
               if(noBack != null)
               {
                  noBack();
               }
         }
      }
      
      override public function setMsg(param1:String = null, param2:String = null) : void
      {
         setTitle(param1);
         if(!param2)
         {
            return;
         }
         _cnTxt.text = param2;
         _cnTxt.visible = true;
      }
   }
}

