# HTTP Load Testing on AWS with Locust

Set up a simple, stateless, distributed HTTP load testing platform on AWS, based on [Locust](http://locust.io/):

> _Define user behaviour with Python code, and swarm your system with millions of simultaneous users._

For more information on the format of the test definition file [locust-eb/locustfile.py](locust-eb/locustfile.py), see [Writing a locustfile](http://docs.locust.io/en/latest/writing-a-locustfile.html).

## Attribution

This setup is heavily inspired by the AWS DevOps Blog post ["Using Locust on AWS Elastic Beanstalk for Distributed Load Generation and Testing"](https://aws.amazon.com/blogs/devops/using-locust-on-aws-elastic-beanstalk-for-distributed-load-generation-and-testing/) and its GitHub repo [eb-locustio-sample](https://www.github.com/awslabs/eb-locustio-sample).

Essentially, this repo automates the manual setup and deployment procedure of [eb-locustio-sample](https://www.github.com/awslabs/eb-locustio-sample).

## Requirements

* Python >=3.6
* [AWS CLI](https://aws.amazon.com/cli/)
* [AWS Elastic Beanstalk CLI](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html)
* a valid credential profile in `~aws/.credentials`

To install the CLI tools in a virtualenv through `pip3`:

    make install-tools

## Usage

### Setup

1. Review [locust-env.cfg](locust-env.cfg) and update it to match your preferences.

    > `LOADTEST_TARGET_URL` defines the _scheme and host_ for target endpoints.
    >
    > Define _paths_ in [the locustfile](locust-eb/locustfile.py). See ["Writing a locustfile"](http://docs.locust.io/en/latest/writing-a-locustfile.html) for reference.

2. Create the load testing infrastructure and deploy a sample Locust configuration:

    ```
    make install
    ```

3. The Locust web UI opens in your browser automatically once infrastructure creation is complete.

### Upload a new Load Test Definition

1. Update the sample load testing HTTP calls in [locust-eb/locustfile.py](locust-eb/locustfile.py).

    > See ["Writing a locustfile"](http://docs.locust.io/en/latest/writing-a-locustfile.html) for reference.

2. Stage the configuration file in Git: ([Why is this important?](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb3-deploy.html))

    ```
    git add locust-eb/locustfile.py
    ```

3. Deploy the updated Locustfile to Locust:

    ```
    make update
    ```

4. The Locust web UI opens in your browser automatically once the update is complete.

### Shut Down the Stack

1. Destroy the full load testing stack:

    ```
    make uninstall
    ```

## Overview of CLI Commands

```bash
$ make
install              Deploy Locust on AWS
update               Deploy a new Locustfile or Target URL
uninstall            Terminate all Locust resources
install-tools        Install/upgrade AWS CLI and AWS EB CLI
deploy-infra         Deploy AWS infrastructure for Locust
deploy-locust        (Re)deploy Locust to AWS infrastructure
terminate-infra      Terminate AWS infrastructure for Locust
```
