FROM skopciewski/devenv-base

USER root

RUN apk add --no-cache \
      ctags \
      libnotify \
      python 

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

ENV JAVA_VERSION 8u131
ENV JAVA_ALPINE_VERSION 8.131.11-r2

RUN set -x \
  && apk add --no-cache \
    openjdk8-jre="$JAVA_ALPINE_VERSION" \
  && [ "$JAVA_HOME" = "$(docker-java-home)" ]
##############################################################################################

ARG user=dev
USER ${user}

RUN mkdir -p /home/${user}/sbin \
  && curl -fsS https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > /home/${user}/sbin/lein \
  && chmod 755 /home/${user}/sbin/lein \
  && /home/${user}/sbin/lein

RUN curl -fsSL https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh > /home/${user}/sbin/boot \
  && chmod 755 /home/${user}/sbin/boot \
  && /home/${user}/sbin/boot -h \
  && /home/${user}/sbin/boot -h

ENV JOKER_VER=0.8.6
RUN cd /home/${user}/sbin \
  && curl -fsSLo joker-${JOKER_VER}-linux-amd64.zip https://github.com/candid82/joker/releases/download/v${JOKER_VER}/joker-${JOKER_VER}-linux-amd64.zip \
  && unzip joker-${JOKER_VER}-linux-amd64.zip \
  && rm joker-${JOKER_VER}-linux-amd64.zip

ENV DEVDOTFILES_VIM_CLOJURE_VER=1.0.6
RUN mkdir -p /home/${user}/opt \
  && cd /home/${user}/opt \
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
