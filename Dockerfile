FROM alpine:latest as build

RUN apk add --no-cache -U \
            git \
            curl

RUN git clone git://github.com/novnc/noVNC /build/noVNC && \
    git clone https://github.com/novnc/websockify /build/noVNC/utils/websockify && \
    sed -ie 's/python\s/python3 /g' /build/noVNC/utils/websockify/run

RUN curl -O https://ipafont.ipa.go.jp/IPAfont/IPAfont00303.zip && \
    unzip IPAfont00303.zip -d /build/

RUN echo -ne '\
    \#!/bin/bash\n\
    if [ "${REQ}" == "" ]; then\n\
      REQ="google.com";\n\
    fi \n\
    mkdir ~/.fluxbox \n\
    echo 'session.screen0.toolbar.visible: false' >> ~/.fluxbox/init \n\
    mkdir ~/.fonts \n\
    mv ~/build/IPAfont00303/ ~/.fonts/IPAfont00303/ \n\
    fc-cache -fv \n\
    ((timeout 1 firefox -headless; exit 0)) \n\
    pref=`find ~/.mozilla/firefox/ -iname "*.default-default"` \n\
    ~/build/noVNC/utils/launch.sh \n\
    Xvfb :1 -screen 0 1920x920x24 &\n\
    fluxbox &\n\
    /usr/bin/ibus-daemon -dr &\n\
    dconf load / < ~/build/dconf &\n\
    firefox --kiosk $REQ &\n\
    echo -ne '\''\n\
    user_pref("font.language.group", "ja");\n\
    user_pref("font.name.monospace.ja", "IPAPGothic");\n\
    user_pref("font.name.sans-serif.ja", "IPAPGothic");\n\
    user_pref("font.name.serif.ja", "IPAMincho");\n\
    user_pref("general.autoScroll", true);\n\
    user_pref("general.smoothScroll", false);'\'' >> $pref/prefs.js \n\
    x11vnc -display :1' \
    > /build/exec.sh &&\
    chmod 755 /build/exec.sh

COPY ibus.dconf /build/dconf

#----------

FROM alpine:latest as browser

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> etc/apk/repositories && \
    apk add --no-cache -U \
            fluxbox \
            xvfb \
            x11vnc \
            bash \
            python3 \
            py3-numpy \
            dbus-x11 \
            ibus-anthy \
            firefox \
            fontconfig

RUN adduser --disabled-password user

USER user

COPY --from=build --chown=user:user /build/ /home/user/build

CMD ~/build/exec.sh

ENV DISPLAY=:1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    GTK_IM_MODULE=ibus \
    XMODIFIERS=@im=ibus \
    QT_IM_MODULE=ibus

EXPOSE 6080
