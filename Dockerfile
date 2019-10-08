FROM skopciewski/devenv-base

USER root

RUN echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add --no-cache \
      ctags \
      libnotify \
      python \
      bash@edge \
      readline@edge \
      python2@edge \
      ruby-libs@edge \
      rlwrap@testing

# Based on: https://hub.docker.com/_/openjdk/
##############################################################################################
# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
    echo '#!/bin/sh'; \
    echo 'set -e'; \
    echo; \
    echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
  } > /usr/local/bin/docker-java-home \
  && chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u222
ENV JAVA_ALPINE_VERSION 8.222.10-r0

RUN set -x \
  && apk add --no-cache \
    openjdk8-jre="$JAVA_ALPINE_VERSION" \
  && [ "$JAVA_HOME" = "$(docker-java-home)" ]
##############################################################################################

ARG user=dev
USER ${user}

RUN mkdir -p /home/${user}/sbin \
  && mkdir -p /home/${user}/opt

RUN curl -fsS https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > /home/${user}/sbin/lein \
  && chmod 755 /home/${user}/sbin/lein \
  && /home/${user}/sbin/lein

RUN curl -fsSL https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh > /home/${user}/sbin/boot \
  && chmod 755 /home/${user}/sbin/boot \
  && /home/${user}/sbin/boot -h \
  && sed -i -e 's/^BOOT_CLOJURE_VERSION=.*/BOOT_CLOJURE_VERSION=1.10.0/' /home/${user}/.boot/boot.properties \
  && /home/${user}/sbin/boot -h

ENV CLOJURE_TOOLS_VER=1.10.0.442
RUN curl -fsSL https://download.clojure.org/install/linux-install-${CLOJURE_TOOLS_VER}.sh > /home/${user}/sbin/linux-install.sh \
  && chmod 755 /home/${user}/sbin/linux-install.sh \
  && sudo /home/${user}/sbin/linux-install.sh \
  && rm /home/${user}/sbin/linux-install.sh

ENV JOKER_VER=0.9.4
RUN cd /home/${user}/sbin \
  && curl -fsSLo joker-${JOKER_VER}-linux-amd64.zip https://github.com/candid82/joker/releases/download/v${JOKER_VER}/joker-${JOKER_VER}-linux-amd64.zip \
  && unzip joker-${JOKER_VER}-linux-amd64.zip \
  && rm joker-${JOKER_VER}-linux-amd64.zip

ENV DEVDOTFILES_VIM_CLOJURE_VER=1.0.7
RUN cd /home/${user}/opt \
  && curl -fsSL https://github.com/skopciewski/dotfiles_vim_clojure/archive/v${DEVDOTFILES_VIM_CLOJURE_VER}.tar.gz | tar xz \
  && cd dotfiles_vim_clojure-${DEVDOTFILES_VIM_CLOJURE_VER} \
  && PATH=/home/${user}/sbin:$PATH make

ENV ZSH_TMUX_AUTOSTART=true \
  ZSH_TMUX_AUTOSTART_ONCE=true \
  ZSH_TMUX_AUTOCONNECT=false \
  ZSH_TMUX_AUTOQUIT=false \
  ZSH_TMUX_FIXTERM=false \
  TERM=xterm-256color

CMD ["/bin/zsh"]
