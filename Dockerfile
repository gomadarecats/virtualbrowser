FROM alpine:latest as build

RUN apk update && \
    apk add --no-cache -U \
            curl \
            git

RUN mkdir /build && \
    cd /build/ && \
    git clone https://github.com/novnc/noVNC && \
    cd /build/noVNC/utils/ && \
    git clone https://github.com/novnc/websockify

RUN curl -O https://moji.or.jp/wp-content/ipafont/IPAfont/IPAfont00303.zip && \
    unzip IPAfont00303.zip -d /build/

RUN echo -ne '#!/bin/bash\n \
     if [ "${REQ}" == "" ]; then\n \
       REQ="google.com";\n \
     fi\n \
     mkdir ~/.fluxbox\n \
     echo 'session.screen0.toolbar.visible: false' >> ~/.fluxbox/init\n \
     mkdir ~/.fonts\n \
     mv ~/build/IPAfont00303/ ~/.fonts/IPAfont00303/\n \
     fc-cache -fv\n \
     ((timeout 1 firefox -headless; exit 0))\n \
     pref=`find ~/.mozilla/firefox/ -iname "*.default-default"`\n \
     echo -ne '\''\n \
     user_pref("font.language.group", "ja");\n \
     user_pref("font.name.monospace.ja", "IPAPGothic");\n \
     user_pref("font.name.sans-serif.ja", "IPAPGothic");\n \
     user_pref("font.name.serif.ja", "IPAMincho");\n \
     user_pref("general.autoScroll", true);\n \
     user_pref("general.smoothScroll", false);'\'' >> $pref/prefs.js\n \
     ~/build/noVNC/utils/novnc_proxy\n \
     Xvfb :1 -screen 0 1920x920x24 &\n \
     fluxbox &\n \
     /usr/bin/ibus-daemon -dr\n \
     dconf load / < ~/build/dconf\n \
     firefox --kiosk $REQ &\n \
     x11vnc -display :1' \
    > /build/exec.sh && \
    chmod 755 /build/exec.sh

COPY ibus.dconf /build/dconf

#----------

FROM alpine:latest as browser

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache -U \
            bash \
            dbus-x11 \
            ffmpeg \
            firefox \
            fluxbox \
            fontconfig \
            gst-plugins-good \
            ibus-anthy \
            py3-numpy \
            python3 \
            x11vnc \
            xvfb

RUN adduser --disabled-password user

USER user

COPY --from=build --chown=user:user /build/ /home/user/build

CMD ~/build/exec.sh

ENV DISPLAY=:1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    XMODIFIERS=@im=ibus \
    GTK_IM_MODULE=ibus \
    QT_IM_MODULE=ibus

EXPOSE 6080
