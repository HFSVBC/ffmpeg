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
RUN apk add --virtual build-dependencies\
	alpine-sdk \
  alsa-lib-dev \
  aom-dev \
  autoconf \
  automake \
  bzip2-dev \
  curl \
  cmake \
  dav1d-dev \
  git \
  gnutls-dev \
  lame-dev \
  libass-dev \
  libdrm-dev \
  libssh-dev \
  libtool \
  libtheora-dev \
  libvdpau-dev \
  libvorbis-dev \
  libvpx-dev \
  libxcb-dev \
  opus-dev \
  sdl2-dev \
  soxr-dev \
  v4l-utils-dev \
  vulkan-loader-dev \
  x264-dev \
  x265-dev \
  xvidcore-dev \
  zlib-dev

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
  && ./configure --prefix=/usr --mandir=/tmp/libva-man --infodir=/tmp/liva-info \
    --localstatedir=/var --disable-glx --disable-wayland --disable-static \
    --enable-shared --with-drivers-path=/opt/intel/mediasdk/lib64 \
	&& make -j"$(nproc)" \
	&& make install

# Get Intel VAAPI Driver, compile and install
RUN git clone https://github.com/intel/intel-vaapi-driver.git \
	&& cd intel-vaapi-driver \
	&& git checkout $INTEL_VAAPI_DRIVER_VERSION \
	&& ./autogen.sh \
  && ./configure \
	&& make -j"$(nproc)" \
	&& make install

# Get Intel Media Driver, compile and install
RUN git clone https://github.com/intel/media-driver.git \
	&& cd media-driver \
	&& git checkout intel-media-$INTEL_MEDIA_DRIVER_VERSION \
	&& mkdir ../build_media \
	&& cd ../build_media \
	&& cmake -Wno-dev -DBUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=/opt/intel/mediasdk \
    -DLIBVA_DRIVERS_PATH=/opt/intel/mediasdk/lib64 -DINSTALL_DRIVER_SYSCONF=OFF \
    -DMEDIA_RUN_TEST_SUITE=OFF ../media-driver \
	&& make -j"$(nproc)" \
	&& make install

# Get Intel Media SDK, compile and install
RUN git clone https://github.com/Intel-Media-SDK/MediaSDK.git msdk \
	&& cd msdk \
	&& git checkout intel-mediasdk-$INTEL_MEDIA_SDK_VERSION \
	&& mkdir build \
	&& cd build \
	&& cmake -DCMAKE_BUILD_TYPE=RELEASE -DMFX_PLUGINS_DIR=/opt/intel/mediasdk/plugins \
    -DMFX_PLUGINS_CONF_DIR=/opt/intel/mediasdk/plugins -DENABLE_OPENCL=OFF \
    -DENABLE_X11_DRI3=OFF -DENABLE_WAYLAND=OFF -DBUILD_DISPATCHER=ON -DENABLE_ITT=OFF \
    -DENABLE_TEXTLOG=OFF -DENABLE_STAT=OFF -DBUILD_SAMPLES=OFF ../ \
	&& make \
	&& make install

# Get FFmpeg, compile and install
ENV LIBVA_DRIVERS_PATH=/opt/intel/mediasdk/lib64/
ENV LIBVA_DRIVER_NAME=iHD
ENV LD_LIBRARY_PATH=/opt/intel/mediasdk/lib64
ENV PKG_CONFIG_PATH=/opt/intel/mediasdk/lib64/pkgconfig

RUN git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg \
	&& cd ffmpeg \
	&& git checkout n$FFMPEG_VERSION \
	&& ./configure --enable-avresample --enable-avfilter \
    --enable-gnutls --enable-gpl --enable-libass --enable-libmp3lame --enable-libvorbis \
    --enable-libvpx --enable-libxvid --enable-libx264 --enable-libx265 --enable-libtheora \
    --enable-libv4l2 --enable-libdav1d --enable-postproc --enable-pic --enable-pthreads \
    --enable-shared --enable-libxcb --enable-libssh --disable-stripping --disable-static \
    --disable-librtmp --enable-vaapi --enable-vdpau --enable-libopus --enable-libaom \
    --disable-debug --disable-yasm --enable-libmfx \
	&& make -j"$(nproc)" \
	&& make install
