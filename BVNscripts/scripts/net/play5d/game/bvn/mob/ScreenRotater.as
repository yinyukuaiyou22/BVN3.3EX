package net.play5d.game.bvn.mob
{
   import flash.display.Stage;
   import flash.events.AccelerometerEvent;
   import flash.sensors.Accelerometer;
   
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
         _stage = param1;
         if(!Accelerometer.isSupported)
         {
            param1.autoOrients = true;
            _stage.setOrientation("rotatedRight");
            return;
         }
         param1.autoOrients = false;
         setOrientation("rotatedRight");
         _accer = new Accelerometer();
         _accer.addEventListener("update",accUpdate);
      }
      
      private function setOrientation(param1:String) : void
      {
         if(_currentOrientation == param1)
         {
            return;
         }
         _currentOrientation = param1;
         _stage.setOrientation(param1);
      }
      
      private function accUpdate(param1:AccelerometerEvent) : void
      {
         if(_currentOrientation == "rotatedLeft")
         {
            if(param1.accelerationY < -sensitivity)
            {
               setOrientation("rotatedRight");
               return;
            }
         }
         if(_currentOrientation == "rotatedRight")
         {
            if(param1.accelerationY < -sensitivity)
            {
               setOrientation("rotatedLeft");
               return;
            }
         }
      }
   }
}

