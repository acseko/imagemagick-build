ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ENV BASE_IMAGE=${BASE_IMAGE}
ARG NOAGPL
ENV NOAGPL=${NOAGPL:-true}

RUN if [ "$BASE_IMAGE" = "redhat/ubi8" ]; then \
      rpm -ivh "https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"; \
    else \
      yum install -y epel-release; \
    fi && \
    yum install -y git make yum-utils rpm-build && \
    if [ "$NOAGPL" = "true" ] && [ "$BASE_IMAGE" = "redhat/ubi8" ]; then \
      yum install -y --skip-broken autoconf automake binutils bison flex gcc gcc-c++ gdb glibc-devel libtool pkgconf pkgconf-m4 pkgconf-pkg-config redhat-rpm-config rpm-build rpm-sign strace \
      byacc ctags diffstat intltool ltrace patchutils perl-Fedora-VSP perl-generators pesign source-highlight systemtap valgrind cmake expect rpmdevtools rpmlint; \
   elif [ "$NOAGPL" = "true" ] && [ "$BASE_IMAGE" != "redhat/ubi8" ]; then \
      echo "non RH no AGPL" && \
      yum group install -y "Development Tools" --exclude asciidoc --exclude graphviz; \
    else \
      yum group install -y "Development Tools"; \
    fi && \
    yum clean all

RUN if [ "$BASE_IMAGE" = "redhat/ubi8" ]; then \
        echo "This is RHEL8, no crb, powertools is required"; \
    elif [ "$BASE_IMAGE" = "rockylinux:9" ]; then \
        dnf install -y dnf-plugins-core && \
        dnf config-manager --set-enabled crb && \
        yum clean all; \
    else \
        yum-config-manager --enable powertools && \
        yum clean all; \
    fi

WORKDIR /build
#COPY after-checkout-* /build/
COPY tests/entrypoint.sh /tests.sh

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
