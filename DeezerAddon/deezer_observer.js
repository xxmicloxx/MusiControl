"use strict";

const COULD_NOT_CONNECT = { error: "COULD_NOT_CONNECT" };
const COVER_PREFIX = "https://e-cdns-images.dzcdn.net/images/cover/";
const COVER_POSTFIX = "/200x200-000000-80-0-0.png";

class DeezerObserver {
    constructor(handshake) {
        this.handshake = handshake;
    }

    init() {
        this.updateTrackData = this.updateTrackData.bind(this);
        this.updatePosition = this.updatePosition.bind(this);
        this.updatePlayerState = this.updatePlayerState.bind(this);
        this.gotWindowMessage = this.gotWindowMessage.bind(this);

        window.addEventListener("message", this.gotWindowMessage, false);

        this.connect();
    }

    updateTrackData() {
        const track = window.dzPlayer.getCurrentSong();
        const position = window.dzPlayer.getPosition();

        let trackObj = null;
        if (track) {
            trackObj = {
                title: track["SNG_TITLE"],
                artist: track["ART_NAME"],
                album: track["ALB_TITLE"],
                cover: COVER_PREFIX + track["ALB_PICTURE"] + COVER_POSTFIX,
                duration: parseInt(track["DURATION"])
            };
        }

        this.send({
            type: "updateTrack",
            track: trackObj,
            position: position
        });
    }

    updatePosition(_event, position) {
        this.send({
            type: "updatePosition",
            position: position
        });
    }

    updatePlayerState() {
        this.send({
            type: "updatePlayerState",
            playerState: {
                shuffle: window.dzPlayer.shuffle,
                playing: window.dzPlayer.playing
            }
        });
    }

    openPlaylist() {
        let playlistButton = document.getElementsByClassName("queuelist")[0];
        if (!playlistButton.classList.contains("is-active")) {
            let evObj = document.createEvent('Events');
            evObj.initEvent('click', true, false);
            playlistButton.dispatchEvent(evObj);
        }
    }

    changeVolume(delta) {
        let vol = window.dzPlayer.volume;
        let dbVol = 20 * Math.log10(vol);

        let targetDelta = delta * 1;
        if (vol == 0) {
            dbVol = -60 + targetDelta;
        } else {
            dbVol += targetDelta;
        }
        dbVol = Math.min(dbVol, 0);

        let targetVol = Math.pow(10, dbVol / 20);
        if (dbVol <= -60) {
            targetVol = 0;
        }

        window.dzPlayer.control.setVolume(targetVol);
    }

    connect() {
        window.Events.subscribe(window.Events.player.position, this.updatePosition);
        window.Events.subscribe(window.Events.player.displayCurrentSong, this.updateTrackData);
        window.Events.subscribe(window.Events.player.shuffle_changed, this.updatePlayerState);
        window.Events.subscribe(window.Events.player.playing, this.updatePlayerState);

        this.updateTrackData();
    }

    canConnect() {
        return "dzPlayer" in window;
    }

    send(data) {
        window.postMessage({ handshake: this.handshake, direction: "up", data }, "*");
    }

    handleWindowMessage(data) {
        let type = data["type"];
        switch (type) {
        case "refresh":
            this.updateTrackData();
            this.updatePlayerState();
            break;

        case "togglePause":
            window.dzPlayer.control.togglePause();
            break;

        case "prev":
            window.dzPlayer.control.prevSong();
            break;

        case "next":
            window.dzPlayer.control.nextSong();
            break;

        case "toggleShuffle":
            window.dzPlayer.control.setShuffle(!window.dzPlayer.shuffle);
            break;

        case "open":
            this.openPlaylist();
            break;

        case "changeVolume":
            this.changeVolume(data["volumeChange"]);
            break;
        }
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
        if (dir != "down") {
            return;
        }
    
        if (!Object.prototype.hasOwnProperty.call(data, "data")) {
            return;
        }

        this.handleWindowMessage(data["data"]);
    }
}

(function() {
    const observer = new DeezerObserver("$HANDSHAKE$");

    // check if we have dzPlayer
    if (!observer.canConnect()) {
        // nope
        observer.send(COULD_NOT_CONNECT);
        return;
    }

    observer.init();
})();