# syntax=docker/dockerfile:1

# Prebuilt IHaskell Jupyter image from Docker Hub (no compilation).
# We do NOT hardcode a platform here; compose sets platform: linux/amd64.
ARG BASE_IMAGE=crosscompass/ihaskell-notebook:latest
FROM ${BASE_IMAGE}

# The image follows the Jupyter Docker Stacks layout (user jovyan:1000).
USER root

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG EXAMPLES_PATH=/home/${NB_USER}/ihaskell_examples

# (Optional) copy your example notebooks into the image.
# You'll also bind-mount ./notebook -> /home/jovyan/work at runtime.
RUN mkdir -p /home/${NB_USER}/learn_you_a_haskell ${EXAMPLES_PATH}
COPY notebook/*.ipynb /home/${NB_USER}/learn_you_a_haskell/
COPY notebook/img /home/${NB_USER}/learn_you_a_haskell/img
COPY notebook_extra/WidgetRevival.ipynb ${EXAMPLES_PATH}/

# Fix ownership to match the notebook user
RUN chown -R ${NB_UID}:users /home/${NB_USER}/learn_you_a_haskell ${EXAMPLES_PATH}

# Back to the notebook user and ensure JupyterLab UI
USER ${NB_UID}
ENV JUPYTER_ENABLE_LAB=yes