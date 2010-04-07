/* * This file is part of Flowplayer, http://flowplayer.org * * By: Anssi Piirainen, <support@flowplayer.org> * Copyright (c) 2008, 2009 Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */ package org.flowplayer {	import flash.text.TextFieldAutoSize;		import flash.text.AntiAliasType;	import flash.text.TextField;	import flash.text.TextFormat;		import org.flowplayer.model.Plugin;	import org.flowplayer.model.PluginModel;	import org.flowplayer.util.Arrange;	import org.flowplayer.view.Flowplayer;	import org.flowplayer.view.StyleableSprite;		public class HelloWorld extends StyleableSprite implements Plugin {		private var _text:TextField;		private var _model:PluginModel;				public function HelloWorld() {			_text = new TextField();			var format:TextFormat = new TextFormat();			format.font = "Trebuchet MS, Lucida Grande, Lucida Sans Unicode, Bitstream Vera, Verdana, Arial, _sans, _serif";			format.size = 20;			format.bold = true;			_text.defaultTextFormat = format;			_text.antiAliasType = AntiAliasType.ADVANCED;			_text.height = 20;			_text.autoSize = TextFieldAutoSize.CENTER;			_text.text = "Hello World!";			addChild(_text);		}				/**		 * Arranges the child display objects. Called by superclass when the size of this sprite changes.         * This should be the only place where you resize and position the child display objects. 		 */		override protected function onResize():void {			super.onResize();			Arrange.center(_text, width, height);					}				/**		 * Gets the default configuration for this plugin. We can include display properties and CSS properties		 * understood by this plugin. The CSS properties are handled by our StyleableSprite superclass.		 */		public function getDefaultConfig():Object {			return { top: "70%", left: '50%', width: '40%', height: 50, backgroundColor: '#F89C4A', opacity: 0.9, borderRadius: 30, backgroundGradient: 'high' };		}				/**		 * Sets a new text to the text field. This function is annotated with the "External" annotation		 * so that it can be called from JavaScript like this:		 * <code>		 *  $f().getPlugin("helloworld").setText("hello again!");		 * </code>		 */		 [External]		 public function set text(newText:String):void {		 	_text.text = newText;		}				/**		 * @inheritDoc		 */		public function onConfig(model:PluginModel):void {			// setting rootStyle causes the superclass to draw the packground			// rootStyle properties can be defined in our config object, so we'll use that as the rootStyle object			rootStyle = model.config;			_model = model;		}				/**		 * @inheritDoc		 */		public function onLoad(player:Flowplayer):void {			// dispatch onLoad so that the player knows this plugin is initialized			_model.dispatchOnLoad();		}	}}