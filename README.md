AS3-mp4info
===========
analyse metadata of MP4 file

Achieved
-------------
* video width
* video height
* video duration
* video coding type
* audio coding type

Todo
-------------
* bitrate
* audio sampling rate
* audio channel
* video frames
* video fps
* implement with javascript

Example
-------------
        // 1.input ByteArray
        var data:ByteArray = fr.data as ByteArray;
        var mp4:Mp4Box = new Mp4Box(data);
        
        // 2.analyse successfully
        if (mp4.isMp4)
        {
            // 3.let metadata write on foo's attribute
            Mp4Box.setMetaData(mp4);
            
            // 4.read them
            trace("fileSize->", mp4.fileSize, "bytes");
            trace("width->", mp4.width);
            trace("height->", mp4.height);
            trace("duration->", mp4.duration, "ms");
            trace("videoCoding->", mp4.videoCoding);
            trace("audioCoding->", mp4.audioCoding);
        }
