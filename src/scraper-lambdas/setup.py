from setuptools import setup, find_packages

setup(
    name="scraper_lambdas",
    version="0.0.1",
    packages=find_packages(),
    install_requires=["requests", "boto3"],
    extras_require={
        'dev': [
            'boto3-stubs[essential]',
        ]
    }
)
