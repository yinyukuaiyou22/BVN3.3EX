package net.play5d.game.bvn.mob
{
   import flash.display.Stage;
   import flash.events.AccelerometerEvent;
   import flash.sensors.*;
   
   public class ScreenRotater
   {
      
      private static var _i:ScreenRotater;
      
      public var sensitivity:Number = 0.8;
      
      private var _accer:Accelerometer;
      
      private var _currentOrientation:String;
      
      private var _stage:Stage;
      
      public function ScreenRotater()
      {
         super();
      }
      
      public static function get I() : ScreenRotater
      {
         if(!_i)
         {
            _i = new ScreenRotater();
         }
         return _i;
      }
      
      public function isSupported() : Boolean
      {
         return Accelerometer.isSupported;
      }
      
      public function init(param1:Stage) : void
      {
         this._stage = param1;
         if(!Accelerometer.isSupported)
         {
            param1.autoOrients = true;
            this._stage.setOrientation("rotatedRight");
            return;
         }
         param1.autoOrients = false;
         this.setOrientation("rotatedRight");
         this._accer = new Accelerometer();
         this._accer.addEventListener("update",this.accUpdate);
      }
      
      private function setOrientation(param1:String) : void
      {
         if(this._currentOrientation == param1)
         {
            return;
         }
         this._currentOrientation = param1;
         this._stage.setOrientation(param1);
      }
      
      private function accUpdate(param1:AccelerometerEvent) : void
      {
         if(this._currentOrientation == "rotatedLeft")
         {
            if(param1.accelerationY < -this.sensitivity)
            {
               this.setOrientation("rotatedRight");
               return;
            }
         }
         if(this._currentOrientation == "rotatedRight")
         {
            if(param1.accelerationY < -this.sensitivity)
            {
               this.setOrientation("rotatedLeft");
               return;
            }
         }
      }
   }
}

