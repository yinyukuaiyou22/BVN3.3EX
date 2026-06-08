package flash.compiler.embed
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   
   public class EmbeddedMovieClip extends MovieClip
   {
      private var loader:Loader = null;
      
      private var initialized:Boolean = false;
      
      private var requestedWidth:Number;
      
      private var requestedHeight:Number;
      
      private var bytes:ByteArray;
      
      protected var initialWidth:Number = 0;
      
      protected var initialHeight:Number = 0;
      
      public function EmbeddedMovieClip(data:ByteArray, width:Number, height:Number)
      {
         super();
         bytes = data;
         initialWidth = width;
         initialHeight = height;
         var context:LoaderContext = new LoaderContext();
         context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
         if("allowLoadBytesCodeExecution" in context)
         {
            context["allowLoadBytesCodeExecution"] = true;
         }
         loader = new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,completeHandler);
         loader.loadBytes(movieClipData,context);
         addChild(loader);
      }
      
      override public function get height() : Number
      {
         if(!initialized)
         {
            return initialHeight;
         }
         return super.height;
      }
      
      override public function set height(v:Number) : void
      {
         if(!initialized)
         {
            requestedHeight = v;
         }
         else
         {
            loader.height = v;
         }
      }
      
      override public function get width() : Number
      {
         if(!initialized)
         {
            return initialWidth;
         }
         return super.width;
      }
      
      override public function set width(v:Number) : void
      {
         if(!initialized)
         {
            requestedWidth = v;
         }
         else
         {
            loader.width = v;
         }
      }
      
      public function get movieClipData() : ByteArray
      {
         return bytes;
      }
      
      private function completeHandler(evt:Event) : void
      {
         initialized = true;
         initialWidth = loader.contentLoaderInfo.width;
         initialHeight = loader.contentLoaderInfo.height;
         if(!isNaN(requestedWidth))
         {
            loader.width = requestedWidth;
         }
         if(!isNaN(requestedHeight))
         {
            loader.height = requestedHeight;
         }
         dispatchEvent(evt);
      }
   }
}

