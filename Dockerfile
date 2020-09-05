FROM alpine:latest

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> etc/apk/repositories
RUN apk update && \
    apk add fluxbox \
            xvfb \
            x11vnc \
            bash \
            git \
            python3 \
            py3-numpy \
            curl \
            fontconfig \
            ibus-anthy \
            dbus-x11 \
            firefox

RUN git clone git://github.com/novnc/noVNC && \
    git clone https://github.com/novnc/websockify /noVNC/utils/websockify && \
    sed -ie 's/python\s/python3 /g' /noVNC/utils/websockify/run

RUN curl -O https://ipafont.ipa.go.jp/IPAfont/IPAfont00303.zip && \
    unzip IPAfont00303.zip -d /usr/share/fonts/ && fc-cache -fv

RUN echo -ne '#!/bin/bash\n/noVNC/utils/launch.sh\n \
    Xvfb :1 -screen 0 1920x920x24 & \
    fluxbox & \
    /usr/bin/ibus-daemon -dr & \
    dconf load / < /tmp/dconf & \
    firefox --kiosk google.com & \
    x11vnc -display :1' > /exec.sh && chmod 755 exec.sh

RUN adduser --disabled-password user

USER user

RUN mkdir ~/.fluxbox && \
    echo 'session.screen0.toolbar.visible: false' >> ~/.fluxbox/init

RUN timeout 1 firefox -headless; exit 0; \
    pref=`find ~/.mozilla/firefox/ -iname "*.default-default"` && \
    echo -ne 'user_pref("font.language.group", "ja");\n \
              user_pref("font.name.monospace.ja", "IPAPGothic");\n \
              user_pref("font.name.sans-serif.ja", "IPAPGothic");\n \
              user_pref("font.name.serif.ja", "IPAMincho");\n \
              user_pref("font.name.serif.x-western", "IPAPMincho");' >> $pref/prefs.js

COPY ibus.dconf /tmp/dconf

CMD /exec.sh

ENV DISPLAY=:1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    GTK_IM_MODULE=ibus \
    XMODIFIERS=@im=ibus \
    QT_IM_MODULE=ibus

EXPOSE 6080
