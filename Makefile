# -- Load Configuration

include ./locust-env.cfg
VARS:=$(shell sed -ne 's/ *\#.*$$//; /./ s/=.*$$// p' ./locust-env.cfg )
$(foreach v,$(VARS),$(eval $(shell echo export $(v)="$($(v))")))

# -- Targets

.PHONY: install
install: install-tools deploy-infra deploy-locust ## Deploy Locust on AWS

.PHONY: update
update: deploy-locust ## Deploy a new Locustfile or Target URL

.PHONY: uninstall
uninstall: terminate-infra ## Terminate all Locust resources

.ONESHELL: install-tools
.PHONY: install-tools
install-tools: ## Install/upgrade AWS CLI and AWS EB CLI
	$(call cyan, "make $@ ...")
	# Python 2
	pip install virtualenv
	virtualenv -p /usr/bin/python2 env
	. ./env/bin/activate
	pip install -r requirements.txt
	## Python 3, throws the following error when deploying through AWS EB CLI:
	## "ERROR: UnicodeDecodeError - ascii codec cant decode byte 0xc3 in position 1382: ordinal not in range(128)"
	# python3 -m venv env
	# . ./env/bin/activate
	# pip3 install -r requirements.txt

.ONESHELL: deploy-infra
.PHONY: deploy-infra
deploy-infra: ## Deploy AWS infrastructure for Locust
	$(call cyan, "make $@ ... (Patience is a virtue. Have some tea or coffee.)")
	. ./env/bin/activate
	# Note: Keep auto scaling min/max equal to prevent accidental termination of the Locust master
	aws --profile $(AWS_PROFILE) --region $(AWS_REGION) \
		cloudformation deploy \
		--stack-name $(LOADTEST_NAME) \
		--template-file ./locust-cfn.yml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			TargetUrl=$(LOADTEST_TARGET_URL) \
			ApplicationName=$(LOADTEST_NAME) \
			SolutionStackName="$(EB_SOLUTION_STACK_NAME)" \
			InstanceType=$(LOADTEST_INSTANCE_TYPE) \
			AutoScalingMinInstanceCount=$(LOADTEST_INSTANCE_COUNT) \
			AutoScalingMaxInstanceCount=$(LOADTEST_INSTANCE_COUNT)

.ONESHELL: deploy-locust
.PHONY: deploy-locust
deploy-locust: ## (Re)deploy Locust to AWS infrastructure
	$(call cyan, "make $@ ...")
	. ./env/bin/activate
	cd ./locust-eb/
	rm -rf ./.elasticbeanstalk/
	# Configure the EB CLI to target the Elastic Beanstalk environment
	eb init --profile $(AWS_PROFILE) --region $(AWS_REGION) --platform "$(EB_SOLUTION_STACK_NAME)" $(LOADTEST_NAME)
	# Set the TARGET_URL environment variable in the Elastic Beanstalk environment
	eb setenv --profile $(AWS_PROFILE) --region $(AWS_REGION) TARGET_URL=$(LOADTEST_TARGET_URL)
	# Deploy Locust to the Elastic Beanstalk environment
	eb deploy --profile $(AWS_PROFILE) --region $(AWS_REGION) --staged $(LOADTEST_NAME)
	# Print out the status of the Elastic Beanstalk deployment
	eb status --profile $(AWS_PROFILE) --region $(AWS_REGION) $(LOADTEST_NAME)
	# Open a browser window for the Elastic Beanstalk environment's endpoint
	eb open --profile $(AWS_PROFILE) --region $(AWS_REGION) $(LOADTEST_NAME)

.ONESHELL: terminate-infra
.PHONY: terminate-infra
terminate-infra: ## Terminate AWS infrastructure for Locust
	$(call cyan, "make $@ ...")
	. ./env/bin/activate
	aws --profile $(AWS_PROFILE) --region $(AWS_REGION) \
		cloudformation delete-stack --stack-name $(LOADTEST_NAME) \
	&& aws --profile $(AWS_PROFILE) --region $(AWS_REGION) \
		cloudformation wait stack-delete-complete --stack-name $(LOADTEST_NAME)

# -- Help

.DEFAULT_GOAL := help

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# -- Functions

define cyan
	@tput setaf 6
	@echo $1
	@tput sgr0
endef
