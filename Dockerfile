FROM alpine:3.12

# Intel Dependencies
ENV INTEL_GMMLIB_VERSION=20.4.1
ENV INTEL_LIBVA_VERSION=2.10.0
# Intel VAPI Driver
ENV INTEL_VAAPI_DRIVER_VERSION=2.4.1
# Intel Media Driver
ENV INTEL_MEDIA_DRIVER_VERSION=20.4.5
# Intel Media SDK
ENV INTEL_MEDIA_SDK_VERSION=20.5.1
# FFmpeg version
ENV FFMPEG_VERSION=4.3.1

RUN apk update
RUN apk add --virtual build-dependencies \
	alpine-sdk \
	autoconf \
	automake \
	bzip2-dev \
	curl \
	cmake \
	git \
	lame-dev \
	libass-dev \
	libdrm-dev \
	libtheora-dev \
	libtool \
	libvorbis-dev \
	rtmpdump-dev \
	x264-dev

WORKDIR /tmp

# Get Intel GMMLIB
RUN git clone https://github.com/intel/gmmlib.git \
	&& cd gmmlib \
	&& git checkout intel-gmmlib-$INTEL_GMMLIB_VERSION \
	&& mkdir build \
	&& cd build \
	&& cmake ../ \
	&& make -j"$(nproc)" \
	&& make install

# Get Intel LIBVA, compile and install
RUN git clone https://github.com/intel/libva.git \
	&& cd libva \
	&& git checkout $INTEL_LIBVA_VERSION \
	&& ./autogen.sh \
	&& make -j"$(nproc)" \
	&& make install

# Get Intel VAAPI Driver, compile and install
RUN git clone https://github.com/intel/intel-vaapi-driver.git \
	&& cd intel-vaapi-driver \
	&& git checkout $INTEL_VAAPI_DRIVER_VERSION \
	&& ./autogen.sh \
	&& make -j"$(nproc)" \
	&& make install

# Get Intel Media Driver, compile and install
RUN git clone https://github.com/intel/media-driver.git \
	&& cd media-driver \
	&& git checkout intel-media-$INTEL_MEDIA_DRIVER_VERSION \
	&& mkdir ../build_media \
	&& cd ../build_media \
	&& cmake ../media-driver \
	&& make -j"$(nproc)" \
	&& make install

# Get Intel Media SDK, compile and install
RUN git clone https://github.com/Intel-Media-SDK/MediaSDK.git msdk \
	&& cd msdk \
	&& git checkout intel-mediasdk-$INTEL_MEDIA_SDK_VERSION \
	&& mkdir build \
	&& cd build \
	&& cmake ../ \
	&& make \
	&& make install

# Get FFmpeg, compile and install
RUN git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg \
	&& cd ffmpeg \
	&& git checkout n$FFMPEG_VERSION \
	&& export LIBVA_DRIVERS_PATH=/usr/local/lib/dri/iHD_drv_video.so \
	&& export LIBVA_DRIVER_NAME=iHD \
	&& export LD_LIBRARY_PATH=/opt/intel/mediasdk/lib64 \
	&& export PKG_CONFIG_PATH=/opt/intel/mediasdk/lib64/pkgconfig \
	&& ./configure --arch=x86_64 --disable-yasm --enable-vaapi --enable-libmfx \
	&& make -j"$(nproc)" \
	&& make install
