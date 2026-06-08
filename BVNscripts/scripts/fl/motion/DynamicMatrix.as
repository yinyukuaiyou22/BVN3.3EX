package fl.motion
{
   public class DynamicMatrix
   {
      
      public static const MATRIX_ORDER_PREPEND:int = 0;
      
      public static const MATRIX_ORDER_APPEND:int = 1;
      
      protected var m_width:int;
      
      protected var m_height:int;
      
      protected var m_matrix:Array;
      
      public function DynamicMatrix(width:int, height:int)
      {
         super();
         this.Create(width,height);
      }
      
      protected function Create(width:int, height:int) : void
      {
         var i:int = 0;
         var j:int = 0;
         if(width > 0 && height > 0)
         {
            this.m_width = width;
            this.m_height = height;
            this.m_matrix = new Array(height);
            for(i = 0; i < height; i++)
            {
               this.m_matrix[i] = new Array(width);
               for(j = 0; j < height; j++)
               {
                  this.m_matrix[i][j] = 0;
               }
            }
         }
      }
      
      protected function Destroy() : void
      {
         this.m_matrix = null;
      }
      
      public function GetWidth() : Number
      {
         return this.m_width;
      }
      
      public function GetHeight() : Number
      {
         return this.m_height;
      }
      
      public function GetValue(row:int, col:int) : Number
      {
         var value:Number = 0;
         if(row >= 0 && row < this.m_height && col >= 0 && col <= this.m_width)
         {
            value = Number(this.m_matrix[row][col]);
         }
         return value;
      }
      
      public function SetValue(row:int, col:int, value:Number) : void
      {
         if(row >= 0 && row < this.m_height && col >= 0 && col <= this.m_width)
         {
            this.m_matrix[row][col] = value;
         }
      }
      
      public function LoadIdentity() : void
      {
         var i:int = 0;
         var j:int = 0;
         if(Boolean(this.m_matrix))
         {
            for(i = 0; i < this.m_height; i++)
            {
               for(j = 0; j < this.m_width; j++)
               {
                  if(i == j)
                  {
                     this.m_matrix[i][j] = 1;
                  }
                  else
                  {
                     this.m_matrix[i][j] = 0;
                  }
               }
            }
         }
      }
      
      public function LoadZeros() : void
      {
         var i:int = 0;
         var j:int = 0;
         if(Boolean(this.m_matrix))
         {
            for(i = 0; i < this.m_height; i++)
            {
               for(j = 0; j < this.m_width; j++)
               {
                  this.m_matrix[i][j] = 0;
               }
            }
         }
      }
      
      public function Multiply(inMatrix:DynamicMatrix, order:int = 0) : Boolean
      {
         var result:DynamicMatrix = null;
         var i:int = 0;
         var j:int = 0;
         var total:Number = NaN;
         var k:int = 0;
         var m:int = 0;
         if(!this.m_matrix || !inMatrix)
         {
            return false;
         }
         var inHeight:int = inMatrix.GetHeight();
         var inWidth:int = inMatrix.GetWidth();
         if(order == MATRIX_ORDER_APPEND)
         {
            if(this.m_width != inHeight)
            {
               return false;
            }
            result = new DynamicMatrix(inWidth,this.m_height);
            for(i = 0; i < this.m_height; i++)
            {
               for(j = 0; j < inWidth; j++)
               {
                  total = 0;
                  k = 0;
                  m = 0;
                  while(k < Math.max(this.m_height,inHeight) && m < Math.max(this.m_width,inWidth))
                  {
                     total += inMatrix.GetValue(k,j) * this.m_matrix[i][m];
                     k++;
                     m++;
                  }
                  result.SetValue(i,j,total);
               }
            }
            this.Destroy();
            this.Create(inWidth,this.m_height);
            for(i = 0; i < inHeight; i++)
            {
               for(j = 0; j < this.m_width; j++)
               {
                  this.m_matrix[i][j] = result.GetValue(i,j);
               }
            }
         }
         else
         {
            if(this.m_height != inWidth)
            {
               return false;
            }
            result = new DynamicMatrix(this.m_width,inHeight);
            for(i = 0; i < inHeight; i++)
            {
               for(j = 0; j < this.m_width; j++)
               {
                  total = 0;
                  k = 0;
                  m = 0;
                  while(k < Math.max(inHeight,this.m_height) && m < Math.max(inWidth,this.m_width))
                  {
                     total += this.m_matrix[k][j] * inMatrix.GetValue(i,m);
                     k++;
                     m++;
                  }
                  result.SetValue(i,j,total);
               }
            }
            this.Destroy();
            this.Create(this.m_width,inHeight);
            for(i = 0; i < inHeight; i++)
            {
               for(j = 0; j < this.m_width; j++)
               {
                  this.m_matrix[i][j] = result.GetValue(i,j);
               }
            }
         }
         return true;
      }
      
      public function MultiplyNumber(value:Number) : Boolean
      {
         var j:int = 0;
         var total:Number = NaN;
         if(!this.m_matrix)
         {
            return false;
         }
         for(var i:int = 0; i < this.m_height; i++)
         {
            for(j = 0; j < this.m_width; j++)
            {
               total = 0;
               total = this.m_matrix[i][j] * value;
               this.m_matrix[i][j] = total;
            }
         }
         return true;
      }
      
      public function Add(inMatrix:DynamicMatrix) : Boolean
      {
         var j:int = 0;
         var total:Number = NaN;
         if(!this.m_matrix || !inMatrix)
         {
            return false;
         }
         var inHeight:int = inMatrix.GetHeight();
         var inWidth:int = inMatrix.GetWidth();
         if(this.m_width != inWidth || this.m_height != inHeight)
         {
            return false;
         }
         for(var i:int = 0; i < this.m_height; i++)
         {
            for(j = 0; j < this.m_width; j++)
            {
               total = 0;
               total = this.m_matrix[i][j] + inMatrix.GetValue(i,j);
               this.m_matrix[i][j] = total;
            }
         }
         return true;
      }
   }
}

