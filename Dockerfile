FROM scratch as caching-downloader
ADD https://github.com/dfiore1230/rtl_433toMQTT/blob/master/rtl433_0.9.tar /rtl433_0.9.tar
FROM alpine:3.13.2 as builder
RUN apk add --no-cache --update cmake build-base librtlsdr-dev libusb-dev bash
COPY --from=caching-downloader / /tmp
WORKDIR /build
#RUN tar -zxvf /tmp/rtl_433.tar.gz --strip-components=1
RUN tar -zxvf /tmp/rtl433_0.9.tar
RUN mkdir out && cd out && cmake .. && make -j$(nproc) && make install
RUN echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

FROM alpine:3.13.2
MAINTAINER bademux
ENV RTL_OPTS=""
RUN apk add --no-cache --update libusb librtlsdr
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/etc /usr/local/etc
COPY --from=builder /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf
COPY --from=builder /etc/udev/rules.d/rtl-sdr.rules /etc/udev/rules.d/rtl-sdr.rules
RUN adduser -D -H user -G usb
USER user
ENTRYPOINT rtl_433 $RTL_OPTS
