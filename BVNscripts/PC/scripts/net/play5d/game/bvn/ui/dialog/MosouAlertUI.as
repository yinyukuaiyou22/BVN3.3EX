package net.play5d.game.bvn.ui.dialog
{
   public class MosouAlertUI extends MosouConfrimUI
   {
      
      public function MosouAlertUI()
      {
         super();
         build();
      }
      
      override protected function build() : void
      {
         super.build();
         _noBtn.visible = false;
         _yesBtn.x = 253;
      }
   }
}

