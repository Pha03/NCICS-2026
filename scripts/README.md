# Jupyter Kernel Setup

These scripts install custom Jupyter kernels on your [Coder](https://coder.com) workspace so you can run the notebooks in this repo.

## Clone this repo

```bash
mkdir -p ~/repos
git clone https://github.com/OpenScienceComputing/NCICS-2026.git ~/repos/NCICS-2026
```

## Install kernels

### protocoast-notebook

Full geospatial/oceanography stack (xarray, dask, cartopy, rasterio, icechunk, and more).

```bash
bash ~/repos/NCICS-2026/scripts/setup-protocoast-kernel.sh
```

### eopf-notebook

Lightweight stack for EOPF data access (xarray-eopf, hvplot, datashader, geoviews).

```bash
bash ~/repos/NCICS-2026/scripts/setup-eopf-kernel.sh
```

After the script completes, **refresh JupyterLab** and the kernel will appear in the launcher.

## Notes

- Installation takes a few minutes the first time. Subsequent runs on the same workspace are fast.
- Each kernel is installed into `~/envs/<kernel-name>/` as an isolated Python 3.12 virtual environment.
- Kernels are registered per-user and are immediately available without a JupyterLab restart.
- If your workspace is **rebuilt** (not just restarted), re-run the setup script to restore the kernel.
