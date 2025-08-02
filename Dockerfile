# Use a supported Debian version (Bullseye/Debian 11)
FROM buildpack-deps:bullseye

# Install system packages in one layer
RUN set -xe && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        locales \
        sqlite3 \
        git \
        libcap-dev \
        bison \
        re2c \
        curl \
        wget \
        ca-certificates && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Install GCC 14.3.0 from pre-built binary (much faster than compiling)
RUN set -xe && \
    curl -fSsL "https://ftp.gnu.org/gnu/gcc/gcc-14.3.0/gcc-14.3.0.tar.gz" -o /tmp/gcc-14.3.0.tar.gz && \
    mkdir /tmp/gcc-14.3.0 && \
    tar -xf /tmp/gcc-14.3.0.tar.gz -C /tmp/gcc-14.3.0 --strip-components=1 && \
    rm /tmp/gcc-14.3.0.tar.gz && \
    cd /tmp/gcc-14.3.0 && \
    ./contrib/download_prerequisites && \
    { rm *.tar.* || true; } && \
    tmpdir="$(mktemp -d)" && \
    cd "$tmpdir" && \
    /tmp/gcc-14.3.0/configure \
        --disable-multilib \
        --enable-languages=c,c++ \
        --prefix=/usr/local/gcc-14.3.0 && \
    make -j$(nproc) && \
    make -j$(nproc) install-strip && \
    rm -rf /tmp/*

# Install Python 3.13.5 from source (needed for Node.js compatibility)
ENV PYTHON_VERSIONS=3.13.5
RUN set -xe && \
    for VERSION in $PYTHON_VERSIONS; do \
      curl -fSsL "https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tar.xz" -o /tmp/python-$VERSION.tar.xz && \
      mkdir /tmp/python-$VERSION && \
      tar -xf /tmp/python-$VERSION.tar.xz -C /tmp/python-$VERSION --strip-components=1 && \
      rm /tmp/python-$VERSION.tar.xz && \
      cd /tmp/python-$VERSION && \
      ./configure \
        --prefix=/usr/local/python-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      rm -rf /tmp/*; \
    done && \
    ln -sf /usr/local/python-3.13.5/bin/python3 /usr/local/bin/python3 && \
    ln -sf /usr/local/python-3.13.5/bin/python3 /usr/local/bin/python

# Install Java from pre-built binary
RUN set -xe && \
    curl -fSsL "https://download.java.net/java/GA/jdk24.0.2/fdc5d0102fe0414db21410ad5834341f/12/GPL/openjdk-24.0.2_linux-x64_bin.tar.gz" -o /tmp/openjdk24.tar.gz && \
    mkdir /usr/local/openjdk24 && \
    tar -xf /tmp/openjdk24.tar.gz -C /usr/local/openjdk24 --strip-components=1 && \
    rm /tmp/openjdk24.tar.gz && \
    ln -s /usr/local/openjdk24/bin/javac /usr/local/bin/javac && \
    ln -s /usr/local/openjdk24/bin/java /usr/local/bin/java && \
    ln -s /usr/local/openjdk24/bin/jar /usr/local/bin/jar

# Install Node.js from pre-built binary (much faster than compiling)
ENV NODE_VERSIONS=22.17.1
RUN set -xe && \
    for VERSION in $NODE_VERSIONS; do \
      curl -fSsL "https://nodejs.org/dist/v$VERSION/node-v$VERSION-linux-x64.tar.xz" -o /tmp/node-$VERSION.tar.xz && \
      mkdir /usr/local/node-$VERSION && \
      tar -xf /tmp/node-$VERSION.tar.xz -C /usr/local/node-$VERSION --strip-components=1 && \
      rm /tmp/node-$VERSION.tar.xz && \
      ln -sf /usr/local/node-$VERSION/bin/node /usr/local/bin/node && \
      ln -sf /usr/local/node-$VERSION/bin/npm /usr/local/bin/npm; \
    done

# Install Rust from pre-built binary
ENV RUST_VERSIONS=1.88.0
RUN set -xe && \
    for VERSION in $RUST_VERSIONS; do \
      curl -fSsL "https://static.rust-lang.org/dist/rust-$VERSION-x86_64-unknown-linux-gnu.tar.gz" -o /tmp/rust-$VERSION.tar.gz && \
      mkdir /tmp/rust-$VERSION && \
      tar -xf /tmp/rust-$VERSION.tar.gz -C /tmp/rust-$VERSION --strip-components=1 && \
      rm /tmp/rust-$VERSION.tar.gz && \
      cd /tmp/rust-$VERSION && \
      ./install.sh \
        --prefix=/usr/local/rust-$VERSION \
        --components=rustc,rust-std-x86_64-unknown-linux-gnu && \
      rm -rf /tmp/*; \
    done

# Install Go from pre-built binary
ENV GO_VERSIONS=1.24.1
RUN set -xe && \
    for VERSION in $GO_VERSIONS; do \
      curl -fSsL "https://storage.googleapis.com/golang/go$VERSION.linux-amd64.tar.gz" -o /tmp/go-$VERSION.tar.gz && \
      mkdir /usr/local/go-$VERSION && \
      tar -xf /tmp/go-$VERSION.tar.gz -C /usr/local/go-$VERSION --strip-components=1 && \
      rm -rf /tmp/*; \
    done

# Install PHP from source (needed for specific version)
ENV PHP_VERSIONS=8.4.11
RUN set -xe && \
    for VERSION in $PHP_VERSIONS; do \
      curl -fSsL "https://codeload.github.com/php/php-src/tar.gz/php-$VERSION" -o /tmp/php-$VERSION.tar.gz && \
      mkdir /tmp/php-$VERSION && \
      tar -xf /tmp/php-$VERSION.tar.gz -C /tmp/php-$VERSION --strip-components=1 && \
      rm /tmp/php-$VERSION.tar.gz && \
      cd /tmp/php-$VERSION && \
      ./buildconf --force && \
      ./configure \
        --prefix=/usr/local/php-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      rm -rf /tmp/*; \
    done

# Install TypeScript using npm
ENV TYPESCRIPT_VERSIONS=5.8.3
RUN set -xe && \
    for VERSION in $TYPESCRIPT_VERSIONS; do \
      npm install -g typescript@$VERSION; \
    done

# Install Ruby from source (needed for specific version)
ENV RUBY_VERSIONS=3.4.5
RUN set -xe && \
    for VERSION in $RUBY_VERSIONS; do \
      curl -fSsL "https://cache.ruby-lang.org/pub/ruby/${VERSION%.*}/ruby-$VERSION.tar.gz" -o /tmp/ruby-$VERSION.tar.gz && \
      mkdir /tmp/ruby-$VERSION && \
      tar -xf /tmp/ruby-$VERSION.tar.gz -C /tmp/ruby-$VERSION --strip-components=1 && \
      rm /tmp/ruby-$VERSION.tar.gz && \
      cd /tmp/ruby-$VERSION && \
      ./configure \
        --disable-install-doc \
        --prefix=/usr/local/ruby-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      rm -rf /tmp/*; \
    done

# Install Bash from source (needed for specific version)
ENV BASH_VERSIONS=5.0
RUN set -xe && \
    for VERSION in $BASH_VERSIONS; do \
      curl -fSsL "https://ftpmirror.gnu.org/bash/bash-$VERSION.tar.gz" -o /tmp/bash-$VERSION.tar.gz && \
      mkdir /tmp/bash-$VERSION && \
      tar -xf /tmp/bash-$VERSION.tar.gz -C /tmp/bash-$VERSION --strip-components=1 && \
      rm /tmp/bash-$VERSION.tar.gz && \
      cd /tmp/bash-$VERSION && \
      ./configure \
        --prefix=/usr/local/bash-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      rm -rf /tmp/*; \
    done

# Install isolate
RUN set -xe && \
    git clone https://github.com/judge0/isolate.git /tmp/isolate && \
    cd /tmp/isolate && \
    git checkout ad39cc4d0fbb577fb545910095c9da5ef8fc9a1a && \
    make -j$(nproc) install && \
    rm -rf /tmp/*

ENV BOX_ROOT=/var/local/lib/isolate

LABEL maintainer="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL version="1.4.0" 