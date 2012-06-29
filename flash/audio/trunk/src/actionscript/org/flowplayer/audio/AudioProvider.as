/*     *    Copyright 2008, 2009 Flowplayer Oy * *    This file is part of FlowPlayer. * *    FlowPlayer is free software: you can redistribute it and/or modify *    it under the terms of the GNU General Public License as published by *    the Free Software Foundation, either version 3 of the License, or *    (at your option) any later version. * *    FlowPlayer is distributed in the hope that it will be useful, *    but WITHOUT ANY WARRANTY; without even the implied warranty of *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the *    GNU General Public License for more details. * *    You should have received a copy of the GNU General Public License *    along with FlowPlayer.  If not, see <http://www.gnu.org/licenses/>. */package org.flowplayer.audio {    import flash.display.DisplayObject;    import flash.display.Loader;    import flash.events.Event;    import flash.events.IOErrorEvent;    import flash.events.ProgressEvent;    import flash.events.TimerEvent;    import flash.media.ID3Info;    import flash.media.Sound;    import flash.media.SoundChannel;    import flash.media.SoundLoaderContext;    import flash.net.NetConnection;    import flash.net.NetStream;    import flash.net.URLRequest;    import flash.utils.Dictionary;    import flash.utils.Timer;    import org.flowplayer.controller.ClipURLResolverHelper;    import org.flowplayer.controller.ConnectionProvider;    import org.flowplayer.controller.ResourceLoader;    import org.flowplayer.controller.StreamProvider;    import org.flowplayer.controller.TimeProvider;    import org.flowplayer.controller.VolumeController;    import org.flowplayer.model.Clip;    import org.flowplayer.model.ClipError;    import org.flowplayer.model.ClipEvent;    import org.flowplayer.model.ClipEventType;    import org.flowplayer.model.Playlist;    import org.flowplayer.model.Plugin;    import org.flowplayer.model.PluginModel;    import org.flowplayer.util.Log;    import org.flowplayer.view.Flowplayer;    /**     * @author api     */    public class AudioProvider implements StreamProvider, Plugin {        private var log:Log = new Log(this);        private var _sound:Sound;        private var _paused:Boolean;        private var _durationSeconds:Number;        private var _prevClip:Clip;        private var _pausedPosition:Number;        private var _channel:SoundChannel;        private var _playlist:Playlist;        private var _progressTimer:Timer;        private var _seeking:Boolean;        private var _started:Boolean;        private var _volumeController:VolumeController;        private var _pauseAfterStart:Boolean;        private var _bufferFullDispatched:Boolean;        private var _timeProvider:TimeProvider;        private var _model:PluginModel;        private var _lastDurationDispatched:Number = 0;        private var _imageLoader:ResourceLoader;        private var _imageDisplay:Loader = null;        private var context:SoundLoaderContext;        private var _clipUrlResolverHelper:ClipURLResolverHelper;        private var _metadataDispatched:Boolean;        public function stop(event:ClipEvent, closeStream:Boolean = false):void {            seek(null, 0);            if (_channel) {                log.debug("in stop(), stopping channel");                _channel.stop();            }            if (closeStream || clip.live) {                closeSound();            }            resetState();            if (event && clip) {                clip.dispatchEvent(event);            }        }        private function closeSound():void {            try {                _sound.close();            } catch (e:Error) {                // ignore            }            if(clip.live) {            	_sound = null;            }        }        private function resetState():void {            _paused = false;            _started = false;            _bufferFullDispatched = false;            _durationSeconds = 0;            _pausedPosition = 0;            if (_progressTimer) {                _progressTimer.stop();                _progressTimer.removeEventListener(TimerEvent.TIMER, onProgressTimer);                _progressTimer = null;            }        }        public function attachStream(video:DisplayObject):void {        }        private function doLoad():void {        }        public function load(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean = true):void {            log.debug("load()");            _metadataDispatched = false;            resetState();            if ((_prevClip == clip) && _sound) {                log.debug("load() reusing existing sound object");                addListeners(_sound);                play(0);                clip.dispatch(ClipEventType.BEGIN);                //#575 send the start event after begin                clip.dispatch(ClipEventType.START);            } else {                log.debug("load(), creating new sound object");                _prevClip = clip;                _sound = new Sound();                context = new SoundLoaderContext(1000, true);                //#582 clear any preloaded images                _imageDisplay = null;                if (clip.getCustomProperty("coverImage")) {                    var cover:Object = getCoverImage(clip);                    log.debug("Loading Artwork For Audio " + cover.url);                    _imageLoader.load(cover.url, onImageComplete);                } else {                    playAudio();                }            }            _pauseAfterStart = pauseAfterStart;        }        private function getCoverImage(clip:Clip):Object {            var cover:Object = clip.getCustomProperty("coverImage");            if (cover is String) return { url: "" + cover };            if (cover.hasOwnProperty("scaling")) {                clip.setScaling(cover["scaling"]);            }            return cover;        }        private function playAudio():void {            addListeners(_sound);            _clipUrlResolverHelper.resolveClipUrl(clip, function onClipUrlResolved(clip:Clip):void {                _sound.load(new URLRequest(clip.completeUrl), context);                play(0);            });        }        private function onImageError(error:IOErrorEvent):void {            log.debug("Cover artwork doesn't exist playing now");            playAudio();        }        private function onImageComplete(loader:ResourceLoader):void {            log.debug("Cover image loaded playing now");            _imageDisplay = loader.getContent() as Loader;            clip.originalWidth = _imageDisplay.width;            clip.originalHeight = _imageDisplay.height;            playAudio();        }        private function removeListeners(sound:Sound):void {            sound.removeEventListener(ProgressEvent.PROGRESS, onProgress);            sound.removeEventListener(Event.COMPLETE, onDownloadComplete);            sound.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);            sound.removeEventListener(Event.ID3, onId3);        }        private function addListeners(sound:Sound):void {            removeListeners(sound);            sound.addEventListener(ProgressEvent.PROGRESS, onProgress);            sound.addEventListener(Event.COMPLETE, onDownloadComplete);            sound.addEventListener(IOErrorEvent.IO_ERROR, onIoError);            sound.addEventListener(Event.ID3, onId3);            _progressTimer = new Timer(200);            _progressTimer.addEventListener(TimerEvent.TIMER, onProgressTimer);            _progressTimer.start();        }        private function onIoError(event:IOErrorEvent):void {            log.error("Unable to load audio file: " + event.text);            clip.dispatchError(ClipError.STREAM_NOT_FOUND);        }        private function addId3Metadata():void {            var metadata:Object = clip.metaData || new Object();            log.debug("current metadata", metadata);            try {                var tag:ID3Info = _sound.id3;            } catch (e:Error) {                log.warn("unable to access ID3 tag: " + e);            }            for (var prop:String in tag) {                log.debug(prop + ": " + _sound.id3[prop]);                metadata[prop] = _sound.id3[prop];            }            clip.metaData = metadata;        }        private function dispatchMetadata():void        {            if (_metadataDispatched) return;            clip.dispatch(ClipEventType.METADATA);            clip.dispatch(ClipEventType.START);            _started = true;            _metadataDispatched = true;        }        private function onId3(event:Event):void {            log.debug("onId3(), _started == " + _started);            addId3Metadata();            //#428 when fully downloaded ID3 is resent and update the duration            //#582 prevent dispatching for files with id1 tags at the end of their files            if (_started)  {                return;            }            //#475 if we have a clip duration set, dispatch start or else wait until the duration is estimated. Start required for beginning duration tracker.            //#501 fixes for start dispatching issue.            if (clip.duration > 0 && !_started) {                log.debug("duration is available dispatching start");                dispatchMetadata();            }            //#569 if the playlist has been reset but the audio has been already buffered, set the duration and start event.            if (clip.duration <= 0 && !_started && (_sound.bytesLoaded >= _sound.bytesTotal)) {                clip.durationFromMetadata = getDuration();                dispatchMetadata();            }            if (_pauseAfterStart) {                pause(new ClipEvent(ClipEventType.PAUSE));                //begin the progress timer to start buffering.                _progressTimer.start();            }        }        private function onProgress(event:ProgressEvent):void {            _sound.removeEventListener(ProgressEvent.PROGRESS, onProgress);            clip.dispatch(ClipEventType.BEGIN);        }        private function onProgressTimer(event:TimerEvent):void {            if (! clip.duration > 0) {                estimateDuration();            }            var bTotal:Number = _sound.bytesTotal;            var bLoaded:Number = _sound.bytesLoaded;            if (clip.live) bTotal = bLoaded + 1;                        if (! bTotal > 0) return;            if (! bLoaded > 0) return;            if (_sound.isBuffering == true && bTotal > bLoaded) {                clip.dispatch(ClipEventType.BUFFER_EMPTY);            } else if (! _bufferFullDispatched) {                clip.dispatch(ClipEventType.BUFFER_FULL);                _bufferFullDispatched = true;            }        }        private function getDuration():Number        {            return (_sound.length / (_sound.bytesLoaded / _sound.bytesTotal)) / 1000;        }        private function estimateDuration():void {        	if (clip.live) return;            //#428 regression issue calculating the initial duration, was returning too small for the duration tracker.            var durationSecs:Number = getDuration();            clip.durationFromMetadata = durationSecs;            if (durationSecs > 0 && Math.abs(_lastDurationDispatched - durationSecs) >= 0.5) {                if (clip.metaData) {                    clip.dispatch(ClipEventType.METADATA);                }                _lastDurationDispatched = durationSecs;                log.debug("dispatching onDuration(), " + clip.duration);                clip.dispatch(ClipEventType.START);                _started = true;            }        }        private function onDownloadComplete(event:Event):void {            log.debug("Audio is buffered dispatching metadata");            clip.durationFromMetadata = getDuration();            dispatchMetadata();        }        private function onComplete(event:Event):void {            //#501 stop the progress timer on completion.            _progressTimer.stop();            stopSoundChannel();            //#582 send the buffer full event here so playlist items will end and transition correctly.            clip.dispatchEvent(new ClipEvent(ClipEventType.BUFFER_FULL));            // dispatch a before event because the finish has default behavior that can be prevented by listeners            //clip.dispatchBeforeEvent(new ClipEvent(ClipEventType.FINISH));        }        public function getVideo(clip:Clip):DisplayObject {            log.debug("getVideo() " + _imageDisplay);            return _imageDisplay as DisplayObject;        }        public function resume(event:ClipEvent):void {            log.debug("resume");            _paused = false;            //start the progress timer            _progressTimer.start();            play(_pausedPosition);            if (event) {                clip.dispatchEvent(event);            }        }        public function pause(event:ClipEvent):void {            log.debug("pause");            if (clip.live) {           		stop(event);           		return;           	}           	            _paused = true;            _pausedPosition = _channel.position;            stopSoundChannel();            //pause the progress timer            _progressTimer.stop();            if (event) {                clip.dispatchEvent(event);            }        }        private function stopSoundChannel():void        {            _channel.stop();            //#501 clear the complete event before creating a new sound channel.            _channel.removeEventListener(Event.SOUND_COMPLETE, onComplete);        }        public function seek(event:ClipEvent, seconds:Number):void {            if (! _channel) return;            stopSoundChannel();            _seeking = true;            play(seconds * 1000);            if (event && clip) {                clip.dispatchEvent(event);            }            if (_paused) {                _pausedPosition = _channel.position;                _channel.stop();            }        }        private function play(posMillis:Number):void {            _channel = _sound.play(posMillis, 0);            //#501 use the sound channel for the completion event to finish correctly.            _channel.addEventListener(Event.SOUND_COMPLETE, onComplete);            _volumeController.soundChannel = _channel;        }        public function get stopping():Boolean {            return false;        }        public function get allowRandomSeek():Boolean {            return false;        }        public function get bufferStart():Number {            return 0;        }        public function get playlist():Playlist {            return _playlist;        }        public function get time():Number {            if (_timeProvider) {                return _timeProvider.getTime(null);            }            return _channel ? _channel.position / 1000 : 0;        }        public function get bufferEnd():Number {            return _sound && clip ? _sound.bytesLoaded / _sound.bytesTotal * clip.duration : 0;        }        public function get fileSize():Number {            return _sound ? _sound.bytesLoaded : 0;        }        public function set playlist(playlist:Playlist):void {            _playlist = playlist;        }        public function set netStreamClient(client:Object):void {        }        public function set volumeController(controller:VolumeController):void {            _volumeController = controller;        }        public function onConfig(model:PluginModel):void {            _model = model;            model.dispatchOnLoad();        }        public function getDefaultConfig():Object {            return null;        }        public function onLoad(player:Flowplayer):void {            _imageLoader = player.createLoader();            _clipUrlResolverHelper = new ClipURLResolverHelper(player, this);        }        public function addConnectionCallback(name:String, listener:Function):void {        }        public function addStreamCallback(name:String, listener:Function):void {        }        public function get netStream():NetStream {            return null;        }        public function get netConnection():NetConnection {            return null;        }        public function getDefaultConnectionProvider():ConnectionProvider {            return null;        }        public function set timeProvider(timeProvider:TimeProvider):void {            _timeProvider = timeProvider;        }        /**         * the value of this property is "audio"         */        public function get type():String {            return "audio";        }        public function switchStream(event:ClipEvent, clip:Clip, netStreamPlayOptions:Object = null):void {        }        public function get streamCallbacks():Dictionary {            return null;        }        private function get clip():Clip {            return _playlist.current;        }    }}