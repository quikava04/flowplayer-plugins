/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com> * Copyright (c) 2008 Electroteque Multimedia * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.bwcheck {			public class BWConfig {				private var _bwHosts:Array = new Array();				private var _bitrates:Array;				private var _serverType:String = "red5";				private var _fileNameString:String = "{0}-{1}.{2}";				private var _netBWConnectionUrl:String;				private var _defaultBitrate:String;				private var _closestRateInterval:int = 0;				private var _rememberBitrate:Boolean = true;				private var _switchCurrentPosition:Boolean = false;						public function get netBWConnectionUrl():String {			return _netBWConnectionUrl;		}				public function set netBWConnectionUrl(netBWConnectionUrl:String):void {			_netBWConnectionUrl = netBWConnectionUrl;		}				public function set bitrates(bitrates:Array):void		{			_bitrates = bitrates;		}				public function get bitrates():Array		{			return _bitrates;		}				public function set fileNameString(value:String):void		{			_fileNameString = value;		}				public function get fileNameString():String		{			return _fileNameString;		}				public function get defaultBitrate():String {			return _defaultBitrate;		}				public function set defaultBitrate(defaultBitrate:String):void {			_defaultBitrate = defaultBitrate;		}				public function get closestRateInterval():int {			return _closestRateInterval;		}				public function set closestRateInterval(closestRateInterval:int):void {			_closestRateInterval = closestRateInterval;		}				public function set bwHosts(bwHosts:Array):void		{			_bwHosts = bwHosts;		}				public function get bwHosts():Array		{			return _bwHosts;		}				public function set rememberBitrate(value:Boolean):void		{			_rememberBitrate = value;		}				public function get rememberBitrate():Boolean		{			return _rememberBitrate;		}				public function set switchCurrentPosition(value:Boolean):void		{			_switchCurrentPosition = value;		}				public function get switchCurrentPosition():Boolean		{			return _switchCurrentPosition;		}				public function set serverType(value:String):void		{			_serverType = value;		}				public function get serverType():String		{			return _serverType;		}	}}