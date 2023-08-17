import setuptools

setuptools.setup(
    name="jupyter-cloudbeaver-proxy",
    version='0.1',
    url="https://github.com/SwanseaUniversityMedical/SeRP-JupyterImages/files/jupyter-cloudbeaver-proxy",
    author="Alex Lee",
    description="Jupyter extension to proxy Cloud Beaver",
    packages=setuptools.find_packages(),
	keywords=['Jupyter'],
	classifiers=['Framework :: Jupyter'],
    install_requires=[
        'jupyter-server-proxy'
    ],
    entry_points={
        'jupyter_serverproxy_servers': [
            'cloudbeaver = jupyter_cloudbeaver_proxy:setup_cloudbeaver'
        ]
    },
    package_data={
        'jupyter_cloudbeaver_proxy': ['icons/cloudbeaver.svg'],
    },
)
