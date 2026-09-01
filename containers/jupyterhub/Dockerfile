FROM jupyterhub/jupyterhub:5.0.0

LABEL org.opencontainers.image.source=https://github.com/SwanseaUniversityMedical/DARE-Jupyter

# Build custom proxy packages in-image (previously done in CI before docker build)
COPY containers/custom-packages/jupyter-cloudbeaver-proxy /tmp/build/jupyter-cloudbeaver-proxy
COPY containers/custom-packages/jupyter-rsession-proxy /tmp/build/jupyter-rsession-proxy

RUN apt-get update && \
	apt-get install -y --no-install-recommends python3-venv && \
	pip install --upgrade build && \
	python -m build --outdir /tmp/build/dist /tmp/build/jupyter-cloudbeaver-proxy && \
	python -m build --outdir /tmp/build/dist /tmp/build/jupyter-rsession-proxy && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*
