package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.interfaces.*;
   
   public class TeamVO
   {
      
      public var id:int;
      
      public var name:String;
      
      public var children:Vector.<IGameSprite> = new Vector.<IGameSprite>();
      
      public function TeamVO(param1:int, param2:String = null)
      {
         super();
         this.id = param1;
         this.name = param2;
      }
      
      public function getAliveChildren() : Vector.<IGameSprite>
      {
         var _loc1_:int = 0;
         var _loc2_:IGameSprite = null;
         var _loc3_:Vector.<IGameSprite> = new Vector.<IGameSprite>();
         while(_loc1_ < this.children.length)
         {
            _loc2_ = this.children[_loc1_];
            if(_loc2_ is BaseGameSprite)
            {
               if((_loc2_ as BaseGameSprite).isAlive)
               {
                  _loc3_.push(_loc2_);
               }
            }
            else
            {
               _loc3_.push(_loc2_);
            }
            _loc1_++;
         }
         return _loc3_;
      }
      
      public function addChild(param1:IGameSprite) : void
      {
         var _loc2_:int = int(this.children.indexOf(param1));
         if(_loc2_ == -1)
         {
            this.children.push(param1);
         }
      }
      
      public function removeChild(param1:IGameSprite) : void
      {
         var _loc2_:int = int(this.children.indexOf(param1));
         if(_loc2_ != -1)
         {
            this.children.splice(_loc2_,1);
         }
      }
   }
}

