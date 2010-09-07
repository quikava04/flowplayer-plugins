/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com>, Anssi Piirainen Flowplayer Oy * Copyright (c) 2009 Electroteque Multimedia, Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.bwcheck {    import flash.system.Capabilities;    import org.flowplayer.model.DisplayProperties;    import org.flowplayer.model.DisplayPropertiesImpl;    import org.flowplayer.util.PropertyBinder;    import org.flowplayer.ui.AutoHideConfig;    import org.flowplayer.ui.ButtonConfig;    import org.flowplayer.cluster.ClusterConfig;    import org.flowplayer.bwcheck.BitrateItem;    public class Config extends ClusterConfig {        private var _streamSelectionStrategy:String = "default";        private var _streamSelectionFullScreen:Boolean = true;        private var _maxWidth:Number = -1;        private var _rememberBitrate:Boolean = false;        private var _bitrateProfileName:String = "bitrateProfile";        private var _dynamicBuffer:Boolean = false;        private var _dynamic:Boolean = false;        private var _cacheExpiry:Number = 24 * 60 * 60;        private var _autoHide:AutoHideConfig;        private var _iconDisplayProperties:DisplayProperties;        private var _iconButtons:ButtonConfig;        private var _buttonConfig:ButtonConfig;        private var _preferredBufferLength:Number = 8;        private var _switchQOSTimerDivision:Number = 2.5;        private var _switchLiveQOSTimerDivision:Number = 5;        private var _switchQOSTimerDelay:Number = _preferredBufferLength / _switchQOSTimerDivision;        private var _startBufferLength:Number = 8;        private var _emptyBufferLength:Number = 8;        private var _fullBufferLength:Number = 30;        private var _aggressiveModeBufferDivision:Number = 2;        private var _aggressiveModeBufferLength:Number = _preferredBufferLength / _aggressiveModeBufferDivision;        private var _liveStream:Boolean = false;        private var _droppedFramesLockRate:int = int.MAX_VALUE; // rate that drops frames in excess of 25%        private var _droppedFramesLockLimit:uint = 3; // limit before that stream is locked permanently due to dropped frames        private var _monitorQOSTimerDelay:Number = 0.150;        private var _droppedFramesTimerDelay:uint = 300;        private var _liveErrorCorrectionLimit:int = 2;        private var _checkOnStart:Object = null;        public function Config() {            _autoHide = new AutoHideConfig();            _autoHide.fullscreenOnly = false;            _autoHide.hideStyle = "fade";            _autoHide.delay = 2000;            _autoHide.duration = 1000;        }        public function set streamSelectionStrategy(value:String):void {            _streamSelectionStrategy = value;        }        public function get streamSelectionStrategy():String {            return _streamSelectionStrategy;        }        public function set streamSelectionFullScreen(value:Boolean):void {            _streamSelectionFullScreen = value;        }        public function get streamSelectionFullScreen():Boolean {            return _streamSelectionFullScreen;        }        public function get maxWidth():Number {            return _maxWidth;        }        public function set maxWidth(width:Number):void {            _maxWidth = width;        }        public function set rememberBitrate(value:Boolean):void {            _rememberBitrate = value;        }        public function get rememberBitrate():Boolean {            return _rememberBitrate;        }        public function set dynamic(value:Boolean):void {            _dynamic = value;        }        public function get dynamic():Boolean {            return Capabilities.version.split(' ')[1].split(",")[0] >= 10 && _dynamic;        }        public function set bitrateProfileName(value:String):void {            _bitrateProfileName = value;        }        public function get bitrateProfileName():String {            return _bitrateProfileName;        }        public function set dynamicBuffer(value:Boolean):void {            _dynamicBuffer = value;        }        public function get dynamicBuffer():Boolean {            return _dynamicBuffer;        }        public function get cacheExpiry():Number {            return _cacheExpiry;        }        public function set cacheExpiry(value:Number):void {            _cacheExpiry = value;        }        public function get buttons():ButtonConfig {            if (! _buttonConfig) {                _buttonConfig = new ButtonConfig();                _buttonConfig.setColor("rgba(140,142,140,1)");                _buttonConfig.setOverColor("rgba(140,142,140,1)");                _buttonConfig.setFontColor("rgb(255,255,255)")            }            return _buttonConfig;        }        public function setButtons(config:Object):void {            new PropertyBinder(buttons).copyProperties(config);        }        public function get iconButtons():ButtonConfig {            if (! _iconButtons) {                _iconButtons = new ButtonConfig();                _iconButtons.setColor("rgba(20,20,20,0.5)");                _iconButtons.setOverColor("rgba(0,0,0,1)");            }            return _iconButtons;        }        public function set icons(config:Object):void {            new PropertyBinder(iconButtons).copyProperties(config);        }        public function get iconDisplayProperties():DisplayProperties {            if (! _iconDisplayProperties) {                _iconDisplayProperties = new DisplayPropertiesImpl(null, "bwcheck-icons", false);                _iconDisplayProperties.top = "20%";                _iconDisplayProperties.right = "7%";                _iconDisplayProperties.width = "10%";                _iconDisplayProperties.height = "30%";            }            return _iconDisplayProperties;        }        public function get autoHide():AutoHideConfig {            return _autoHide;        }        public function setAutoHide(value:Object):void {            if (value is String) {                _autoHide.state = value as String;                return;            }            if (value is Boolean) {                _autoHide.enabled = value as Boolean;                _autoHide.fullscreenOnly = Boolean(! value);                return;            }            new PropertyBinder(_autoHide).copyProperties(value);        }        /**         * Configs for quality of service monitoring         */        /**         * Set a preferred optimal buffer length for the stream to run smoothly, giving enough         * buffer to switch under low bandwidth conditions         *         */        public function set preferredBufferLength(length:Number):void {            _preferredBufferLength = length;            if (_liveStream) {                _switchQOSTimerDelay = Math.max(_preferredBufferLength / _switchLiveQOSTimerDivision, 1);   //live case server fills only x times the buffer, so need to check more often                //_curBufferTime = _preferredBufferLength; //in live case we dont go between various types of buffer lengths, so set this here.                //this.bufferTime = _curBufferTime;                _aggressiveModeBufferLength = _preferredBufferLength / _aggressiveModeBufferDivision;            }            else                _switchQOSTimerDelay = Math.max(_preferredBufferLength / _switchQOSTimerDivision, 1); //vod case server fills 2x the buffer        }        public function get preferredBufferLength():Number {            return _preferredBufferLength;        }        public function set liveStream(value:Boolean):void {            _liveStream = value;        }        public function get liveStream():Boolean {            return _liveStream;        }        public function set switchQOSTimerDelay(length:Number):void {            _switchQOSTimerDelay = length;        }        public function get switchQOSTimerDelay():Number {            return _switchQOSTimerDelay;        }        public function set aggressiveModeBufferLength(length:Number):void {            _aggressiveModeBufferLength = length;        }        public function get aggressiveModeBufferLength():Number {            return _aggressiveModeBufferLength;        }        public function set startBufferLength(length:Number):void {            _startBufferLength = length;        }        public function get startBufferLength():Number {            return _startBufferLength;        }        public function set emptyBufferLength(length:Number):void {            _emptyBufferLength = length;        }        public function get emptyBufferLength():Number {            return _emptyBufferLength;        }        public function set fullBufferLength(length:Number):void {            _fullBufferLength = length;        }        public function get fullBufferLength():Number {            return _fullBufferLength;        }        public function get droppedFramesLockRate():int {            return _droppedFramesLockRate;        }        public function get droppedFramesLockLimit():uint {            return _droppedFramesLockLimit;        }        public function set monitorQOSTimerDelay(value:Number):void {            _monitorQOSTimerDelay = value;        }        public function get monitorQOSTimerDelay():Number {            return _monitorQOSTimerDelay;        }        public function set droppedFramesTimerDelay(value:Number):void {            _droppedFramesTimerDelay = value;        }        public function get droppedFramesTimerDelay():Number {            return _droppedFramesTimerDelay;        }        public function set liveErrorCorrectionLimit(value:Number):void {            _liveErrorCorrectionLimit = value;        }        public function get liveErrorCorrectionLimit():Number {            return _liveErrorCorrectionLimit;        }        public function get checkOnStart():Boolean {            if (_checkOnStart != null) return _checkOnStart as Boolean;            return ! dynamic;        }        public function set checkOnStart(value:Boolean):void {            _checkOnStart = value;        }    }}