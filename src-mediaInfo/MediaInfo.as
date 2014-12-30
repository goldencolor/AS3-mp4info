package
{
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	public class MediaInfo extends MovieClip
	{
		/**
		 * UI资源
		 * 
		 */
		public var mcPanel:MovieClip;
		public var btnSelectFile:SimpleButton;
		public var tfFileName:TextField;
		public var tfFileType:TextField;
		public var tfFileSize:TextField;
		public var tfFileDetailInfo:TextField;
		public var tfLoadProgress:TextField;
		
		/**
		 * 数据资源
		 * 
		 */
		public var frVideo:FileReference;
		
		public function MediaInfo()
		{
			super();
			trace("MediaInfo->MediaInfo");
			mcPanel = getChildByName("mcPanel") as MovieClip;
			btnSelectFile = mcPanel.btn_selectFile as SimpleButton;
			tfFileName = mcPanel.TF_fileName as TextField;
			tfFileType = mcPanel.TF_fileType as TextField;
			tfFileSize = mcPanel.TF_fileSize as TextField;
			tfFileDetailInfo = mcPanel.TF_detailInfo as TextField;
			tfLoadProgress = mcPanel.TF_loadProgress as TextField;
			
			init();
		}
		
		private function init():void {
			trace("MediaInfo->init");
			tfFileName.text = "";
			tfFileSize.text = "";
			tfFileType.text = "";
			tfFileDetailInfo.text = "";
			tfLoadProgress.text = "";
			
			btnSelectFile.removeEventListener(MouseEvent.CLICK, onClickBtn);
			btnSelectFile.addEventListener(MouseEvent.CLICK, onClickBtn); 
		}
		
		private function onClickBtn(event:MouseEvent):void {
			trace("MediaInfo->onClickBtn");
			//var filter:FileFilter = new FileFilter("mp4", "*.mp4");
			frVideo = new FileReference();
			frVideo.browse(/*[filter]*/);
			if (!frVideo.hasEventListener(Event.SELECT)) 
			{
				frVideo.addEventListener(Event.SELECT, onSelectFile);
			}
		}
		
		private function onSelectFile(event:Event):void {
			trace("MediaInfo->onSelectFile");
			btnSelectFile.enabled = false;
			btnSelectFile.removeEventListener(MouseEvent.CLICK, onClickBtn);
			if (!frVideo.hasEventListener(Event.COMPLETE)) 
			{
				frVideo.addEventListener(Event.COMPLETE, onFileLoaded);
				frVideo.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
				frVideo.addEventListener(ProgressEvent.PROGRESS, onProgress);
			}
			
			//
			tfFileName.text = "";
			tfFileSize.text = "";
			tfFileType.text = "";
			tfFileDetailInfo.text = "";
			tfLoadProgress.text = "";
			// 加载文件
			frVideo.load();
		}
		
		private function onFileLoaded(event:Event):void {
			trace("MediaInfo->onFileLoaded");
			btnSelectFile.enabled = true;
			btnSelectFile.addEventListener(MouseEvent.CLICK, onClickBtn); 
			var fr:FileReference = event.target as FileReference;
			
			tfFileName.text = fr.name;
			tfFileSize.text = fr.size.toString() + "字节";
			tfFileType.text = fr.type;
			
			// 载入MP4
			var data:ByteArray = fr.data as ByteArray;			
			var mp4:Mp4Box = new Mp4Box(data);
			if (mp4.isMp4) 
			{
				Mp4Box.setMetaData(mp4);
				
				if (ExternalInterface.available) 
				{
					ExternalInterface.call("console.log", "fileSize->", mp4.size);
					ExternalInterface.call("console.log", "width->", mp4.width);
					ExternalInterface.call("console.log", "height->", mp4.height);
					ExternalInterface.call("console.log", "duration->", mp4.duration);
					ExternalInterface.call("console.log", "videoCoding->", mp4.videoCoding);
					ExternalInterface.call("console.log", "audioCoding->", mp4.audioCoding);
				}
				else
				{
					trace("fileSize->", mp4.fileSize, "bytes");
					trace("width->", mp4.width);
					trace("height->", mp4.height);
					trace("duration->", mp4.duration, "ms");
					trace("videoCoding->", mp4.videoCoding);
					trace("audioCoding->", mp4.audioCoding);
				}
				
				tfFileDetailInfo.text = "   fileSize: " + mp4.fileSize + 'bytes' + "\n"
					+ "      width: " + mp4.width + "\n"
					+ "     height: " + mp4.height + "\n"
					+ "   duration: " + mp4.duration + 'ms' + "\n"
					+ "videoCoding: " + mp4.videoCoding + "\n"
					+ "audioCoding: " + mp4.audioCoding + "\n";
			}
			else
			{
				if (ExternalInterface.available) 
				{
					ExternalInterface.call("console.log", "fileSize->", "error");
					ExternalInterface.call("console.log", "width->", "error");
					ExternalInterface.call("console.log", "height->", "error");
					ExternalInterface.call("console.log", "duration->", "error");
					ExternalInterface.call("console.log", "videoCoding->", "error");
					ExternalInterface.call("console.log", "audioCoding->", "error");
				}
				else
				{
					trace("fileSize->", "error");
					trace("width->", "error");
					trace("height->", "error");
					trace("duration->", "error");
					trace("videoCoding->", "error");
					trace("audioCoding->", "error");
				}
				
				tfFileDetailInfo.text = "不能以MP4格式解析其数据！";
			}
			
			// 释放资源
			mp4 = null;
			fr = null;
		}
		
		private function onFileLoadError(e:ErrorEvent):void {
			trace("MediaInfo->onFileLoadError");
			btnSelectFile.enabled = true;
			btnSelectFile.addEventListener(MouseEvent.CLICK, onClickBtn); 
			tfFileDetailInfo.text = "fileLoadError:" + e.toString();
		}
		
		private function onProgress(e:ProgressEvent):void {
			var progress:uint = parseInt((100 * e.bytesLoaded / e.bytesTotal).toString());
			tfLoadProgress.text = "文件读取进度：" + progress.toString() + "%";
			if (progress == 100) 
			{
				setTimeout(function(){
					tfLoadProgress.visible = false;
				}, 100);
			}
			else if(progress == 0) 
			{
				tfLoadProgress.visible = true;
			}
				
			//trace("MediaInfo->onProgress->", progress, "%");
		}
		
		private function destory():void {
					
		}
	}
}
