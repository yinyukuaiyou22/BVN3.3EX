package net.play5d.game.bvn.state
{
   import flash.display.*;
   import flash.events.*;
   import flash.text.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.bitmap.*;
   import net.play5d.kyo.stage.*;
import net.play5d.game.bvn.Debugger;
   
   public class WinnerState implements Istage
   {
      
      private var _ui:MovieClip;
      
      private var _scoreText:BitmapFontText;
      
      private var _winnerFaces:Array;
      
      private var _winSay:String;
      
      private var _bgmDelay:int;
      
      public function WinnerState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      private function buildData() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:FighterVO = FighterModel.I.getFighter(GameData.I.winnerId);
         var _loc5_:Vector.<FighterVO> = new Vector.<FighterVO>();
         var _loc6_:Array = GameData.I.p1Select.getSelectFighters();
         while(_loc1_ < _loc6_.length)
         {
            _loc5_.push(FighterModel.I.getFighter(_loc6_[_loc1_]));
            _loc1_++;
         }
         this._winSay = _loc4_.getRandSay();
         if(_loc5_.length == 1)
         {
            this._winnerFaces = [AssetManager.I.getFighterFaceWin(_loc5_[0])];
         }
         else
         {
            this._winnerFaces = [];
            _loc2_ = int(_loc5_.indexOf(_loc4_));
            this._winnerFaces.push(AssetManager.I.getFighterFaceWin(_loc5_[_loc2_]));
            _loc5_.splice(_loc2_,1);
            while(_loc3_ < _loc5_.length)
            {
               this._winnerFaces.push(AssetManager.I.getFighterFaceWin(_loc5_[_loc3_]));
               _loc3_++;
            }
         }
      }
      
      private function initText() : void
      {
         var txtCompleteHandler:* = undefined;
         var txtmc:MovieClip = null;
         txtCompleteHandler = function(param1:Event):void
         {
            txtmc.removeEventListener("complete",txtCompleteHandler);
            var _loc2_:TextField = new TextField();
            _loc2_.x = 33;
            _loc2_.width = 548;
            _loc2_.height = 66;
            _loc2_.multiline = true;
            _loc2_.wordWrap = true;
            _loc2_.mouseEnabled = false;
            var _loc3_:TextFormat = new TextFormat();
            _loc3_.font = "SimHei";
            _loc3_.color = 0;
            _loc3_.size = 18;
            _loc3_.align = "center";
            _loc3_.leading = 5;
            _loc2_.defaultTextFormat = _loc3_;
            setText(_loc2_,_winSay);
            txtmc.addChild(_loc2_);
         };
         txtmc = this._ui.getChildByName("txtmc") as MovieClip;
         if(Boolean(txtmc))
         {
            txtmc.addEventListener("complete",txtCompleteHandler);
         }
      }
      
      private function testFighterSays(param1:TextField) : void
      {
         var k:String = null;
         var i:FighterVO = null;
         var j:String = null;
         var txt:TextField = null;
         var sayIndex:int = 0;
         var says:Array = null;
         txt = param1;
         var keyHandler:* = function(param1:KeyboardEvent):void
         {
            switch(int(param1.keyCode) - 37)
            {
               case 0:
                  --sayIndex;
                  if(sayIndex < 0)
                  {
                     sayIndex = 0;
                  }
                  break;
               case 2:
                  ++sayIndex;
                  if(sayIndex > says.length - 1)
                  {
                     sayIndex = says.length - 1;
                  }
                  break;
               default:
                  return;
            }
            setText(txt,says[sayIndex].say);
            Debugger.log(says[sayIndex].id);
         };
         var winner:FighterVO = FighterModel.I.getFighter(GameData.I.winnerId);
         sayIndex = 0;
         says = [];
         for each(k in winner.says)
         {
            says.push({
               "id":winner.id,
               "say":k
            });
         }
         for each(i in FighterModel.I.getAllFighters())
         {
            for each(j in i.says)
            {
               says.push({
                  "id":i.id,
                  "say":j
               });
            }
         }
         MainGame.I.stage.addEventListener("keyDown",keyHandler);
      }
      
      private function setText(param1:TextField, param2:String) : void
      {
         param1.text = param2.split("|").join("\n");
         param1.height = param1.textHeight + 5;
         param1.y = 10 + (90 - param1.height) / 2;
      }
      
      public function build() : void
      {
         this.buildData();
         this._scoreText = new BitmapFontText(AssetManager.I.getFont("font1"));
         this._scoreText.text = "SCORE " + GameData.I.score;
         this._scoreText.x = -this._scoreText.width / 2;
         this._scoreText.y = -this._scoreText.height / 2;
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.loading,ResUtils.WINNER);
         this._ui.addEventListener("complete",this.onUIPlayComplete);
         this._ui.scoremc.addChild(this._scoreText);
         if(Boolean(this._winnerFaces[0]))
         {
            this._ui.f0.addChildAt(this._winnerFaces[0],0);
         }
         else
         {
            this._ui.f0.visible = false;
         }
         if(Boolean(this._winnerFaces[1]))
         {
            this._ui.f1.addChildAt(this._winnerFaces[1],0);
         }
         else
         {
            this._ui.f1.visible = false;
         }
         if(Boolean(this._winnerFaces[2]))
         {
            this._ui.f2.addChildAt(this._winnerFaces[2],0);
         }
         else
         {
            this._ui.f2.visible = false;
         }
         SoundCtrl.I.BGM(null);
         SoundCtrl.I.playAssetSound("win");
         GameInputer.enabled = false;
         this.initText();
         this._bgmDelay = setTimeout(function():void
         {
            SoundCtrl.I.BGM(AssetManager.I.getSound("winloop"));
         },6500);
      }
      
      private function onUIPlayComplete(param1:Event) : void
      {
         this._ui.removeEventListener("complete",this.onUIPlayComplete);
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["winner_show"])));
         var _loc2_:MovieClip = this._ui.getChildByName("btns") as MovieClip;
         _loc2_.btn_more.addEventListener("click",this.btnHandler);
         _loc2_.btn_cont.addEventListener("click",this.btnHandler);
         _loc2_.btn_exit.addEventListener("click",this.btnHandler);
         _loc2_.btn_more.addEventListener("mouseOver",this.btnHandler);
         _loc2_.btn_cont.addEventListener("mouseOver",this.btnHandler);
         _loc2_.btn_exit.addEventListener("mouseOver",this.btnHandler);
         GameRender.add(this.render);
         GameInputer.enabled = true;
      }
      
      private function render() : void
      {
         if(GameInputer.select("MENU"))
         {
            this.goNext();
         }
      }
      
      private function btnHandler(param1:MouseEvent) : void
      {
         if(param1.type == "mouseOver")
         {
            SoundCtrl.I.sndSelect();
            return;
         }
         var _loc2_:MovieClip = this._ui.getChildByName("btns") as MovieClip;
         switch(param1.currentTarget)
         {
            case _loc2_.btn_more:
               GameInterface.instance.moreGames();
               break;
            case _loc2_.btn_cont:
               this.goNext();
               break;
            case _loc2_.btn_exit:
               GameUI.confrim("BACK TITLE?","返回到主菜单？",MainGame.I.goMenu);
         }
         SoundCtrl.I.sndConfrim();
      }
      
      private function goNext() : void
      {
         GameInputer.enabled = false;
         StateCtrl.I.transIn(function():void
         {
            MessionModel.I.messionComplete();
            MainGame.I.loadGame();
         });
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         GameRender.remove(this.render);
         GameInputer.enabled = false;
         clearTimeout(this._bgmDelay);
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["winner_end"])));
         if(Boolean(this._ui))
         {
            this._ui.gotoAndStop("destory");
            this._ui = null;
         }
      }
   }
}

