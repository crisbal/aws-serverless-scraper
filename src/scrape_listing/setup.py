from setuptools import setup, find_packages

setup(
    name="scrape_listing",
    version="0.0.1",
    packages=find_packages(),
    install_requires=["requests", "boto3"],
)
