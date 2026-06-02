package net.play5d.game.bvn.stage
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.ui.SetBtnGroup;
   import net.play5d.kyo.stage.Istage;
   
   public class StaffStage implements Istage
   {
      
      private var _ui:Sprite;
      
      private var _btngroup:SetBtnGroup;
      
      private var _createsSp:DisplayObject;
      
      public function StaffStage()
      {
         super();
      }
      
      private static function selectBtnHandler(param1:SetBtnEvent) : void
      {
         MainGame.I.goMenu();
      }
      
      private static function getCreditsText() : String
      {
         return "游戏原作：<a href=\'event:myEvent\'>剑jian</a><br>综合企划：数字化流天、L、社长、Diazynez<br>程序开发：Nagisa、Diazynez、BearBrine、パチュリー<br>美术绘制：数字化流天、L、酸菜鱼、V.临界幻想、小数、Azreal、影、赤炎、小海、主流、卡布托、<br>                 Future、Nagisa、惊鸿、杯梓、花里、Just、机器唐、铃、腐竹...<br>角色设计：ゞ影孞&僮畵ヾ、cat232181、逝时_流光、黑咲琉璃、哈士奇、星空幻梦、LOTTU...<br>战斗测试：御礼、油条、pH、屑狼、Q、有也与生、无宇逆风、叽咕村夫、默默、小皮、山之叟、<br>                 欲上天、肥宅正品、皮皮虾...<br>特殊贡献：灰原·银<br>版本对接：七米、Lemon_kenbai、黑羽、诺斯给给...<br>社区运营：多情丶回忆、成环、FZCL石头门、纯白暮弦、风之旅人、寒窗听雨、黑猫、老秦、<br>                 凌辰夜风、萌新、某个热爱理科的死宅、天双、一只ZH、乌拉子、小熙、翔龙、帝释梦寐...<br>";
      }
      
      private static function getDefaultCredits(param1:String) : Sprite
      {
         var _loc4_:Sprite = new Sprite();
         var _loc3_:TextFormat = new TextFormat();
         _loc3_.font = "Microsoft YaHei";
         _loc3_.size = 20;
         _loc3_.color = 16776960;
         _loc3_.leading = 15;
         var _loc2_:TextField = new TextField();
         _loc2_.defaultTextFormat = _loc3_;
         _loc2_.multiline = true;
         _loc2_.htmlText = param1;
         _loc2_.autoSize = "left";
         _loc2_.x = 50;
         _loc2_.y = 30;
         _loc4_.addChild(_loc2_);
         return _loc4_;
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
         _ui = new Sprite();
         var _loc2_:Bitmap = new Bitmap(AssetManager.I.createObject("cover_staff_bg","subswfs/common_ui.swf") as BitmapData);
         _ui.addChild(_loc2_);
         var _loc1_:String = getCreditsText();
         _createsSp = GameInterface.instance.getCreadits(_loc1_);
         if(!_createsSp)
         {
            _createsSp = getDefaultCredits(_loc1_);
         }
         _ui.addChild(_createsSp);
         _btngroup = new SetBtnGroup();
         _btngroup.y = GameConfig.GAME_SIZE.y - 150;
         _btngroup.setBtnData([{
            "label":GetLangText("game_ui.btn_data.general.back.label"),
            "cn":GetLangText("game_ui.btn_data.general.back.txt")
         }]);
         _btngroup.addEventListener("SELECT",selectBtnHandler);
         _ui.addChild(_btngroup);
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         if(_btngroup)
         {
            _btngroup.destory();
            _btngroup.removeEventListener("SELECT",selectBtnHandler);
            _btngroup = null;
         }
      }
   }
}

