# JupyterLab for Tribble.
#
# The platform builds from a repo instead of pulling a registry image, so this
# Dockerfile exists only to re-export the official Jupyter "minimal-notebook"
# image. Pinned to a dated tag for reproducible builds; bump it deliberately.
#
# Upstream: https://quay.io/repository/jupyter/minimal-notebook
FROM quay.io/jupyter/minimal-notebook:2026-11-02

# Upstream config, repeated here so it is visible:
#   ENTRYPOINT ["tini", "-g", "--", "start.sh"]   (start.sh execs CMD)
#   USER 1000 (jovyan), WORKDIR /home/jovyan

# Default port. The platform usually injects its own $PORT at runtime, which the
# CMD below prefers over this value.
ENV JUPYTER_PORT=8888
EXPOSE 8888

# Bind to all interfaces and listen on whatever port the platform hands us.
# Auth: set JUPYTER_TOKEN in the platform's env to pick the login token
# yourself; otherwise Jupyter generates a random one and prints it to the logs.
CMD ["bash", "-c", "exec start-notebook.py \
  --ServerApp.ip=0.0.0.0 \
  --ServerApp.port=${PORT:-${JUPYTER_PORT:-8888}} \
  --ServerApp.allow_remote_access=True"]
