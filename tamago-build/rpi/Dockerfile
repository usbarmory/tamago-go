# The version of Go used to compile tamago-go
ARG BOOTSTRAP_GO_VERSION=1.16.4

FROM golang:$BOOTSTRAP_GO_VERSION as go

COPY / /usr/local/tamago-go
RUN cd /usr/local/tamago-go/src && ./all.bash

FROM multiarch/crossbuild

COPY --from=go /usr/local/tamago-go /usr/local/tamago-go
ENV TAMAGO=/usr/local/tamago-go/bin/go

ENV CROSS_TRIPLE=arm-linux-gnueabi
COPY /tamago-build/rpi /tamago-build/

ENTRYPOINT ["crossbuild", "/tamago-build/build.sh"]
CMD ["."]
