ARG BASE_CONTAINER=python:3.7.4-slim-buster

ARG JUPYTER_USER="jupetri"
ARG JUPYTER_UID="12345"
ARG JUPYTER_GROUP="petri"
ARG JUPYTER_GID="54321"

FROM $BASE_CONTAINER as builder

LABEL maintainer="Arseny Mitin <mitinarseny@gmail.com>"

ARG JUPYTER_USER
ARG JUPYTER_UID
ARG JUPYTER_GROUP
ARG JUPYTER_GID

RUN apt-get update \
  && apt-get install -y \
    curl \
  && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get install -y \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    texlive-lang-cyrillic \
    pandoc \
    nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && chmod -R +777 /usr/local/ \
  && addgroup --gid "${JUPYTER_GID}" "${JUPYTER_GROUP}" \
  && adduser \
    --disabled-password \
    --gecos "" \
    --uid "${JUPYTER_UID}" \
    "${JUPYTER_USER}"

USER ${JUPYTER_USER}

RUN pip3 install --upgrade pip \
  && pip3 install --no-cache-dir \
    jupyterlab==1.1.4 \
    jupyterlab-git==0.8.1 \
    jupyterlab-latex==1.0.0 \
    jupyterlab-server==1.0.6 \
    nbconvert==5.6.0 \\
  && jupyter labextension install --clean --no-build \
    @kenshohara/theme-nord-extension \
    @jupyterlab/toc \
    @jupyterlab/latex \
    @krassowski/jupyterlab_go_to_definition \
    @ryantam626/jupyterlab_code_formatter \
    @jupyterlab/katex-extension \
    @jupyterlab/shortcutui \
  && jupyter lab build

FROM builder AS configer

ARG JUPYTER_USER
ARG JUPYTER_GROUP

WORKDIR /home/${JUPYTER_USER}

RUN mkdir -p "/home/${JUPYTER_USER}/.jupyter/"
COPY --chown=${JUPYTER_USER}:${JUPYTER_GROUP} jupyter/ /home/${JUPYTER_USER}/.jupyter/
ARG JUPYTERLAB_WORK_DIR="/home/${JUPYTER_USER}/work"

RUN mkdir -p "${JUPYTERLAB_WORK_DIR}"
ENV JUPYTERLAB_SETTINGS_DIR="/home/${JUPYTER_USER}/.jupyter/lab/user-settings/"

ENTRYPOINT ["jupyter"]
CMD ["lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
EXPOSE 8888

FROM configer
