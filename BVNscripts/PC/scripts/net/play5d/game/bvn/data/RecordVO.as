package net.play5d.game.bvn.data
{
   import flash.desktop.NativeApplication;
   import flash.events.Event;
   import flash.filesystem.File;
   import flash.filesystem.FileStream;
   import flash.net.URLRequest;
   import flash.net.URLVariables;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.win.utils.FileUtils;
   import net.play5d.game.bvn.win.utils.UpdateUtils;
   import net.play5d.kyo.utils.KyoUtils;
   import net.play5d.patchouli.utils.ClassUtil;
   
   public class RecordVO implements ISaveData
   {
      
      public var fights_single:Array = [];
      
      public var fights_team:Array = [];
      
      public function RecordVO()
      {
         super();
      }
      
      public function toSaveObj() : Object
      {
         var _loc3_:Object = {};
         var _loc1_:Array = ClassUtil.getClassProperty(RecordVO);
         if(_loc1_ == null)
         {
            throw new Error("指定类没有公开属性！");
         }
         for each(var _loc2_ in _loc1_)
         {
            _loc3_[_loc2_] = this[_loc2_];
         }
         return _loc3_;
      }
      
      public function readSaveObj(param1:Object) : void
      {
         KyoUtils.setValueByObject(this,param1);
      }
      
      public function addRecord(param1:int = 0, param2:Object = null) : void
      {
         var _loc3_:Object = param2;
         _loc3_.time = getTime();
         _loc3_.version = UpdateUtils.I.version;
         if(param1 == 0)
         {
            fights_single.push(_loc3_);
         }
         if(param1 == 1)
         {
            fights_team.push(_loc3_);
         }
         saveRecord();
      }
      
      public function saveRecord() : void
      {
         GameInterface.instance.saveRecord(GameData.I.record.toSaveObj());
         Trace("记录数据: 单人模式" + fights_single.length + "局；小队模式" + fights_team.length + "局");
         uploadRecord(10);
      }
      
      public function uploadRecord(param1:int = 10, param2:Boolean = false) : Boolean
      {
         var path:String;
         var file:File;
         var stream:FileStream;
         var bytes:ByteArray;
         var params:URLVariables;
         var request:URLRequest;
         var recordUploaded:*;
         var num:int = param1;
         var autoExit:Boolean = param2;
         if(!GameData.I.config.isUploadRecord)
         {
            return false;
         }
         if(fights_single.length + fights_team.length >= num)
         {
            recordUploaded = function(param1:Event):void
            {
               Trace("上传数据成功，本地数据已清空");
               fights_single.length = 0;
               fights_team.length = 0;
               GameInterface.instance.saveRecord(GameData.I.record.toSaveObj());
               if(autoExit)
               {
                  NativeApplication.nativeApplication.exit();
               }
            };
            path = FileUtils.getAppStorageFloderFileUrl("record.json");
            file = new File(path);
            stream = new FileStream();
            stream.open(file,"read");
            bytes = new ByteArray();
            stream.readBytes(bytes,0,stream.bytesAvailable);
            stream.close();
            params = new URLVariables();
            params.key = "record_" + getTime() + ".json";
            params.token = "hhq48tXOPFJHlwQ0ghGXNBSAIujbltM8VlZlO7qi:4I1tUS659tdM6Lq-Ta74FHroUhM=:eyJzY29wZSI6ImJ2bi1yZWNvcmRzIiwiZGVhZGxpbmUiOjIwMDAwMDAwMDAsImRldGVjdE1pbWUiOjF9";
            params.file = bytes;
            request = new URLRequest("http://up-as0.qiniup.com/");
            request.method = "POST";
            request.contentType = "multipart/form-data";
            request.data = params;
            try
            {
               file.addEventListener("complete",recordUploaded);
               file.upload(request);
            }
            catch(error:Error)
            {
               Trace("上传数据失败: " + error.message);
            }
            return true;
         }
         return false;
      }
      
      private function getTime() : String
      {
         var fix:* = function(param1:int, param2:int = 2):String
         {
            return ("" + param1).length < param2 ? (new Array(param2 + 1).join("0") + param1).slice(-param2) : "" + param1;
         };
         var current:Date = new Date();
         return current.fullYear.toString() + "." + fix(current.month + 1) + "." + fix(current.date) + "_" + fix(current.hours) + "." + fix(current.minutes) + "." + fix(current.seconds);
      }
   }
}

