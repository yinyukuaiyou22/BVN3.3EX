package net.play5d.game.bvn.utils
{
   import net.play5d.kyo.utils.WebUtils;
   
   public class URL
   {
      
      public static var MARK:String = "bvn";
      
      public static const WEBSITE:String = "http://www.1212321.com/";
      
      public static const BBS:String = "http://bbs.1212321.com/";
      
      public static const BILIBILI:String = "https://space.bilibili.com/1340107883";
      
      public static const QQ_CHANNEL:String = "https://qun.qq.com/qqweb/qunpro/share?_wv=3&_wwv=128&appChannel=share&inviteCode=1W5HHlx&from=246611";
      
      public static const DOWNLOAD:String = "http://www.1212321.com/";
      
      public static const FEED_BACK:String = "https://support.qq.com/product/454324#label=show";
      
      public function URL()
      {
         super();
      }
      
      public static function go(param1:String, param2:Boolean = true) : void
      {
         var _loc3_:String = null;
         if(param2)
         {
            _loc3_ = markURL(param1);
            WebUtils.getURL(_loc3_);
         }
         else
         {
            WebUtils.getURL(param1);
         }
      }
      
      public static function markURL(param1:String) : String
      {
         var _loc2_:String = param1.indexOf("?") == -1 ? "?" : "&";
         return param1 + _loc2_ + MARK;
      }
      
      public static function website(... rest) : void
      {
         go("http://www.1212321.com/",false);
      }
      
      public static function bbs(... rest) : void
      {
         go("http://bbs.1212321.com/",false);
      }
      
      public static function download(... rest) : void
      {
         go("http://www.1212321.com/",false);
      }
      
      public static function bilibili(... rest) : void
      {
         go("https://space.bilibili.com/1340107883",false);
      }
      
      public static function feedBack(... rest) : void
      {
         go("https://support.qq.com/product/454324#label=show",false);
      }
      
      public static function qqChannel(... rest) : void
      {
         go("https://qun.qq.com/qqweb/qunpro/share?_wv=3&_wwv=128&appChannel=share&inviteCode=1W5HHlx&from=246611",false);
      }
   }
}

