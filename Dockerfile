FROM alpine:latest as build

RUN apk add --no-cache -U \
            git \
            curl

RUN git clone git://github.com/novnc/noVNC /build/noVNC && \
    git clone https://github.com/novnc/websockify /build/noVNC/utils/websockify && \
    sed -ie 's/python\s/python3 /g' /build/noVNC/utils/websockify/run

RUN curl -O https://ipafont.ipa.go.jp/IPAfont/IPAfont00303.zip && \
    unzip IPAfont00303.zip -d /build/

RUN echo -ne \
    '#!/bin/bash\n \
    if [ "${REQ}" == "" ]; then \
      REQ="google.com"; \
    fi && \
    ~/build/noVNC/utils/launch.sh\n \
    Xvfb :1 -screen 0 1920x920x24 & \
    fluxbox & \
    /usr/bin/ibus-daemon -dr & \
    dconf load / < ~/build/dconf & \
    firefox --kiosk $REQ & \
    x11vnc -display :1' \
    > /build/exec.sh && \
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

RUN mkdir ~/.fluxbox && \
    echo 'session.screen0.toolbar.visible: false' >> ~/.fluxbox/init && \
    mkdir ~/.fonts && \
    mv ~/build/IPAfont00303/ ~/.fonts/IPAfont00303/ && \
    fc-cache -fv && \
    timeout 1 firefox -headless; exit 0; \
    pref=`find ~/.mozilla/firefox/ -iname "*.default-default"` && \
    echo -ne 'user_pref("font.language.group", "ja");\n \
              user_pref("font.name.monospace.ja", "IPAPGothic");\n \
              user_pref("font.name.sans-serif.ja", "IPAPGothic");\n \
              user_pref("font.name.serif.ja", "IPAMincho");\n \
              user_pref("font.name.serif.x-western", "IPAPMincho");' >> $pref/prefs.js

CMD ~/build/exec.sh

ENV DISPLAY=:1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    GTK_IM_MODULE=ibus \
    XMODIFIERS=@im=ibus \
    QT_IM_MODULE=ibus

EXPOSE 6080
