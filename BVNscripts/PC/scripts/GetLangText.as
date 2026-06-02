package
{
   import net.play5d.game.bvn.win.utils.MultiLangUtils;
   
   public function GetLangText(param1:String) : String
   {
      var _loc2_:String = MultiLangUtils.I.getLangText(param1);
      if(_loc2_ == null)
      {
         _loc2_ = "[N/A]";
      }
      return _loc2_;
   }
}

