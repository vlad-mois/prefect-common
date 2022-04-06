FROM node:14.15.1 as build_ui

RUN echo "VUE_APP_PREFECT_VERSION=1.1.0" >> .env
RUN git clone https://github.com/PrefectHQ/ui.git && mv ui /app
RUN cd /app && npm ci && npm run build
WORKDIR /app

FROM hasura/graphql-engine:v2.4.0

ENV NODE_VERSION=14.15.1
ENV PYTHON_VERSION=3.7.12

ENV LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    LC_MESSAGES=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    gdb \
    git \
    lcov \
    less \
    libbz2-dev \
    libc6-dev \
    libffi-dev \
    libgdbm-compat-dev \
    libgdbm-dev \
    liblzma-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline6-dev \
    libsqlite3-dev \
    libssl-dev \
    locales \
    lzma \
    lzma-dev \
    nano \
    nginx \
    openssh-server \
    pkg-config \
    python3-distutils \
    python3-testresources \
    supervisor \
    tini \
    tk-dev \
    tzdata \
    uuid-dev \
    vim \
    wget \
    zlib1g-dev \
  && sed -i "s/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g" /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
  && apt-get clean \
  && apt-get autoclean \
  && rm -rf /var/lib/apt/lists/*

COPY nvm-v0.35.3-install.sh ./nvm-v0.35.3-install.sh
RUN chmod +x nvm-v0.35.3-install.sh && ./nvm-v0.35.3-install.sh \
  && export NVM_DIR="$HOME/.nvm" \
  && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
  && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" \
  && nvm install $NODE_VERSION \
  && ln -s /root/.nvm/versions/node/v14.15.1/bin/npm /usr/local/bin/npm \
  && ln -s /root/.nvm/versions/node/v14.15.1/bin/node /usr/local/bin/node
RUN node --version && npm --version

RUN curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
  && tar -xvzf Python-${PYTHON_VERSION}.tgz \
  && cd Python-${PYTHON_VERSION} \
  && sed -i '/_socket socketmodule.c/s/^#//g' Modules/Setup.dist \
  && sed -i '/_ssl _ssl.c/s/^#//g' Modules/Setup.dist \
  && sed -i '/include\/openssl/s/^#//g' Modules/Setup.dist \
  && sed -i '/lib -lssl -lcrypto/s/^#//g' Modules/Setup.dist \
  && ./configure \
    --prefix=/opt/python/${PYTHON_VERSION} \
    --enable-ipv6 \
    --enable-optimizations \
    LDFLAGS=-Wl,-rpath=/opt/python/${PYTHON_VERSION}/lib,--disable-new-dtags \
  && make \
  && make install \
  && cd .. \
  && rm -r Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tgz \
  && /opt/python/3.7.12/bin/python3.7 -c 'import ssl; print(ssl.OPENSSL_VERSION)'

RUN unlink /usr/bin/python && unlink /usr/bin/python3 \
  && ln -s /opt/python/3.7.12/bin/python3.7 /usr/bin/python \
  && ln -s /opt/python/3.7.12/bin/python3.7 /usr/bin/python3 \
  && ln -s /opt/python/3.7.12/bin/pip3 /usr/bin/pip \
  && ln -s /opt/python/3.7.12/bin/pip3 /usr/bin/pip3

RUN pip install --no-cache-dir --upgrade \
  pip==22.0.4 \
  setuptools==61.1.1 \
  wheel==0.37.1

RUN pip install --no-cache-dir \
    crowd-kit \
    dask[complete]==2022.2.0 \
    ipython \
    prefect[azure,kubernetes,redis,templates,viz]==1.1.0 \
    toloka-kit>=0.1.23 \
    toloka-prefect \
  && chmod +x /opt/python/3.7.12/bin/prefect \
  && ln -s /opt/python/3.7.12/bin/prefect /usr/bin/prefect

RUN git clone https://github.com/PrefectHQ/server.git -b 2022.01.25 \
  && cp -r server/services/apollo /apollo \
  && mv server /prefect-server \
  && cd /prefect-server \
  && pip install -e . \
  && ln -s /opt/python/3.7.12/bin/prefect-server /usr/bin/prefect-server \
  && cd ..

RUN cd /apollo \
  && npm ci \
  && npm run build \
  && chmod +x post-start.sh

RUN echo "root:Docker!" | chpasswd
COPY sshd_config /etc/ssh/
RUN mkdir -p /tmp
COPY ssh_setup.sh /tmp
RUN chmod +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null)
RUN /usr/sbin/sshd

COPY --from=nginx:1.14.2 /etc/nginx /etc/nginx
COPY --from=build_ui /app/dist /var/www.bak
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.conf.d.default.conf /etc/nginx/conf.d/default.conf
COPY start_server.sh /start_server.sh
COPY prefect-agent-config.toml /root/.prefect/config.toml
RUN chmod a+x /start_server.sh
COPY --from=build_ui /app/intercept.sh /intercept.sh
RUN chmod a+x /intercept.sh

COPY start_1_hasura.sh /
COPY start_2_graphql.sh /
COPY start_3_towel.sh /
COPY start_4_apollo.sh /
COPY start_5_ui.sh /
COPY start_6_agent.sh /
RUN chmod +x start_*.sh

COPY ./supervisord.conf /etc/supervisor/conf.d/conf.src.bak
COPY ./run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 2222 8080

CMD /run.sh
