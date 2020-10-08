"use strict";

class DeezerBackground {
    constructor() {
        this.contentConnected = this.contentConnected.bind(this);
        this.onContentMessage = this.onContentMessage.bind(this);
        this.onBridgeMessage = this.onBridgeMessage.bind(this);
        this.onBridgeDisconnected = this.onBridgeDisconnected.bind(this);

        this.port = null;
        this.bridgePort = null;
        this.debug = false;

        console.log("MusiControl Deezer addon loaded.");
    }

    onContentMessage(m) {
        if (this.debug) {
            console.log("Up", m);
        }

        if (this.bridgePort) {
            this.bridgePort.postMessage(m);
        }
    }

    openTab() {
        let tab = this.port.sender.tab;
        let tabId = tab.id;
        let windowId = tab.windowId;

        browser.windows.update(windowId, { focused: true });
        browser.tabs.update(tabId, { active: true });
    }

    onBridgeMessage(m) {
        if (this.debug) {
            console.log("Down", m);
        }

        if ("type" in m && m["type"] === "open") {
            this.openTab();
        }

        this.send(m);
    }

    onBridgeDisconnected() {
        this.bridgePort = null;
        console.log("Disconnected from bridge");
        if (browser.runtime.lastError) {
            console.error("Got error on disconnect:", browser.runtime.lastError.message);
        }
    }

    contentConnected(p) {
        if (this.port) {
            this.port.disconnect();
        }
        this.port = p;
        this.startBridge();

        p.onMessage.addListener(this.onContentMessage);
    }

    startBridge() {
        if (this.bridgePort) {
            return;
        }

        console.log("Starting bridge...");
        try {
            this.bridgePort = browser.runtime.connectNative("com.xxmicloxx.musicontrol.bridge");
            this.bridgePort.onMessage.addListener(this.onBridgeMessage);
            this.bridgePort.onDisconnect.addListener(this.onBridgeDisconnected);
        } catch (e) {
            console.error("Could not load bridge:", e);
        }
    }

    start() {
        this.startBridge();

        browser.runtime.onConnect.addListener(this.contentConnected);
    }

    send(msg) {
        const port = this.port;
        if (!port) {
            return;
        }

        port.postMessage(msg);
    }
}

window.deezerBackground = new DeezerBackground();
window.deezerBackground.start();