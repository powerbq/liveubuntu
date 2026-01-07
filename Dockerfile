FROM busybox AS cloud-build
ADD https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64-root.tar.xz /
WORKDIR /build-ubuntu
RUN xz -dck /noble-server-cloudimg-amd64-root.tar.xz | tar -xpf -

FROM scratch AS ubuntu-cloud
COPY --from=cloud-build /build-ubuntu/ /

FROM ubuntu-cloud AS debootstrap-build
ENV LC_ALL=C
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y debootstrap
RUN mkdir /build-ubuntu /cache-ubuntu
COPY debootstrap*/ /cache-ubuntu/
RUN debootstrap --cache-dir /cache-ubuntu noble /build-ubuntu http://archive.ubuntu.com/ubuntu 2>&1 | tee /var/log/live-debootstrap.log

FROM scratch
ENV LC_ALL=C
ENV DEBIAN_FRONTEND=noninteractive
ENV MAIN_PACKAGE=ubuntu-server
COPY --from=debootstrap-build /build-ubuntu/ /
COPY --from=debootstrap-build /var/log/live-debootstrap.log /var/log/
COPY --from=debootstrap-build /cache-ubuntu /usr/local/src/build/debootstrap/
COPY --from=ubuntu-cloud /etc/apt/sources.list /etc/apt/
COPY --from=ubuntu-cloud /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/
COPY entrypoint/entrypoint.sh /usr/local/src/build/
COPY excludes.txt PKGBUILD-* /usr/local/src/build/
COPY hooks/ /etc/initramfs-tools/hooks/
COPY scripts/ /etc/initramfs-tools/scripts/
COPY patches/patch-*/ /usr/local/live/patch/
COPY packages.sh.d/ /usr/local/src/build/packages.sh.d/
COPY debs/ /usr/local/src/build/debs/
COPY makepkg/ /usr/local/src/build/makepkg/

ENTRYPOINT ["/usr/local/src/build/entrypoint.sh"]
