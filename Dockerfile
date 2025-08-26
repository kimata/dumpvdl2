FROM ubuntu:24.04 AS builder

RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends --assume-yes \
    ca-certificates \
    git \
    build-essential \
    cmake \
    pkg-config \
    librtlsdr-dev \
    libxml2-dev \
    zlib1g-dev \
    libjansson-dev \
    libglib2.0-dev \
    libzmq3-dev \
    libsqlite3-dev


RUN git clone https://github.com/szpajder/libacars -b v2.2.0
RUN mkdir libacars/build && cd libacars/build && cmake ..
RUN cd libacars/build && make && make install

RUN git clone https://github.com/szpajder/dumpvdl2.git -b v2.4.0
RUN mkdir dumpvdl2/build && cd dumpvdl2/build && cmake -DRTLSDR=TRUE -DZMQ=TRUE -DSQLITE=TRUE ..
RUN cd dumpvdl2/build && make && make install

FROM ubuntu:24.04

RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends --assume-yes \
    language-pack-ja \
    tzdata \
    librtlsdr2 \
    libxml2 \
    zlib1g \
    libjansson4 \
    libglib2.0-0 \
    libzmq5 \
    libsqlite3-0

ENV TZ=Asia/Tokyo \
    LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8

RUN locale-gen en_US.UTF-8
RUN locale-gen ja_JP.UTF-8

COPY --from=builder /usr/local/lib/libacars-2.so* /usr/local/lib/

RUN mkdir /opt/dumpvdl2

COPY --from=builder /usr/local/bin/dumpvdl2 /opt/dumpvdl2

RUN ldconfig

EXPOSE 5555

#CMD ["/opt/dumpvdl2/dumpvdl2", "--rtlsdr", "VDL2", "--centerfreq", "136975000", "--gain", "49.6", "--msg-filter", "downlink,avlc_i,acars,-acars_nodata", "--output", "decoded:pp_acars:zmq:mode=server,endpoint=tcp://*:5555"]

#CMD ["/opt/dumpvdl2/dumpvdl2", "--rtlsdr", "VDL2", "--centerfreq", "136975000", "--gain", "49.6", "--msg-filter", "all,-avlc_s,-acars_nodata,-gsif,-x25_control,-idrp_keepalive,-esis"]

CMD ["/opt/dumpvdl2/dumpvdl2", "--rtlsdr", "VDL2", "--centerfreq", "136975000", "--gain", "49.6", "--msg-filter", "all,-avlc_s,-acars_nodata,-gsif,-x25_control,-idrp_keepalive,-esis", "--output", "decoded:text:zmq:mode=server,endpoint=tcp://*:5050", "--output", "decoded:text:file:path=-"]




