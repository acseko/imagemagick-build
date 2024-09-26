#!/bin/bash
set -e -o pipefail -x

if [ -z "$BASE_IMAGE" ]; then
    echo "BASE_IMAGE env needs to be set"
    exit 1
fi

if [ -z "$1" ]; then
    echo "first argument needs to be set - IMAGEMAGICK_VERSION"
    exit 1
fi

if [ -z "$2" ]; then
    echo "second argument needs to be set - TARGET_ARCH"
    exit 1
fi

IMAGEMAGICK_VERSION=$1
TARGET_ARCH=$2

echo "Preparing to build Imagemagick $IMAGEMAGICK_VERSION for $TARGET_ARCH..."

git clone --depth 1 -b "$IMAGEMAGICK_VERSION" https://github.com/ImageMagick/ImageMagick.git
cd ImageMagick

# Drop LQR support
sed -i '/BuildRequires.*lqr/d; /--with-lqr/d' ImageMagick.spec.in

# Drop Raqm support
sed -i '/BuildRequires.*raqm/d; s/--with-raqm/--without-raqm/' ImageMagick.spec.in

# Drop ghostscript support
sed -i '/BuildRequires.*ghostscript-devel/d; s/--with-gslib/--without-gslib/' ImageMagick.spec.in

# Drop LibRaw support which is not compatible with the current version of ImageMagick
sed -i '/BuildRequires.*LibRaw/d; /--with-raw/d' ImageMagick.spec.in

if [ "${NOAGPL:-false}" = "true" ]; then
  # Drop urw-base35-fonts support, which has AGPL license.
  sed -i '/BuildRequires.*urw-base35-fonts/d; /--with-urw-base35-fonts/d; /urw-base35-fonts/d' ImageMagick.spec.in
  # Drop graphviz, since it requires urw-base35-fonts
  sed -i '/BuildRequires.*graphviz/d' ImageMagick.spec.in
fi;

AFTER_CHECKOUT_HOOK_SCRIPT="../after-checkout-${BASE_IMAGE//:/}-$IMAGEMAGICK_VERSION.sh"
if [ -x "$AFTER_CHECKOUT_HOOK_SCRIPT" ]; then
    "$AFTER_CHECKOUT_HOOK_SCRIPT"
fi

# Generate updated src.rpm
if [ "${NOAGPL:-false}" = "true" ]; then
  ./configure --with-gvc=no
else
  ./configure
fi
make dist-xz
make srpm

# Build it
if [ "${NOAGPL:-false}" = "true" ]; then
  yum-builddep -y "ImageMagick-$IMAGEMAGICK_VERSION.src.rpm" --exclude urw-base35-fonts --exclude graphviz
else
  yum-builddep -y "ImageMagick-$IMAGEMAGICK_VERSION.src.rpm"
fi
rpmbuild --rebuild --nocheck --target "$TARGET_ARCH" "ImageMagick-$IMAGEMAGICK_VERSION.src.rpm"

echo "Imagemagick $IMAGEMAGICK_VERSION for $TARGET_ARCH built successfully."
ls  -lR /root/rpmbuild/RPMS/

cd "/root/rpmbuild/RPMS/$TARGET_ARCH"

echo "Testing package for unexpected dependencies"
rpm -qp --requires ImageMagick-libs-$IMAGEMAGICK_VERSION.$TARGET_ARCH.rpm | grep -qEv 'libgs'

if [ "${NOAGPL:-false}" = "true" ]; then
  rpm -qp --requires ImageMagick-libs-$IMAGEMAGICK_VERSION.$TARGET_ARCH.rpm | grep -qEv 'urw-base35-fonts'
  rpm -qp --requires ImageMagick-libs-$IMAGEMAGICK_VERSION.$TARGET_ARCH.rpm | grep -qEv 'graphviz'
fi;

exec /tests.sh $IMAGEMAGICK_VERSION $TARGET_ARCH
