package org.flowplayer.bitrateselect {

    import flash.net.NetStream;
    import flash.events.NetStatusEvent;

    import org.flowplayer.controller.ClipURLResolver;
    import org.flowplayer.controller.StreamProvider;
    import org.flowplayer.model.Clip;
    import org.flowplayer.model.ClipEvent;
    import org.flowplayer.model.Plugin;
    import org.flowplayer.model.PluginModel;
    import org.flowplayer.model.PlayerEvent;
    import org.flowplayer.util.PropertyBinder;
    import org.flowplayer.view.AbstractSprite;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.view.Styleable;
    import org.flowplayer.util.Arrange;

    import org.flowplayer.ui.containers.*;
    import org.flowplayer.ui.Dock;
    import org.flowplayer.ui.Notification;
    import org.flowplayer.ui.buttons.ToggleButton;
    import org.flowplayer.ui.buttons.ToggleButtonConfig;

    import org.flowplayer.net.BitrateItem;
    import org.flowplayer.net.StreamSelectionManager;
    import org.flowplayer.net.StreamSwitchManager;

    import fp.HDSymbol;

    import org.flowplayer.bitrateselect.ui.HDToggleController;
    import org.flowplayer.bitrateselect.event.HDEvent;
    import org.flowplayer.bitrateselect.config.Config;


    public class BitrateSelectProvider extends AbstractSprite implements ClipURLResolver, Plugin, Styleable {
        private var _config:Config;
        private var _model:PluginModel;
        private var _hdButton:ToggleButton;
        private var _hasHdButton:Boolean;
        private var _hdEnabled:Boolean = false;
        private var _player:Flowplayer;
        private var _iconDock:Dock;
        private var _provider:StreamProvider;
        private var _resolveSuccessListener:Function;
        private var _resolving:Boolean;
        private var _netStream:NetStream;
        private var _clip:Clip;
        private var _start:Number = 0;
        private var _failureListener:Function;
        private var _bitrateResource:HDBitrateResource;
        private var _streamSelectionManager:StreamSelectionManager;
        private var _streamSwitchManager:StreamSwitchManager;
        
        public function onConfig(model:PluginModel):void {
            _model = model;
            _config = new PropertyBinder(new Config(), null).copyProperties(model.config) as Config;
        }

        private function applyForClip(clip:Clip):Boolean {
            log.debug("applyForClip(), clip.urlResolvers == " + clip.urlResolvers);
            if (clip.urlResolvers == null) return false;
            var apply:Boolean = clip.urlResolvers.indexOf(_model.name) >= 0;
            log.debug("applyForClip? " + apply);
            return apply;
        }
    
        public function onLoad(player:Flowplayer):void {
            log.info("onLoad()");

            _player = player;

            _player.playlist.onStart(function(event:ClipEvent):void {
                log.debug("onBegin()");
                log.debug("hd available? " + hasHD);
                dispatchEvent(new HDEvent(HDEvent.HD_AVAILABILITY, hasHD));
            });

            if (_config.hdButton.docked) {
                _hasHdButton = true;
                createIconDock();	// we need to create the controller pretty early else it won't receive the HD_AVAILABILITY event
                _player.onLoad(onPlayerLoad);
            }

            if (_config.hdButton.controls) {
                _hasHdButton = true;
                var controlbar:* = player.pluginRegistry.plugins['controls'];
                controlbar.pluginObject.addEventListener(WidgetContainerEvent.CONTAINER_READY, addHDButton);
            }

            _model.dispatchOnLoad();
        }

        private function onPlayerLoad(event:PlayerEvent):void {
            log.debug("onPlayerLoad() ");
            _iconDock.addToPanel();
        }

        private function addHDButton(event:WidgetContainerEvent):void {
            var container:WidgetContainer = event.container;
            var controller:HDToggleController = new HDToggleController(false, this);
            container.addWidget(controller, "volume", false);
        }

        private function createIconDock():void {
            if (_iconDock) return;
            _iconDock = Dock.getInstance(_player);
            var controller:HDToggleController = new HDToggleController(true, this);

            // dock should do that, v3.2.7 maybe :)
            _hdButton = controller.init(_player, _iconDock, new ToggleButtonConfig(_config.iconConfig, _config.iconConfig)) as ToggleButton;
            _iconDock.addIcon(_hdButton);
            _iconDock.addToPanel();
        }

        public function get hasHD():Boolean {
            return (_player.playlist.current.getCustomProperty("hdBitrateItem") && _player.playlist.current.getCustomProperty("sdBitrateItem"));
        }

        public function set hd(enable:Boolean):void {
            if (! hasHD) return;
            log.info("set HD, switching to " + (enable ? "HD" : "normal"));

            var newItem:BitrateItem = _player.playlist.current.getCustomProperty(enable ? "hdBitrateItem" : "sdBitrateItem") as BitrateItem;
            _streamSwitchManager.switchStream(newItem);


            setHDNotification(enable);
        }

        private function setHDNotification(enable:Boolean):void {
            _hdEnabled = enable;
            if (_config.hdButton.splash) {
                displayHDNotification(enable);
            }
            dispatchEvent(new HDEvent(HDEvent.HD_SWITCHED, _hdEnabled));
        }

        private function displayHDNotification(enable:Boolean):void {
            var symbol:HDSymbol = new HDSymbol();
            symbol.hdText.text = enable ? _config.hdButton.onLabel : _config.hdButton.offLabel;
            symbol.hdText.width = symbol.hdText.textWidth + 26;
            Arrange.center(symbol.hdText, symbol.width);
            Arrange.center(symbol.hdSymbol, symbol.width);
            var notification:Notification = Notification.createDisplayObjectNotification(_player, symbol);
            notification.show(_config.hdButton.splash).autoHide(1200);
        }

        private function alreadyResolved(clip:Clip):Boolean {
            return clip.getCustomProperty("bwcheckResolvedUrl") != null;
        }

        public function resolve(provider:StreamProvider, clip:Clip, successListener:Function):void {
            //log.debug("resolve " + clip);

            if (!clip.getCustomProperty("bitrates") && !clip.getCustomProperty("dynamicStreamingItems")) {
                log.debug("Bitrates configuration not enabled for this clip");
                successListener(clip);
                return;
            }

            if (alreadyResolved(clip)) {
                log.debug("resolve(): bandwidth already resolved for clip " + clip + ", will not detect again");
                successListener(clip);
                return;
            }


            _provider = provider;
            _resolving = true;
            _resolveSuccessListener = successListener;

            init(provider.netStream, clip);
        }

        private function init(netStream:NetStream, clip:Clip):void {
            log.debug("init(), netStream == " + netStream);

            _netStream = netStream;
            _clip = clip;
            _start = netStream ? netStream.time : 0;
            _bitrateResource = new HDBitrateResource();

            _streamSelectionManager = new StreamSelectionManager(_bitrateResource.addBitratesToClip(clip));
            _streamSwitchManager = new StreamSwitchManager(netStream, _streamSelectionManager, _provider, _player, this);

            var mappedBitrate:BitrateItem = _streamSelectionManager.getMappedBitrate(-1);

            _streamSwitchManager.changeStreamNames(mappedBitrate);

            _resolveSuccessListener(_clip);

            toggleDefaultToHD(mappedBitrate);
        }

        private function toggleDefaultToHD(mappedBitrate:BitrateItem):void {
            if (mappedBitrate.isDefault) toggleToHD(mappedBitrate);
        }

        private function toggleToHD(mappedBitrate:BitrateItem):void {
            if (mappedBitrate.hd) setHDNotification(true);
        }

        public function set onFailure(listener:Function):void {
            _failureListener = listener;
        }

        public function handeNetStatusEvent(event:NetStatusEvent):Boolean {
            return true;
        }

        public function get hd():Boolean {
            return _hdEnabled;
        }

        public function getDefaultConfig():Object {
            return {
                top: "45%",
                left: "50%",
                opacity: 1,
                borderRadius: 15,
                border: 'none',
                width: "80%",
                height: "80%"
            };
        }

        public function css(styleProps:Object = null):Object {
            return {};
        }

        public function animate(styleProps:Object):Object {
            return {};
        }

        public function onBeforeCss(styleProps:Object = null):void {
            _iconDock.cancelAnimation();
        }

        public function onBeforeAnimate(styleProps:Object):void {
            _iconDock.cancelAnimation();
        }
        
    }
}