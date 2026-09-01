package net.play5d.game.bvn.data
{
   public class SelectCharListConfigVO
   {
      // 批次6：人物子框数据从 SelectCharListItemVO.pluginIDs 读取（每个 item 独立配置）
      // 预留位置，本类暂不增加字段；详见 doc/feature/sub-frame/ 规划文档

      public var list:Array = [];

      public var HCount:int;

      public var VCount:int;
      
      public function SelectCharListConfigVO()
      {
         super();
      }
   }
}

