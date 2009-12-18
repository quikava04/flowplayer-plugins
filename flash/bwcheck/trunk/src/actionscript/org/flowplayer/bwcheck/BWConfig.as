/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com>, Anssi Piirainen Flowplayer Oy * Copyright (c) 2009 Electroteque Multimedia, Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.bwcheck {		import flash.system.Capabilities;	import org.flowplayer.cluster.ClusterConfig;		public class BWConfig extends ClusterConfig {				private var _bitrates:Array;        private var _aliases:Array;		private var _urlPattern:String = "{0}-{1}.{2}";		private var _urlPatternNoExt:String = "{0}-{1}";        private var _urlExtension:String;		private var _defaultBitrate:Number;		private var _closestRateInterval:int = 0;		private var _rememberBitrate:Boolean = true;		private var _switchCurrentPosition:Boolean = false;		private var _bitrateProfileName:String = "bitrateProfile";        private var _preferredBufferLength:Number = 8;        private var _switchQOSTimerDivision:Number = 2.5;        private var _switchLiveQOSTimerDivision:Number = 5;        private var _switchQOSTimerDelay:Number = _preferredBufferLength / _switchQOSTimerDivision;        private var _startBufferLength:Number = 2;        private var _emptyBufferLength:Number = 1;        private var _aggressiveModeBufferDivision:Number = 2;        private var _aggressiveModeBufferLength:Number = _preferredBufferLength / _aggressiveModeBufferDivision;        private var _liveStream:Boolean = false;        private var _droppedFramesLockRate:int = int.MAX_VALUE; // rate that drops frames in excess of 25%        private var _droppedFramesLockLimit:uint = 3; // limit before that stream is locked permanently due to dropped frames        private var _monitorQOSTimerDelay:Number = 0.150;        private var _droppedFramesTimerDelay:uint = 300;        private var _liveErrorCorrectionLimit:int = 2;                private var _dynamic:Boolean = false;        private var _smilResolver:String = "smil";        private var _cacheExpiry:Number = 24 * 60 * 60;				public function setBitrates(bitrates:Object):void {            var rates:Array;            if (bitrates is Array) {                rates = bitrates.concat();                rates.sort(Array.NUMERIC);            } else {                rates = [];                for (var alias:String in bitrates) {                    rates.push(bitrates[alias]);                }                rates.sort(Array.NUMERIC);                _aliases = [];                // fill the aliases based on the sorted rates                for (var i:int = 0; i < rates.length; i++) {                    _aliases.push(findAlias(bitrates, rates[i] as Number));                }            }            _bitrates = rates;        }        private function findAlias(bitrates:Object, bitrate:Number):String {            for (var alias:String in bitrates) {                if (bitrates[alias] == bitrate) return alias;            }            // should not go here            return null;        }				public function get bitrates():Array		{			return _bitrates;		}				public function set urlPattern(value:String):void		{			_urlPattern = value;		}				public function get urlPattern():String		{			return _urlPattern;		}				public function set urlPatternNoExt(value:String):void		{			_urlPatternNoExt = value;		}				public function get urlPatternNoExt():String		{			return _urlPatternNoExt;		}				public function get defaultBitrate():Number {			return _defaultBitrate;		}				public function set defaultBitrate(defaultBitrate:Number):void {			_defaultBitrate = defaultBitrate;		}				public function get closestRateInterval():int {			return _closestRateInterval;		}				public function set closestRateInterval(closestRateInterval:int):void {			_closestRateInterval = closestRateInterval;		}				public function set rememberBitrate(value:Boolean):void		{			_rememberBitrate = value;		}				public function get rememberBitrate():Boolean		{			return _rememberBitrate;		}				public function set switchCurrentPosition(value:Boolean):void		{			_switchCurrentPosition = value;		}				public function get switchCurrentPosition():Boolean		{			return _switchCurrentPosition;		}				public function set enableDynamic(value:Boolean):void		{			_dynamic = value;		}				public function get enableDynamic():Boolean		{			return Capabilities.version.split(' ')[1].split(",")[0] >= 10 && _dynamic;		}				public function set bitrateProfileName(value:String):void		{			_bitrateProfileName = value;		}				public function get bitrateProfileName():String		{			return _bitrateProfileName;		}						/**	 	 * Set a preferred optimal buffer length for the stream to run smoothly, giving enough	 	 * buffer to switch under low bandwidth conditions	 	 * 	 	 */		public function set preferredBufferLength(length: Number):void {			_preferredBufferLength = length;			if(_liveStream) {				_switchQOSTimerDelay = Math.max(_preferredBufferLength/_switchLiveQOSTimerDivision, 1);   //live case server fills only x times the buffer, so need to check more often				//_curBufferTime = _preferredBufferLength; //in live case we dont go between various types of buffer lengths, so set this here.				//this.bufferTime = _curBufferTime;				_aggressiveModeBufferLength = _preferredBufferLength/_aggressiveModeBufferDivision;				}			else				_switchQOSTimerDelay = Math.max(_preferredBufferLength/_switchQOSTimerDivision, 1); //vod case server fills 2x the buffer		}				public function get preferredBufferLength():Number {			return _preferredBufferLength;		}				public function set liveStream(value : Boolean):void {			_liveStream = value;		}				public function get liveStream():Boolean {			return _liveStream;		}				public function set switchQOSTimerDelay(length : Number):void {			_switchQOSTimerDelay = length;		}				public function get switchQOSTimerDelay():Number {			return _switchQOSTimerDelay;		}				public function set aggressiveModeBufferLength(length: Number):void {			_aggressiveModeBufferLength = length;					}				public function get aggressiveModeBufferLength():Number {			return _aggressiveModeBufferLength;		}				public function set startBufferLength(length : Number):void {			_startBufferLength = length;		}				public function get startBufferLength():Number {			return _startBufferLength;		}				public function set emptyBufferLength(length : Number):void {			_emptyBufferLength = length;		}				public function get emptyBufferLength():Number {			return _emptyBufferLength;		}				public function get droppedFramesLockRate():int {			return _droppedFramesLockRate;		}				public function get droppedFramesLockLimit():uint {			return _droppedFramesLockLimit;		}				public function set monitorQOSTimerDelay(value : Number):void {			_monitorQOSTimerDelay = value;		}				public function get monitorQOSTimerDelay():Number {			return _monitorQOSTimerDelay;		}				public function set droppedFramesTimerDelay(value : Number):void {			_droppedFramesTimerDelay = value;		}				public function get droppedFramesTimerDelay():Number {			return _droppedFramesTimerDelay;		}				public function set liveErrorCorrectionLimit(value : Number):void {			_liveErrorCorrectionLimit = value;		}				public function get liveErrorCorrectionLimit():Number {			return _liveErrorCorrectionLimit;		}        public function get smilResolver():String {            return _smilResolver;        }        public function set smilResolver(value:String):void {            _smilResolver = value;        }        public function get urlExtension():String {            return _urlExtension;        }        public function set urlExtension(value:String):void {            _urlExtension = value;        }        public function getAlias(bitrate:Number):String {            if (! _aliases) return bitrate.toString();            return _aliases[_bitrates.indexOf(bitrate)];        }        public function get cacheExpiry():Number {            return _cacheExpiry;        }        public function set cacheExpiry(value:Number):void {            _cacheExpiry = value;        }    }}