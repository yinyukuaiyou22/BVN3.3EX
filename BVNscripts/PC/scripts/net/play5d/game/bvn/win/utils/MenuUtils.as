package net.play5d.game.bvn.win.utils
{
   import flash.display.MovieClip;
   import flash.display.NativeMenu;
   import flash.display.NativeMenuItem;
   import flash.display.NativeWindow;
   import flash.display.NativeWindowInitOptions;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.filesystem.File;
   import flash.geom.Rectangle;
   import flash.system.Capabilities;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.AIModel;
   import net.play5d.game.bvn.data.AIVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.PluginModel;
   import net.play5d.game.bvn.data.PluginVO;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.utils.URL;
   
   public class MenuUtils
   {
      
      private static var _instance:MenuUtils;
      
      public const OFFSET_Y:Number = 20;
      
      private var _stage:Stage;
      
      private var _window:NativeWindow;
      
      private var _menu:NativeMenu = null;
      
      private var _isHidden:Boolean = true;
      
      private var _pluginActive:Array = [];
      
      private var _noPlugItem:NativeMenuItem = createMenuItem({
         "label":GetLangText("system.menu.plugin.child.no_plugin.label"),
         "enabled":false
      });
      
      public function MenuUtils()
      {
         super();
      }
      
      public static function get I() : MenuUtils
      {
         if(_instance == null)
         {
            _instance = new MenuUtils();
         }
         return _instance;
      }
      
      private static function getLinkArray() : Array
      {
         return [{
            "label":GetLangText("system.menu.help.child.website_items.game"),
            "select":URL.website
         },{
            "label":GetLangText("system.menu.help.child.website_items.bbs"),
            "select":URL.bbs
         },{
            "label":GetLangText("system.menu.help.child.website_items.bili"),
            "select":URL.bilibili
         },{
            "label":GetLangText("system.menu.help.child.website_items.qq_channel"),
            "select":URL.qqChannel
         }];
      }
      
      private static function unCheckedOtherItem(param1:NativeMenuItem, param2:NativeMenuItem) : void
      {
         if(param1 == null || param2 == null)
         {
            return;
         }
         var _loc4_:NativeMenu = param2.submenu;
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:Array = _loc4_.items;
         for each(var _loc3_ in _loc5_)
         {
            if(_loc3_.label != "-")
            {
               _loc3_.checked = _loc3_ == param1;
            }
         }
      }
      
      public static function findMenuItemByLabel(param1:String, param2:NativeMenu) : NativeMenuItem
      {
         var _loc4_:NativeMenu = null;
         var _loc6_:NativeMenuItem = null;
         var _loc5_:NativeMenuItem = null;
         if(param2 == null)
         {
            return null;
         }
         var _loc7_:Array = param2.items;
         for each(var _loc3_ in _loc7_)
         {
            if(_loc3_.label == param1)
            {
               _loc5_ = _loc3_;
               break;
            }
            _loc4_ = _loc3_.submenu;
            if(_loc4_ != null)
            {
               _loc6_ = findMenuItemByLabel(param1,_loc4_);
               if(_loc6_ != null)
               {
                  _loc5_ = _loc6_;
               }
            }
         }
         return _loc5_;
      }
      
      public function getMenu() : NativeMenu
      {
         return _menu;
      }
      
      public function getWindow() : NativeWindow
      {
         return _window;
      }
      
      public function getMenuArray() : Array
      {
         var array:Array = [{
            "label":GetLangText("system.menu.tool.label"),
            "submenu":createMenu([{
               "label":GetLangText("system.menu.tool.child.unstuck.label"),
               "select":function(param1:Event):void
               {
                  var _loc3_:FighterMain = null;
                  var _loc2_:FighterMain = null;
                  if(GameCtrl.I.gameState != null && GameCtrl.I.gameRunData != null)
                  {
                     _loc3_ = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
                     _loc2_ = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
                     EffectCtrl.I.endBisha(_loc3_);
                     EffectCtrl.I.endBisha(_loc2_);
                     _loc3_.idle();
                     _loc2_.idle();
                  }
               }
            },{
               "label":GetLangText("system.menu.tool.child.open_savedata_folder.label"),
               "select":function(param1:Event):void
               {
                  var _loc2_:File = File.applicationStorageDirectory;
                  _loc2_.openWithDefaultApplication();
               }
            }])
         },{
            "label":GetLangText("system.menu.plugin.label"),
            "submenu":createMenu([])
         },{
            "label":GetLangText("system.menu.computer.label"),
            "submenu":createMenu([])
         },{
            "label":GetLangText("system.menu.help.label"),
            "submenu":createMenu([{
               "label":GetLangText("system.menu.help.child.website"),
               "submenu":createMenu(getLinkArray())
            },{"label":"-"},{
               "label":GetLangText("system.menu.help.child.about"),
               "select":showAbout
            }])
         }];
         return array;
      }
      
      private function showAbout(param1:Event) : void
      {
         var _loc2_:String = GetLangText("system.game_title") + "\n" + GetLangText("system.menu.help.child.about_items.ver") + "<b>" + UpdateUtils.I.version + "</b>\n" + GetLangText("system.menu.help.child.about_items.date") + UpdateUtils.I.date + "\n" + GetLangText("system.menu.help.child.about_items.air_ver") + Capabilities.version + "\n" + GetLangText("system.menu.help.child.about_items.make");
         messageBox(GetLangText("system.menu.help.child.about_items.msg_box_title"),_loc2_,300,150);
      }
      
      public function initialize(param1:Stage) : void
      {
         _stage = param1;
         _window = _stage.nativeWindow;
         _menu = createMenu(getMenuArray());
         var _loc2_:NativeMenuItem = findMenuItemByLabel(GetLangText("system.menu.plugin.label"),_menu);
         if(_loc2_ != null)
         {
            _loc2_.submenu.addItem(_noPlugItem);
         }
      }
      
      public function initPluginMenu() : void
      {
         var i:int;
         var pluginVO:PluginVO;
         var plugItem:NativeMenuItem;
         var plugins:Vector.<PluginVO> = PluginModel.I.getPlugins();
         var plugsItem:NativeMenuItem = findMenuItemByLabel(GetLangText("system.menu.plugin.label"),_menu);
         if(plugins.length > 0)
         {
            plugsItem.submenu.removeItem(_noPlugItem);
         }
         plugins.sort(0);
         i = 0;
         while(i < plugins.length)
         {
            pluginVO = plugins[i] as PluginVO;
            plugItem = createMenuItem({
               "name":pluginVO.id,
               "label":pluginVO.name,
               "enabled":!pluginVO.isRunBack,
               "select":function(param1:Event):void
               {
                  var _loc3_:NativeMenuItem = param1.target as NativeMenuItem;
                  var _loc2_:String = _loc3_.name;
                  createPluginWindow(PluginModel.I.getPlugin(_loc2_));
               }
            });
            plugsItem.submenu.addItem(plugItem);
            i = i + 1;
         }
      }
      
      public function initAIMenu() : void
      {
         var defaultItem:NativeMenuItem;
         var enabled:Boolean;
         var aivo:AIVO;
         var aiItem:NativeMenuItem;
         var select:* = function(param1:Event):void
         {
            var _loc3_:NativeMenuItem = param1.target as NativeMenuItem;
            var _loc2_:String = _loc3_.name;
            GameData.I.config.enableCurAI = _loc2_;
            unCheckedOtherItem(_loc3_,aisItem);
            GameData.I.saveData();
         };
         var ais:Vector.<AIVO> = AIModel.I.getAIs();
         var aisItem:NativeMenuItem = findMenuItemByLabel(GetLangText("system.menu.computer.label"),_menu);
         var defaultAIVO:AIVO = ais[0] as AIVO;
         if(ais.length == 1)
         {
            defaultItem = createMenuItem({
               "name":defaultAIVO.id,
               "label":defaultAIVO.name + " - " + defaultAIVO.author,
               "select":select
            });
            GameData.I.config.enableCurAI = defaultAIVO.id;
            defaultItem.checked = true;
            GameData.I.saveData();
            aisItem.submenu.addItem(defaultItem);
            return;
         }
         enabled = false;
         for each(aivo in ais)
         {
            aiItem = createMenuItem({
               "name":aivo.id,
               "label":aivo.name + " - " + aivo.author,
               "select":select
            });
            if(aivo.id == GameData.I.config.enableCurAI)
            {
               enabled = true;
               aiItem.checked = true;
            }
            aisItem.submenu.addItem(aiItem);
         }
         if(!enabled)
         {
            defaultItem = findMenuItemByLabel(defaultAIVO.name + " - " + defaultAIVO.author,aisItem.submenu);
            if(defaultItem != null)
            {
               GameData.I.config.enableCurAI = "default";
               defaultItem.checked = true;
               GameData.I.saveData();
            }
         }
      }
      
      public function updateMenu() : void
      {
         _window.menu = _menu;
      }
      
      public function showMenu() : void
      {
         if(!_isHidden || Boolean(_window.closed))
         {
            return;
         }
         _window.height += 20;
         updateMenu();
         _isHidden = false;
      }
      
      public function hiddenMenu() : void
      {
         if(_isHidden || Boolean(_window.closed))
         {
            return;
         }
         _window.height -= 20;
         _window.menu = null;
         _isHidden = true;
      }
      
      public function createMenuItem(param1:Object) : NativeMenuItem
      {
         var key:String;
         var listener:Function;
         var param:Object = param1;
         var isSeparator:* = function():Boolean
         {
            for(var _loc1_ in param)
            {
               if(_loc1_ == "label" && param[_loc1_] == "-")
               {
                  return true;
               }
            }
            return false;
         };
         var hasEnabled:* = function():Boolean
         {
            for(var _loc1_ in param)
            {
               if(_loc1_ == "enabled" && param[_loc1_] == false)
               {
                  return false;
               }
            }
            return true;
         };
         var getId:* = function():String
         {
            for(var _loc1_ in param)
            {
               if(_loc1_ == "name")
               {
                  return param[_loc1_];
               }
            }
            return null;
         };
         var item:NativeMenuItem = null;
         try
         {
            if(param)
            {
               item = new NativeMenuItem(null,isSeparator());
               for(key in param)
               {
                  var _loc4_:String = key;
                  if("select" !== _loc4_)
                  {
                     item[key] = param[key];
                  }
                  else if(hasEnabled())
                  {
                     listener = param[key] as Function;
                     if(listener != null)
                     {
                        item.addEventListener("select",listener);
                     }
                  }
                  else
                  {
                     startBackRun(PluginModel.I.getPlugin(getId()));
                  }
               }
            }
         }
         catch(e:Error)
         {
            throw new Error("MenuUtils::createMenuItem 参数不正确！");
         }
         return item;
      }
      
      public function createMenu(param1:Array) : NativeMenu
      {
         var _loc2_:NativeMenuItem = null;
         var _loc3_:NativeMenu = new NativeMenu();
         for each(var _loc4_ in param1)
         {
            _loc2_ = createMenuItem(_loc4_);
            _loc3_.addItem(_loc2_);
         }
         return _loc3_;
      }
      
      public function messageBox(param1:String = "", param2:String = "", param3:Number = 200, param4:Number = 100, param5:String = "center") : void
      {
         var _loc10_:NativeWindowInitOptions = new NativeWindowInitOptions();
         _loc10_.maximizable = false;
         _loc10_.minimizable = false;
         _loc10_.resizable = false;
         _loc10_.systemChrome = "standard";
         _loc10_.type = "normal";
         _loc10_.owner = _window;
         _loc10_.renderMode = "gpu";
         var _loc9_:NativeWindow = new NativeWindow(_loc10_);
         _loc9_.title = param1;
         var _loc8_:Stage = _loc9_.stage;
         _loc8_.scaleMode = "noScale";
         _loc8_.align = "TL";
         _loc9_.bounds = new Rectangle(_window.x + (_window.width - param3) * 0.5,_window.y + (_window.height - param4) * 0.5);
         _loc8_.stageWidth = param3;
         _loc8_.stageHeight = param4;
         var _loc7_:TextFormat = new TextFormat();
         _loc7_.font = "Microsoft YaHei";
         _loc7_.size = 12;
         _loc7_.align = param5;
         var _loc6_:TextField = new TextField();
         _loc6_.width = _loc9_.width;
         _loc6_.autoSize = "center";
         _loc6_.multiline = true;
         _loc6_.htmlText = param2;
         _loc6_.y = (_loc8_.stageHeight - _loc6_.height - 20) * 0.5;
         _loc6_.mouseEnabled = param2.indexOf("<a href=\"") != -1;
         _loc6_.setTextFormat(_loc7_);
         _loc8_.addChild(_loc6_);
         _loc9_.activate();
      }
      
      public function createPluginWindow(param1:PluginVO) : void
      {
         var pluginClass:Class;
         var windowOptions:NativeWindowInitOptions;
         var window:NativeWindow;
         var windowStage:Stage;
         var pluginMC:MovieClip;
         var initPlugin:Function;
         var paramObj:Object;
         var location:MovieClip;
         var width:Number;
         var height:Number;
         var pluginVO:PluginVO = param1;
         var id:String = pluginVO.id;
         if(_pluginActive.indexOf(id) != -1)
         {
            return;
         }
         pluginClass = pluginVO.cls;
         windowOptions = new NativeWindowInitOptions();
         windowOptions.maximizable = false;
         windowOptions.minimizable = false;
         windowOptions.resizable = false;
         windowOptions.systemChrome = "standard";
         windowOptions.type = "normal";
         windowOptions.owner = _window;
         windowOptions.renderMode = "gpu";
         window = new NativeWindow(windowOptions);
         window.title = pluginVO.name + " - " + pluginVO.author;
         windowStage = window.stage;
         windowStage.scaleMode = "noScale";
         windowStage.align = "TL";
         pluginMC = new pluginClass() as MovieClip;
         initPlugin = pluginMC.initPlugin as Function;
         if(initPlugin == null)
         {
            throw new Error("插件 " + pluginVO.name + " 未定义 initPlugin！");
         }
         paramObj = {};
         paramObj.mainStage = _stage;
         paramObj.stage = windowStage;
         paramObj.gameRender = GameRender;
         initPlugin(paramObj);
         location = pluginMC.getChildByName("location") as MovieClip;
         width = location.width;
         height = location.height;
         window.bounds = new Rectangle(_window.x + (_window.width - width) * 0.5,_window.y + (_window.height - height) * 0.5);
         windowStage.stageWidth = width;
         windowStage.stageHeight = height;
         windowStage.addChild(pluginMC);
         window.activate();
         window.addEventListener("close",function(param1:Event):void
         {
            var _loc2_:int = _pluginActive.indexOf(id);
            _pluginActive.splice(_loc2_,1);
         });
         _pluginActive.push(id);
      }
      
      public function startBackRun(param1:PluginVO) : void
      {
         var _loc5_:Class = param1.cls;
         var _loc2_:MovieClip = new _loc5_() as MovieClip;
         var _loc3_:Function = _loc2_.initPlugin as Function;
         if(_loc3_ == null)
         {
            throw new Error("插件 " + param1.name + " 未定义 initPlugin！");
         }
         var _loc4_:Object = {};
         _loc4_.mainStage = _stage;
         _loc4_.gameRender = GameRender;
         _loc3_(_loc4_);
      }
   }
}

