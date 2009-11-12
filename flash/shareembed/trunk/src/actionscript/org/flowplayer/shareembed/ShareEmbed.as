/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com> * Copyright (c) 2009 Electroteque Multimedia * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.shareembed {    import com.adobe.serialization.json.JSON;		import flash.display.Stage;    import flash.display.Sprite;    import flash.events.MouseEvent;    	import org.flowplayer.controller.ResourceLoader;    import org.flowplayer.model.ClipEvent;    import org.flowplayer.model.DisplayPluginModel;    import org.flowplayer.model.Plugin;    import org.flowplayer.model.PluginModel;    import org.flowplayer.view.FlowStyleSheet;    import org.flowplayer.view.Styleable;    import org.flowplayer.model.PlayerEvent;    import org.flowplayer.util.PropertyBinder;    import org.flowplayer.view.AbstractSprite;    import org.flowplayer.view.Flowplayer;        import org.flowplayer.util.URLUtil;        import org.flowplayer.shareembed.assets.EmailBtn;    import org.flowplayer.shareembed.assets.EmbedBtn;    import org.flowplayer.shareembed.assets.ShareBtn;    /**	 * A Subtitling and Captioning Plugin. Supports the following:	 * <ul>	 * <li>Loading subtitles from the Timed Text or Subrip format files.</li>	 * <li>Styling text from styles set in the Time Text format files.</li>	 * <li>Loading subtitles or cuepoints from a JSON config.</li>	 * <li>Loading subtitles or cuepoints from embedded FLV cuepoints.</li>	 * <li>Controls an external content plugin.</li>	 * <li>Working with the Javascript captions plugin, it enables a scrolling cuepoint thumbnail menu.</li>	 * </ul>	 * <p>	 * To setup an external subtitle caption file the config would look like so:	 * 	 * captionType: 'external'	 * 	 * For Timed Text	 *	 * captionUrl: 'timedtext.xml'	 * 	 * For Subrip	 * 	 * captionUrl: 'subrip.srt'	 * 	 * <p>	 * To enable the captioning to work properly a caption target must link to a content plugin like so:	 * 	 * captionTarget: 'content'	 * 	 * Where content is the config for a loaded content plugin.	 *	 * <p>	 * 	 * To be able to customised the subtitle text a template string is able to tell the captioning plugin	 * which text property is to be used for the subtitle text which is important for embedded cuepoints. It also	 * enables to add extra properties to the text like so:	 * 	 * template: '{text} {time} {custom}' 	 * 	 * <p>	 * To enable simple formatting of text if Timed Text has style settings, 	 * only "fontStyle", "fontWeight" and "textAlign" properties are able to be set like so:	 * 	 * simpleFormatting: true	 * 	 * @author danielr	 */	public class ShareEmbed extends AbstractSprite implements Plugin, Styleable {				private var _player:Flowplayer;		private var _model:PluginModel;		private var _config:Config;		private var _loader:ResourceLoader;				private var embedBtn:Sprite;		private var emailBtn:Sprite;		private var shareBtn:Sprite;		private var btnContainer:Sprite;				private var _embedView:EmbedView;		private var _emailView:EmailView;		private var _shareView:ShareView;				private var _stageWidth:int;		private var _stageHeight:int;				private var _stage:Stage;				/**		 * Sets the plugin model. This gets called before the plugin		 * has been added to the display list and before the player is set.		 * @param plugin		 */		public function onConfig(plugin:PluginModel):void {			_model = plugin;			_config = new PropertyBinder(new Config(), null).copyProperties(plugin.config) as Config;			}				override protected function onResize():void {	        }		public function onLoad(player:Flowplayer):void {			_player = player;						_player.playlist.onBegin(onBegin);			_player.playlist.onLastSecond(onBeforeFinish);			_loader = _player.createLoader();						btnContainer = new Sprite();			            emailBtn = new EmailBtn() as Sprite;            btnContainer.addChild(emailBtn);            emailBtn.y = 0;                        embedBtn = new EmbedBtn() as Sprite;            btnContainer.addChild(embedBtn);            embedBtn.y = emailBtn.y + emailBtn.height + 5;                              shareBtn = new ShareBtn() as Sprite;            btnContainer.addChild(shareBtn);            shareBtn.y = embedBtn.y + embedBtn.height + 5;                        _player.addToPanel(btnContainer, {right:0, top: 0, zIndex: 100, alpha: 0});                        emailBtn.addEventListener(MouseEvent.CLICK, onShowEmailPanel);			embedBtn.addEventListener(MouseEvent.CLICK, onShowEmbedPanel);			shareBtn.addEventListener(MouseEvent.CLICK, onShowSharePanel);									            _model.dispatchOnLoad();        }        				public function getDefaultConfig():Object {			//return {width: "80%"};			return {top: 0, left: 0, width: "100%", height: "80%"};		}				[External]		public function email():void		{			//if (!_emailView)			//{				_emailView = new EmailView(_model as DisplayPluginModel, _player, _config);	            _emailView.setSize(stage.width, stage.height);				_emailView.x = 0;				_emailView.y = 0;	            _emailView.style = createStyleSheet(null);	         	addChild(_emailView);			//} else {			//	log.debug("yes");				//_player.animationEngine.animate(_emailView, {alpha: 1}, 500);					//_player.animationEngine.fadeIn(_emailView, 500);			//}   		}				[External]        public function embed():void        {            //if (!_embedView)            //{	            _embedView = new EmbedView(_model as DisplayPluginModel, _player);	            _embedView.setSize(stage.width, stage.height);				_embedView.x = 0;				_embedView.y = 0;	            _embedView.style = createStyleSheet(null);	         	addChild(_embedView);	         	_embedView.html = getEmbedCode();          //  } else {            //	_player.animationEngine.fadeIn(_embedView, 500);            	//_player.animationEngine.animate(_embedView, {alpha: 1}, 500);            //}	        }                [External]        public function share():void        {        	//if (!_shareView)        	//{	        	_shareView = new ShareView(_model as DisplayPluginModel, _player, _config);	        	_shareView.embedCode = getEmbedCode();	            _shareView.setSize(stage.width, stage.height);				_shareView.x = 0;				_shareView.y = 0;	            _shareView.style = createStyleSheet(null);	         	addChild(_shareView);        	//} else {        	//	log.error("yes");        		//_shareView.alpha = 1;        		//_player.animationEngine.fadeIn(_shareView, 500);        		//_player.animationEngine.animate(_shareView, {alpha: 1}, 500);        	//}        }                               private function getEmbedCode():String        {   			        	var conf:Object = JSON.decode(stage.loaderInfo.parameters["config"]);			for (var plugin:String in conf.plugins)        	{        		var url:String = URLUtil.isCompleteURLWithProtocol(conf.plugins[plugin].url)         						? conf.plugins[plugin].url         						: conf.plugins[plugin].url.substring(conf.plugins[plugin].url.lastIndexOf("/") + 1,conf.plugins[plugin].url.length);        						        		conf.plugins[plugin].url = URLUtil.completeURL(_config.baseURL, url);        	}        	var playerSwf:String = URLUtil.completeURL(URLUtil.pageUrl, _player.config.playerSwfName);       		       		var configStr:String = JSON.encode(conf);        	        	var code:String =         	'<object id="' + _player.id + '" width="' + stage.width + '" height="' + stage.height +'" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"> ' + "\n" +			'	<param value="true" name="allowfullscreen"/>' + "\n" +			'	<param value="always" name="allowscriptaccess"/>' + "\n" +			'	<param value="high" name="quality"/>' + "\n" +			'	<param value="true" name="cachebusting"/>' + "\n" +			'	<param value="#000000" name="bgcolor"/>' +  "\n" +			'	<param name="movie" value="' + playerSwf + '" />' + "\n" +			'	<param value="config=' + configStr + '" name="flashvars"/>' + "\n" +			'	<embed src="' + playerSwf + '" type="application/x-shockwave-flash" width="' + stage.width + '" height="' + stage.height +'" allowfullscreen="true" allowscriptaccess="always" cachebusting="true" flashvars="config=' + configStr + '" bgcolor="#000000" quality="true"/>' + "\n" +			'</object>';			//code = code.replace(/\</g, "&lt;").replace(/\>/g, "&gt;"); 			return code;        }                private function createStyleSheet(cssText:String = null):FlowStyleSheet {						var styleSheet:FlowStyleSheet = new FlowStyleSheet("#content", cssText);			// all root style properties come in config root (backgroundImage, backgroundGradient, borderRadius etc)			addRules(styleSheet, _model.config);			// style rules for the textField come inside a style node			addRules(styleSheet, _model.config.style);			return styleSheet;		}				private function addRules(styleSheet:FlowStyleSheet, rules:Object):void {			var rootStyleProps:Object;			for (var styleName:String in rules) {				log.debug("adding additional style rule for " + styleName);				if (FlowStyleSheet.isRootStyleProperty(styleName)) {					if (! rootStyleProps) {						rootStyleProps = new Object();					}                    log.debug("setting root style property " + styleName + " to value " + rules[styleName]);					rootStyleProps[styleName] = rules[styleName];				} else {					styleSheet.setStyle(styleName, rules[styleName]);				}			}			styleSheet.addToRootStyle(rootStyleProps);		}				private function showButtonPanel():void		{				_player.animationEngine.animate(btnContainer,{alpha: 1}, 500);		}				private function hideButtonPanel():void		{				_player.animationEngine.animate(btnContainer,{alpha: 0}, 500);		}				private function onMouseOver(event:PlayerEvent):void        {        	showButtonPanel();        }                private function onMouseOut(event:PlayerEvent):void        {			hideButtonPanel();        }				private function onBegin(event:ClipEvent):void		{			hideButtonPanel();						_stageWidth = stage.width;			_stageHeight = stage.height;			_stage = stage;						_player.onMouseOver(onMouseOver);			_player.onMouseOut(onMouseOut);		}				private function onBeforeFinish(event:ClipEvent):void		{			showButtonPanel();		}				private function onShowEmailPanel(event:MouseEvent):void		{			email();		}				private function onShowEmbedPanel(event:MouseEvent):void		{			embed();		}				private function onShowSharePanel(event:MouseEvent):void		{			share();		}				[External]        public function show():void        {            showButtonPanel();        }				public function css(styleProps:Object = null):Object {			return {};		}				public function animate(styleProps:Object):Object {			return {};		}					}}