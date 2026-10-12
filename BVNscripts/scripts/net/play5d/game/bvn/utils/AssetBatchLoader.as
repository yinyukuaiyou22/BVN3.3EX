package net.play5d.game.bvn.utils
{
   import flash.utils.*;
   import net.play5d.game.bvn.Debugger;
   
   /** AS3 批量并发加载调度器。
    *
    *  把资源加载从"逐个串行"（一个完成才发起下一个）改为 N 路并发：每发起一项，
    *  完成或失败后立刻补发下一项，直到队列取空。内置（APK）与外置（Android/media）
    *  资源共用同一条调度路径，并发度由调用方按资源体积给定。
    *
    *  重入安全：若 loadOne 在发起过程中同步回调（例如外置 XML 命中后同步解析完成、
    *  或角色 id 不存在时同步失败），pump 用固定栈深继续派发，不会递归爆栈、不会漏项、
    *  也不会提前触发整批完成。单项失败只记日志并继续，不中断整批。
    *
    *  用法：
    *     var b:AssetBatchLoader = new AssetBatchLoader();
    *     b.load(urls, loadOne, back, process, 4);
    *  loadOne(item, onDone, onFail, onProgress) —— onDone/onFail 各调用一次即结算该项。 */
   public class AssetBatchLoader
   {
      
      private var _items:Array;
      
      private var _loadOne:Function;
      
      private var _back:Function;
      
      private var _process:Function;
      
      private var _concurrency:int;
      
      private var _total:int;
      
      private var _done:int;
      
      private var _active:int;
      
      private var _nextIndex:int;
      
      private var _ratioByIndex:Object;
      
      private var _sumRatio:Number;
      
      private var _startTime:int;
      
      private var _inPump:Boolean;
      
      private var _pumpAgain:Boolean;
      
      private var _finished:Boolean;
      
      public function AssetBatchLoader()
      {
         super();
         this._ratioByIndex = {};
      }
      
      /** 并发加载一批资源。
       *  @param items       待加载项（任意对象，原样传给 loadOne）
       *  @param loadOne     function(item:*, onDone:Function, onFail:Function, onProgress:Function):void
       *  @param back        全部结算（成功或失败）后回调一次
       *  @param process     可选，function(ratio:Number):void，ratio 单调不减
       *  @param concurrency 并发度，<=0 时退回默认 4 */
      public function load(items:Array, loadOne:Function, back:Function, process:Function = null, concurrency:int = 4) : void
      {
         this._items = items != null ? items.concat() : [];
         this._loadOne = loadOne;
         this._back = back;
         this._process = process;
         this._concurrency = concurrency > 0 ? concurrency : 4;
         this._total = this._items.length;
         this._done = 0;
         this._active = 0;
         this._nextIndex = 0;
         this._ratioByIndex = {};
         this._sumRatio = 0;
         this._inPump = false;
         this._pumpAgain = false;
         this._finished = false;
         this._startTime = getTimer();
         if(this._total < 1)
         {
            this.finish();
            return;
         }
         this.pump();
      }
      
      private function pump() : void
      {
         if(this._inPump)
         {
            this._pumpAgain = true;
            return;
         }
         this._inPump = true;
         while(!this._finished && this._active < this._concurrency && this._items.length > 0)
         {
            this.startOne(this._items.shift());
         }
         this._inPump = false;
         if(this._pumpAgain)
         {
            this._pumpAgain = false;
            this.pump();
         }
      }
      
      private function startOne(item:*) : void
      {
         var index:int = this._nextIndex++;
         var settled:Boolean = false;
         this._ratioByIndex[index] = 0;
         this._active++;
         var onProgress:Function = function(ratio:Number) : void
         {
            if(settled) return;
            var old:Number = Number(_ratioByIndex[index]);
            _ratioByIndex[index] = ratio;
            _sumRatio += ratio - old;
            reportProcess();
         };
         var onDone:Function = function() : void
         {
            if(settled) return;
            settled = true;
            settle(index);
            reportProcess();
            pump();
            checkFinish();
         };
         var onFail:Function = function() : void
         {
            if(settled) return;
            settled = true;
            Debugger.log("[BATCH] 加载失败:", item);
            settle(index);
            reportProcess();
            pump();
            checkFinish();
         };
         try
         {
            this._loadOne(item,onDone,onFail,onProgress);
         }
         catch(e:Error)
         {
            Debugger.log("[BATCH] 发起加载异常:", item, e.message);
            onFail();
         }
      }
      
      private function settle(index:int) : void
      {
         this._sumRatio -= Number(this._ratioByIndex[index]);
         delete this._ratioByIndex[index];
         this._active--;
         this._done++;
      }
      
      private function checkFinish() : void
      {
         if(this._finished) return;
         if(this._done < this._total || this._active > 0) return;
         this.finish();
      }
      
      private function reportProcess() : void
      {
         if(this._process == null || this._finished) return;
         var ratio:Number = this._total > 0 ? (this._done + this._sumRatio) / this._total : 1;
         if(ratio > 1) ratio = 1;
         this._process(ratio);
      }
      
      private function finish() : void
      {
         if(this._finished) return;
         this._finished = true;
         if(this._process != null)
         {
            this._process(1);
         }
         Debugger.log("[BATCH] 批量加载完成:",this._total,"项, 耗时",getTimer() - this._startTime,"ms");
         var back:Function = this._back;
         this._back = null;
         this._loadOne = null;
         if(back != null)
         {
            back();
         }
      }
   }
}
