# tribble-jupyterlab

A one-line Dockerfile that re-exports the official
[`jupyter/minimal-notebook`](https://quay.io/repository/jupyter/minimal-notebook)
image, so a platform that only builds from a Git repo (no registry images) can
still deploy JupyterLab.

## Deploy

Point the platform at this repo. It finds `Dockerfile` and builds it instead of
falling back to railpack. Nothing else is required.

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | — | Injected by most platforms; takes precedence if set. |
| `JUPYTER_PORT` | `8888` | Fallback port when `PORT` is absent. |
| `JUPYTER_TOKEN` | random | Login token. Set it, or read the generated one from the deploy logs. |

Set `JUPYTER_TOKEN` before the first deploy — otherwise the only way in is to
dig the token out of the container logs, and it changes on every restart.

## Storage

Notebooks live under `/home/jovyan` (owned by uid 1000, `jovyan`). Without a
persistent volume mounted there, everything is lost on redeploy. Mount
`/home/jovyan/work` if the platform supports volumes.

## Upgrading

Bump the dated tag in `Dockerfile` (e.g. `2026-11-02`) to a newer one from the
[tag list](https://quay.io/repository/jupyter/minimal-notebook?tab=tags).

## Adding packages

`minimal-notebook` is deliberately bare — no pandas, numpy, or scipy. Either add
a layer here:

```dockerfile
RUN mamba install --yes pandas numpy && \
    mamba clean --all -f -y
```

...or switch the base image to `quay.io/jupyter/scipy-notebook` /
`datascience-notebook`, which ship the usual stack.
