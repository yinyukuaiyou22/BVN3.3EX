package fl.motion
{
   public class ColorMatrix extends DynamicMatrix
   {
      
      protected static const LUMINANCER:Number = 0.3086;
      
      protected static const LUMINANCEG:Number = 0.6094;
      
      protected static const LUMINANCEB:Number = 0.082;
      
      public function ColorMatrix()
      {
         super(5,5);
         LoadIdentity();
      }
      
      public function SetBrightnessMatrix(value:Number) : void
      {
         if(!m_matrix)
         {
            return;
         }
         m_matrix[0][4] = value;
         m_matrix[1][4] = value;
         m_matrix[2][4] = value;
      }
      
      public function SetContrastMatrix(value:Number) : void
      {
         if(!m_matrix)
         {
            return;
         }
         var brightness:Number = 0.5 * (127 - value);
         value /= 127;
         m_matrix[0][0] = value;
         m_matrix[1][1] = value;
         m_matrix[2][2] = value;
         m_matrix[0][4] = brightness;
         m_matrix[1][4] = brightness;
         m_matrix[2][4] = brightness;
      }
      
      public function SetSaturationMatrix(value:Number) : void
      {
         if(!m_matrix)
         {
            return;
         }
         var subVal:Number = 1 - value;
         var mulVal:Number = subVal * LUMINANCER;
         m_matrix[0][0] = mulVal + value;
         m_matrix[1][0] = mulVal;
         m_matrix[2][0] = mulVal;
         mulVal = subVal * LUMINANCEG;
         m_matrix[0][1] = mulVal;
         m_matrix[1][1] = mulVal + value;
         m_matrix[2][1] = mulVal;
         mulVal = subVal * LUMINANCEB;
         m_matrix[0][2] = mulVal;
         m_matrix[1][2] = mulVal;
         m_matrix[2][2] = mulVal + value;
      }
      
      public function SetHueMatrix(angle:Number) : void
      {
         var j:int = 0;
         if(!m_matrix)
         {
            return;
         }
         LoadIdentity();
         var baseMat:DynamicMatrix = new DynamicMatrix(3,3);
         var cosBaseMat:DynamicMatrix = new DynamicMatrix(3,3);
         var sinBaseMat:DynamicMatrix = new DynamicMatrix(3,3);
         var cosValue:Number = Math.cos(angle);
         var sinValue:Number = Math.sin(angle);
         var lumR:Number = 0.213;
         var lumG:Number = 0.715;
         var lumB:Number = 0.072;
         baseMat.SetValue(0,0,lumR);
         baseMat.SetValue(1,0,lumR);
         baseMat.SetValue(2,0,lumR);
         baseMat.SetValue(0,1,lumG);
         baseMat.SetValue(1,1,lumG);
         baseMat.SetValue(2,1,lumG);
         baseMat.SetValue(0,2,lumB);
         baseMat.SetValue(1,2,lumB);
         baseMat.SetValue(2,2,lumB);
         cosBaseMat.SetValue(0,0,1 - lumR);
         cosBaseMat.SetValue(1,0,-lumR);
         cosBaseMat.SetValue(2,0,-lumR);
         cosBaseMat.SetValue(0,1,-lumG);
         cosBaseMat.SetValue(1,1,1 - lumG);
         cosBaseMat.SetValue(2,1,-lumG);
         cosBaseMat.SetValue(0,2,-lumB);
         cosBaseMat.SetValue(1,2,-lumB);
         cosBaseMat.SetValue(2,2,1 - lumB);
         cosBaseMat.MultiplyNumber(cosValue);
         sinBaseMat.SetValue(0,0,-lumR);
         sinBaseMat.SetValue(1,0,0.143);
         sinBaseMat.SetValue(2,0,-(1 - lumR));
         sinBaseMat.SetValue(0,1,-lumG);
         sinBaseMat.SetValue(1,1,0.14);
         sinBaseMat.SetValue(2,1,lumG);
         sinBaseMat.SetValue(0,2,1 - lumB);
         sinBaseMat.SetValue(1,2,-0.283);
         sinBaseMat.SetValue(2,2,lumB);
         sinBaseMat.MultiplyNumber(sinValue);
         baseMat.Add(cosBaseMat);
         baseMat.Add(sinBaseMat);
         for(var i:int = 0; i < 3; i++)
         {
            for(j = 0; j < 3; j++)
            {
               m_matrix[i][j] = baseMat.GetValue(i,j);
            }
         }
      }
      
      public function GetFlatArray() : Array
      {
         var j:int = 0;
         if(!m_matrix)
         {
            return null;
         }
         var ptr:Array = new Array();
         var index:int = 0;
         for(var i:int = 0; i < 4; i++)
         {
            for(j = 0; j < 5; j++)
            {
               ptr[index] = m_matrix[i][j];
               index++;
            }
         }
         return ptr;
      }
   }
}

class XFormData
{
   
   public var ox:Number;
   
   public var oy:Number;
   
   public var oz:Number;
   
   public function XFormData()
   {
      super();
   }
}
