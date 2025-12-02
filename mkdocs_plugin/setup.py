"""Setup script for PySwiftKit Demo MkDocs Plugin"""

from setuptools import setup, find_packages

setup(
    name='mkdocs-pyswiftkit-demo',
    version='0.1.0',
    description='MkDocs plugin for PySwiftKit interactive demos with Monaco Editor and Swift WASM',
    author='PySwiftKit',
    license='MIT',
    python_requires='>=3.8',
    install_requires=[
        'mkdocs>=1.4.0',
    ],
    packages=find_packages(),
    entry_points={
        'mkdocs.plugins': [
            'pyswiftkit_demo = mkdocs_plugin:PySwiftKitDemoPlugin',
        ]
    },
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
    ],
)
