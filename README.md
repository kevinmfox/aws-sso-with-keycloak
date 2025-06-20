# Overview
I wanted to have an Identity Provider that I could _spin up_ relatively quickly.

Additionally, I work/play a lot with AWS, and didn't find a lot of documentation on how to get Keycloak () properly working with AWS IAM Identity Center.

This repo gives a rundown on how to deploy a Keycloak server into an AWS account. And, will also cover how to configure the AWS Identity Center side as well as the Keycloak side to allow SSO for your Keycloak users.

# Requirements

- You have an active AWS account and are relatively familiar with how to use it
- You have some familiarity with Terraform and how to run plans
- Your Terraform setup can _reach_ your AWS environment programmatically

# Assumptions
The Terraform script assumes you have a Route53 zone setup and at your disposal. If you don't you'll need to modify the Terraform script to not use Route53, and you'll most likely have to modify the ```cloud-init-keycloak.sh``` script to not automatically get an SSL certificate (as that needs a DNS name in place). Just create a DNS record wherever you want to, point it at the server, and run the certbot command manually on the system afterwards.
You can certainly run Keycloak without an SSL cert, but that requires some other nonsense that I've since forgotten (and I didn't test this setup without a cert).

# Warning
I use a password of 'password' everywhere for this. Obviously if you're going to do anyting _real_ with this environment, review everything and make it _production ready_.

None of the below is inherently destructive, but there is a point where you modify AWS IAM Identity Center's Identity source. If you're in an existing environment and blindly change identity sources, that could be a bad thing. As always, understand what you're running in any of your environments...even if it's just for testing.

# Walkthrough

Before you run any Terraform commands, take a look at ```terraform.tfvars``` and update any relavant information.

Once the variables are updated, run the following terraform commands to get moving with Terraform:

```terraform init```

```terraform plan```

```terraform apply```

This will take about 5 minutes or so, but eventually you should be able to access the server via HTTPS.

If you're a Chrome user and you ran certbot in staging mode, you'll need to use incognito to get at the site.

Once the site's up, log in using ```admin``` and ```password``` (assuming you didn't modify that).

