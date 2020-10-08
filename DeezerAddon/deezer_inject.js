"use strict";

class DeezerInjector {

    constructor() {
        this.gotWindowMessage = this.gotWindowMessage.bind(this);
        this.gotBackgroundMessage = this.gotBackgroundMessage.bind(this);

        this.handshake = this.generateHandshake();
        this.connection = browser.runtime.connect();
        this.connection.onMessage.addListener(this.gotBackgroundMessage);

        window.addEventListener("message", this.gotWindowMessage, false);
    }

    generateHandshake() {
        const array = new Uint32Array(5);
        return window.crypto.getRandomValues(array).toString();
    }

    loadScript() {
        const thiz = this;

        function loaded() {
            console.log("Injecting Handshake...");
            let script = this.responseText;
            script = script.replace(/\$HANDSHAKE\$/g, thiz.handshake);
        
            const s = document.createElement('script');
            const body = document.createTextNode(script);
            s.appendChild(body);
            (document.head||document.documentElement).appendChild(s);
            s.onload = function() { "use strict"; s.parentNode.removeChild(s); };
            console.log("...injected successfully.");
        }

        const oReq = new XMLHttpRequest();
        oReq.addEventListener("load", loaded);
        oReq.open("GET", chrome.extension.getURL('deezer_observer.js'));
        oReq.send();
    }

    gotBackgroundMessage(m) {
        window.postMessage({ handshake: this.handshake, direction: "down", data: m });
    }

    gotWindowMessage({data}) {
        if (!Object.prototype.hasOwnProperty.call(data, "handshake")) {
            return;
        }
    
        const sentShake = data["handshake"];
        if (sentShake !== this.handshake) {
            console.warn("Received wrong handshake " + sentShake);
            return;
        }

        if (!Object.prototype.hasOwnProperty.call(data, "direction")) {
            return;
        }

        const dir = data["direction"];
        if (dir != "up") {
            return;
        }
    
        if (!Object.prototype.hasOwnProperty.call(data, "data")) {
            return;
        }

        this.connection.postMessage(data["data"]);
    }
}

function bootstrap() {
    if (document.readyState !== "complete") {
        return;
    }

    const injector = new DeezerInjector();
    injector.loadScript();
}

document.addEventListener("readystatechange", bootstrap);
bootstrap();