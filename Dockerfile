FROM scratch

ADD base.tar.gz /

COPY assemble.sh packages.sh oh-my-zsh.sh save.sh excludes.txt PKGBUILD-* /usr/local/src/build/
COPY hooks/ /etc/initramfs-tools/hooks/
COPY scripts/ /etc/initramfs-tools/scripts/
COPY patches/patch-*/ /usr/local/live/patch/
COPY packages.sh.d/ /usr/local/src/build/packages.sh.d/
COPY debs/ /usr/local/src/build/debs/

ENV TZ=Europe/Kiev DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C

ENV SETUP_MOZILLA_SOURCE=y
ENV SETUP_DOCKER_SOURCE=y
ENV SETUP_SUBLIME_SOURCE=y

ENV MAIN_PACKAGE=kubuntu-desktop

ENTRYPOINT ["/usr/local/src/build/assemble.sh"]
