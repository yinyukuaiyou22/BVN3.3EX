package net.play5d.game.bvn.ui.dialog
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ui.Text;
   import net.play5d.game.bvn.utils.BtnUtils;
   
   public class BranchUI extends BaseDialog
   {
      
      private var _branchNum:int = 0;
      
      private var _branchBtns:Vector.<DisplayObject> = new Vector.<DisplayObject>();
      
      public function BranchUI(param1:Number)
      {
         super();
         _branchNum = param1;
         width = 495;
         height = 240;
         _ui = AssetManager.I.createObject("dialog_branch","subswfs/dialog_ui.swf") as MovieClip;
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
         for each(var _loc1_ in _branchBtns)
         {
            BtnUtils.destoryBtn(_loc1_);
         }
      }
      
      protected function build() : void
      {
         var _loc5_:int = 0;
         var _loc6_:MovieClip = null;
         var _loc1_:TextField = null;
         var _loc2_:DisplayObject = null;
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
         _loc5_ = 1;
         while(_loc5_ <= _branchNum)
         {
            _loc6_ = AssetManager.I.createObject("num_btn","subswfs/dialog_ui.swf") as MovieClip;
            _loc6_.buttonMode = true;
            _loc6_.mouseChildren = false;
            _loc1_ = _loc6_.getChildByName("txt") as TextField;
            if(_loc1_ != null)
            {
               _loc1_.cacheAsBitmap = true;
               _loc1_.text = _loc5_.toString();
            }
            _branchBtns.push(_loc6_);
            BtnUtils.initBtn(_loc6_,clickHandler);
            _loc5_++;
         }
         _noBtn = AssetManager.I.createObject("no_btn","subswfs/dialog_ui.swf") as SimpleButton;
         _branchBtns.push(_noBtn);
         BtnUtils.initBtn(_noBtn,clickHandler);
         var _loc3_:int = int(_branchBtns.length);
         var _loc4_:Number = width / (_loc3_ + 1);
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            _loc2_ = _branchBtns[_loc5_] as DisplayObject;
            if(_loc2_ != null)
            {
               _loc2_.y = 234;
               _loc2_.x = (_loc5_ + 1) * _loc4_;
               _ui.addChild(_loc2_);
            }
            _loc5_++;
         }
      }
      
      private function clickHandler(param1:DisplayObject) : void
      {
         if(param1 == _noBtn)
         {
            if(noBack != null)
            {
               noBack();
               return;
            }
         }
         var _loc2_:TextField = (param1 as MovieClip).getChildByName("txt") as TextField;
         var _loc3_:int = int(_loc2_.text);
         if(yesBack != null)
         {
            yesBack(_loc3_);
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

