package
{
	import flash.external.ExternalInterface;
	import flash.utils.ByteArray;
	
	import flashx.textLayout.elements.BreakElement;

	public class Mp4Box
	{
		// box头部3个字段长度
		public static var H_SIZE_LEN:uint = 4;
		public static var H_NAME_LEN:uint = 4;
		public static var H_LARGE_SIZE_LEN:uint = 8;
		
		// box结点类型
		public static var TYPE_ROOT:String = "TYPE_ROOT";
		public static var TYPE_CONTAINER:String = "TYPE_CONTAINER";
		public static var TYPE_LEAF:String = "TYPE_LEAF";
		
		// 重要的box
		public static var BOX_MVHD:String = "mvhd";
		public static var BOX_SMHD:String = "smhd";
		public static var BOX_VMHD:String = "vmhd";
		public static var BOX_TKHD:String = "tkhd";
		public static var BOX_STSD:String = "stsd";
		
		// 不需要写入data的box
		public static var NO_DATA_BOX:String = "mdat";
		
		// video编码可能的值
		public static var CODING_VIDEO:String = "avc|avc1|h264";
		
		// audio编码可能的值
		public static var CONDING_AUDIO:String = "mp4a|acc";
		
		// box结点类型
		public var type:String;
		// box头：box尺寸
		public var size:uint;
		// box头：box名称
		public var name:String;
		// box头：超大box尺寸
		// public var largeSize:ByteArray;
		// 头部大小
		public var hSize:uint;
		// box data offset
		public var offset:uint;
		// box数据部分
		public var data:ByteArray;
		// 父结点
		public var parent:Mp4Box;
		// 子结点
		public var children:Vector.<Mp4Box> = new Vector.<Mp4Box>();
		
		//
		public var root:Mp4Box;
		
		// 元数据
		public var isMp4:Boolean = true;
		// 文件大小
		public var fileSize:uint;
		// video宽
		public var width:uint;
		// video高
		public var height:uint;
		// video时长，单位：毫秒
		public var duration:uint;
		// video编码
		public var videoCoding:String;
		// audio编码
		public var audioCoding:String;
		
		/**
		 * 构造函数
		 * @Param data {ByteArray} MP4二进制数据
		 * @Param isRoot {Boolean} 是整个MP4文件
		 */
		public function Mp4Box(data:ByteArray, parent:Mp4Box = null, root:Mp4Box = null)
		{	
//			if (ExternalInterface.available) 
//			{
//				ExternalInterface.call("console.log", "Mp4Box");
//			}
//			else 
//			{
//				trace("Mp4Box");
//			}
			this.offset = data.position;
			// MP4 ROOT
			if (root == null) 
			{
				this.type = Mp4Box.TYPE_ROOT;
				this.size = data.length;
				this.name = "";
				this.data = data;
				this.parent = null;
				this.root = this;
				// 文件大小
				this.fileSize = data.length;
				try
				{
					this.getChildren();
				} 
				catch(error:Error) 
				{
					this.isMp4 = false;
					return;
				}
			}
			// MP4 内的box
			else
			{
				var size:ByteArray =  new ByteArray();
				var name:ByteArray = new ByteArray();
				data.readBytes(size, 0, Mp4Box.H_SIZE_LEN);
				data.readBytes(name, 0, Mp4Box.H_NAME_LEN);
				this.root = root;
				this.size = size.readUnsignedInt();
				this.name = name.readUTFBytes(Mp4Box.H_NAME_LEN);
				if (ExternalInterface.available) 
				{
					ExternalInterface.call("console.log", ">>", "-----", "name->", this.name);
				}
				else 
				{
					trace(">>", "-----", "name->", this.name);
				}
				this.parent = parent;
				var headerSize:uint = Mp4Box.H_SIZE_LEN + Mp4Box.H_NAME_LEN;
				
				//todo: 处理hSize == 1
				
				var bodySize = this.size - headerSize;
				this.data = new ByteArray();
				
				if (bodySize > 0 && this.name != "mdat")
				{
					var bytesAvailable:uint = data.bytesAvailable;
					var position:uint = data.position;
					
					// 防止溢出
					try
					{
						data.readBytes(this.data, 0, bodySize);
					} 
					catch (error:Error) 
					{
						this.data = new ByteArray();
						data.position = position;
						data.readBytes(this.data, 0, bytesAvailable);
					}
					
					if (bodySize > 8) 
					{
						this.getChildren();
					}
				}
				else
				{
					this.data = new ByteArray();
					// 跳过mdat数据段
					if (this.name == "mdat") 
					{
						var offset:uint = 0;
						for (var i:int = 0; i < root.children.length; i++) 
						{
							offset += root.children[i].size;
						}
						this.root.data.position = offset;
					}
				}
				
				if (ExternalInterface.available) 
				{
					ExternalInterface.call("console.log", "<<", "-----", "name->", this.name, "-----", "childrenLen->", this.children.length, "-----", "dataLen->", this.data.length);
				}
				else 
				{
					trace("<<", "-----", "name->", this.name, "-----", "childrenLen->", this.children.length, "-----", "dataLen->", this.data.length);
				}
			}
		}
		
		public static function parseMetaData(box:Mp4Box):void
		{
			var vipBoxNames:String = Mp4Box.BOX_MVHD + Mp4Box.BOX_STSD + Mp4Box.BOX_TKHD;
			var name:String = box.name.toLowerCase();

			if (~vipBoxNames.indexOf(name)) 
			{
				var data:ByteArray = box.data;
				if (data == null || data.length == 0) 
				{
					return;
				}

				switch(name)
				{
					// 提取时长
					case Mp4Box.BOX_MVHD:
						data.position = 12;
						var timeScale:uint = data.readUnsignedInt();
						var duration:uint = data.readUnsignedInt();
						box.root.duration = duration * 1000 / timeScale;
						break;
					// 提取音视频编码类型
					case Mp4Box.BOX_STSD:
						data.position = 12;
						var coding:String = data.readUTFBytes(4);
						// 音频
						if (box.parent.parent.children[0].name == Mp4Box.BOX_SMHD) 
						{
							// 多音轨时检查
							if (box.root.audioCoding && box.root.audioCoding != coding) 
							{
								// 多音轨编码不同
								box.root.audioCoding = "mix";
							}
							else
							{
								box.root.audioCoding = coding;
							}
						}
						// 视频
						else if (box.parent.parent.children[0].name == Mp4Box.BOX_VMHD) 
						{
							box.root.videoCoding = coding;
						}
						break;
					// 提取视频尺寸
					case Mp4Box.BOX_TKHD:
						data.position = 76;
						var width:uint = data.readUnsignedShort();
						data.position = 80;
						var height:uint = data.readUnsignedShort();
						if (width && height) 
						{
							box.root.width = width;
							box.root.height = height;
						}
						break;
				}
				data.position = 0;
			}
		}
		
		public static function setMetaData(box:Mp4Box):void
		{
//			if (ExternalInterface.available) 
//			{
//				ExternalInterface.call("console.log", "setMetaData");
//			}
//			else 
//			{
//				trace("setMetaData");
//			}
			if (box.type == Mp4Box.TYPE_ROOT) 
			{
				for each (var subBox:Mp4Box in box) 
				{
					if (subBox.children.length > 0) 
					{
						for each (var child:Mp4Box in subBox.children) 
						{
							Mp4Box.setMetaData(child);
						}
					}
					else
					{
						Mp4Box.parseMetaData(box);
					}
				}
			}
			else
			{
				if (box.children.length > 0) 
				{
					for each (var child2:Mp4Box in box.children) 
					{
						Mp4Box.setMetaData(child2);
					}
				}
				else
				{
					Mp4Box.parseMetaData(box);
				}
			}
		}
		
		public static function print(box:Mp4Box):void
		{
			return;
			trace("name->", box.name);
			trace("size->", box.size);
			trace("childrenCount->", box.children.length);
			trace("type->", box.type);
			trace("=============================================");
		}
		
		/**
		 * 获取当前Box的子Box
		 * 
		 */
		public function getChildren():void
		{
//			if (ExternalInterface.available) 
//			{
//				ExternalInterface.call("console.log", "getChildren");
//			}
//			else 
//			{
//				trace("getChildren");
//			}
			while(data.bytesAvailable > 0)
			{
				// box name至少三位必须是英文字符，第四位是英文字符或者00
				if (this.getBoxName(data).length > 2) 
				{
					var mp4Box:Mp4Box = new Mp4Box(data, this, this.root);
					this.children.push(mp4Box);
				}
				// 指针移动到下一个Box
				else if (this.type == Mp4Box.TYPE_ROOT)
				{
					break;
//					var offset:uint = 0;
//					for (var j:int = 0; j < root.children.length; j++) 
//					{
//						offset += root.children[j].size;
//					}
//					data.position = offset;
//					if (offset >= root.size) 
//					{
//						break;
//					}
				}
				else
				{
					data.position = size;
				}
			}
			
			// 确定结点类型
			if (children.length > 0 && this.name != "mdat") 
			{
				// 是普通结点
				this.type = Mp4Box.TYPE_CONTAINER;
				Mp4Box.print(this);
				for (var i:int = 0; i < children.length; i++) 
				{
					var box:Mp4Box = children[i] as Mp4Box;
					box.getChildren();
				}
			}
			else
			{
				if (this.type == Mp4Box.TYPE_ROOT) 
				{
					this.root.isMp4 = false;
				}
				else
				{
					// 是叶子结点
					this.type = Mp4Box.TYPE_LEAF;
					Mp4Box.print(this);
				}
			}
		}
		
		/**
		 * 获取box name，如果不是box则返回空字符串
		 * 如果box name不是ASCII就认为不是box name
		 * 
		 */
		public function getBoxName(data:ByteArray):String
		{
//			if (ExternalInterface.available) 
//			{
//				ExternalInterface.call("console.log", "getBoxName");
//			}
//			else 
//			{
//				trace("getBoxName");
//			}
			if (data.length < Mp4Box.H_NAME_LEN + Mp4Box.H_SIZE_LEN)
			{
				return "";
			}
			var nameBytes:ByteArray = new ByteArray();
			var oldPosition:uint = data.position;
			// 指针移动到box length末尾
			data.position = Mp4Box.H_SIZE_LEN;
			data.readBytes(nameBytes, 0, Mp4Box.H_NAME_LEN);
			
			var name:String = "";
			var nameChar:String = "";
			var charCode:uint;
			var nameValidate:ByteArray = new ByteArray();
			while(nameBytes.bytesAvailable) 
			{
				nameChar = nameBytes.readUTFBytes(1);
				charCode = nameChar.charCodeAt(0);
				// box name至少三位必须是英文字符，第四位是英文字符或者00
				if ((charCode >= 65 && charCode <= 90)
					|| (charCode >= 97 && charCode <= 122))
				{
					name += nameChar;
					nameValidate.writeByte(1);
				}
			}

			// 指针移动到读取之前的位置
			data.position = oldPosition;
			if (nameValidate.length < 4) 
			{
				return "";	
			}
			return name;
		}
	}
}

