# syntax=docker/dockerfile:1

# Use a prebuilt IHaskell Jupyter image (no compiling).
ARG BASE_IMAGE=crosscompass/ihaskell-notebook:latest
FROM ${BASE_IMAGE}

# Base image uses Jupyter Docker Stacks conventions (user jovyan:1000, group users)
USER root

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG EXAMPLES_PATH=/home/${NB_USER}/ihaskell_examples

# (Optional) copy your example notebooks into the image
RUN mkdir -p /home/${NB_USER}/learn_you_a_haskell ${EXAMPLES_PATH}
COPY notebook/*.ipynb /home/${NB_USER}/learn_you_a_haskell/
COPY notebook/img /home/${NB_USER}/learn_you_a_haskell/img
COPY notebook_extra/WidgetRevival.ipynb ${EXAMPLES_PATH}/

# Fix permissions for the notebook user
RUN chown -R ${NB_UID}:users /home/${NB_USER}/learn_you_a_haskell ${EXAMPLES_PATH}

# Back to the unprivileged user; Lab is enabled by default
USER ${NB_UID}
ENV JUPYTER_ENABLE_LAB=yes