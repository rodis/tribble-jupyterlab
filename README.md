# tribble-jupyterlab

A thin Dockerfile that re-exports the official
[`jupyter/tensorflow-notebook`](https://quay.io/repository/jupyter/tensorflow-notebook)
image, so a platform that only builds from a Git repo (no registry images) can
still deploy JupyterLab.

Ships the scipy stack (pandas, numpy, scipy, matplotlib, scikit-learn) plus
TensorFlow and Keras.

## Deploy

Point the platform at this repo. It finds `Dockerfile` and builds it instead of
falling back to railpack. Nothing else is required.

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | — | Injected by most platforms; takes precedence if set. |
| `JUPYTER_PORT` | `8888` | Fallback port when `PORT` is absent. |
| `JUPYTER_TOKEN` | random | Login token. Set it, or read the generated one from the deploy logs. |
| `TF_CPP_MIN_LOG_LEVEL` | `1` | TensorFlow log verbosity. `0` restores the full INFO chatter. |

Set `JUPYTER_TOKEN` before the first deploy — otherwise the only way in is to
dig the token out of the container logs, and it changes on every restart.

## Persistent storage

Mount the volume at **`/home/jovyan/work`**.

On Kubernetes a PVC mounts as `root:root 0755` by default, and the server runs
as uid 1000 (`jovyan`, gid 100) — so JupyterLab starts fine but cannot write to
the mount, and the failure only surfaces when someone saves a notebook. Fix it
one of two ways:

1. **Preferred — set `fsGroup: 100` in the pod security context.** The kubelet
   chgrps the volume to gid `users` and adds `g+rwxs`; `jovyan` is already in
   that group. No root required.
2. **If you cannot set a security context** — run the container as uid 0 with:

   ```
   CHOWN_EXTRA=/home/jovyan/work
   CHOWN_EXTRA_OPTS=-R
   ```

   `start.sh` fixes ownership, then drops privileges, so the server itself still
   runs unprivileged as `jovyan`.

Option 2 is unavailable under a restricted Pod Security Standard
(`runAsNonRoot: true`); use `fsGroup` there.

Anything outside the mount — `~/.jupyter` config, extra `pip install`s, UI
settings — is lost on redeploy. Bake those into this Dockerfile instead.

## GPU

For GPU nodes, change the base image tag to the CUDA variant:

```dockerfile
FROM quay.io/jupyter/tensorflow-notebook:cuda-2026-11-02
```

That needs the NVIDIA device plugin on the cluster and a GPU resource request on
the pod. The CPU image pinned here ignores GPUs entirely.

## Upgrading

Bump the dated tag in `Dockerfile` (e.g. `2026-11-02`) to a newer one from the
[tag list](https://quay.io/repository/jupyter/tensorflow-notebook?tab=tags).

## Adding packages

```dockerfile
RUN mamba install --yes polars duckdb && \
    mamba clean --all -f -y
```
