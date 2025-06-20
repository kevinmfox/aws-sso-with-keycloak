# Overview
I wanted to have an Identity Provider that I could _spin up_ relatively quickly - so, Keycloak (https://www.keycloak.org/)

Additionally, I work/play a lot with AWS, and didn't find a lot of documentation on how to get Keycloak properly working with AWS IAM Identity Center as an Identity Provider.

This repo gives a rundown on how to deploy a Keycloak server into an AWS account and will also cover how to configure the AWS Identity Center side as well as the Keycloak side to allow SSO into AWS Console for your Keycloak users.

The deployment of Keycloak is done via Terraform and a shell script through user data (```cloud-init-keycloak.sh```). The AWS IAM Identity Center and Keycloak setup afterwards is manual (but lightweight) - it could certainly be automated, but that wasn't the goal of this particular exercise :)

## Requirements

- You have an active AWS account and are relatively familiar with how to use it
- You have some familiarity with Terraform and how to run plans
- Your Terraform setup can _reach_ your AWS environment programmatically
- I only tested all of this on Ubuntu 24.04

## Assumptions
The Terraform script assumes you have a Route53 zone setup and at your disposal. If you don't you'll need to modify the Terraform script to not use Route53, and you'll most likely have to modify the ```cloud-init-keycloak.sh``` script to not automatically get an SSL certificate (as that needs a DNS name in place). Just create a DNS record wherever you want to, point it at the server, and run the certbot command manually on the system afterwards.
You can certainly run Keycloak without an SSL cert, but that requires some other nonsense that I've since forgotten (and I didn't test this setup without a cert).

## Warnings
I use a password of 'password' everywhere for this. Obviously if you're going to do anyting _real_ with this environment, review everything and make it _production ready_.

Additionally, the Security Group, while it does restrict the ports, does allow everyone (0.0.0.0/0) to _hit_ those ports.

None of the below is inherently destructive, but there is a point where you modify AWS IAM Identity Center's Identity source. If you're in an existing environment and blindly change identity sources, that could be a bad thing. As always, understand what you're running in any of your environments...even if it's just for testing.

# Walkthrough

## Keycloak Terraform Deploy

Before you run any Terraform commands, take a look at ```terraform.tfvars``` and update any relavant information.

Once the variables are updated, run the following terraform commands to get moving with Terraform:

```terraform init```

```terraform plan```

```terraform apply```

This will take about 5 minutes or so, but eventually you should be able to access the server via HTTPS.

If you're a Chrome user and you ran certbot in staging mode, you'll need to use incognito to get at the site.

Once the site's up, log in using ```admin``` and ```password``` (assuming you didn't modify that).

## AWS Identity Center Setup

Log into your AWS account, and head on over to "IAM Identity Center".

If you haven't yet enabled Identity Center, it will look like this:

<img src="images/image01.jpg" ></a>

 There are some things to consider when enabling Identity Center. Nothing _earth shattering_, but it does shift a few things around: https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-prerequisites.html

 Assuming Identity Center is enabled, head on over to "Settings" and select "Change identity source" under "Actions":

 <img src="images/image02.jpg" ></a>

Select "External identity provider", and click "Next"

Download the metadata file locally (e.g. ```aws-metadata.xml```)

## Keycloak IdP Setup

Back on over to your Keycloak instance, select "Clients" on the left menu, and select "Import client":

<img src="images/image03.jpg" ></a>

Select "Browse..." on the next screen, and upload your ```aws-metadata.xml``` file.

You can give it a friendly name if you want, otherwise just hit "Save".

Under "Realm settings" on the left menu, scroll all the way to the bottom, right-click "SAML 2.0 Identity Provider Metadat", and save that info locally (e.g. ```keycloak-metadata.xml```)

<img src="images/image04.jpg" ></a>

## AWS Identity Provider Finalization

Back over to AWS (assuming you didn't close that last screen), click the "Choose file" under "IdP SAML Metadata" and upload the ```keycloak-metadata.xml``` file.

Click "Next", review the details, type "ACCEPT" and click "Change identity source".

## AWS User Creation

Since Keycloak doesn't support SCIM by default (and I have yet to look into it), we'll need to create our user mappings manually in AWS.

Still in IAM Identity Center, select Users, and click "Add user".

__Important__: This tripped me up for longer than I'd like to admit. Keycloak will, by default, pass the user email address as the username identity, even if you setup your keycloak users with simple usernames. For example...I created a keycloak user with 'kfox' as the username, and 'kfox@foxlab.ca' as the email. I can authenticate with Keycloak using 'kfox', and even suring the SSO process, I will use 'kfox' to sign-in, but what gets sent over to AWS is 'kfox@foxlab.ca', and AWS expects that to be in the username field. I'll cover how to address this (if you want) below, but it wasn't obvious to me.

So, my user was setup as such:

<img src="images/image05.jpg" ></a>

Click "Next", "Next", and "Add user".

Once the user is added, they'll need some permissions. If you're using AWS Organizations, there's a good chance some pre-defined permissions have already been created for you. If not, you can easily create one from a template. Quickest way to check would be to Click "Permission sets" within IAM Identity Center - if you see items in there, great. If not, click "Create permission set", select "Predefined permission set", and I'd select "ReadOnlyAccess" (for testing) and click "Next", "Next", and "Create".

Click "AWS Accounts" within IAM Identity Center, select (check box) an account, and click "Assign users or groups". Select the user you created, click "Next". On the Permission sets screen, select an available permission set, click "Next", and click "Submit".

## Keycloak User Creation

Over in Keycloak, select "Users" in the left menu, and click "Add user".

My user was setup as such:

<img src="images/image06.jpg" ></a>

__Note__ that the Username is setup as the email (vs. 'kfox'). This isn't required, but since AWS is (by default) expecting the email to be passed along, it's just easier to be consistent (i.e. using email everywhere for _users_).

Click "Create".

On the next screen, you'll need to give this user credentials. Click "Credentials", click "Set password", give the user a password and turn "Temporary" off to make life eaiser for testing. Click "Save".

<img src="images/image07.jpg" ></a>

Log out of Keycloak (to avoid issues during the SSO process).

## Test It!

On the Dashboard of your AWS IAM Identity Center page, you should see an "AWS access portal URL". Give that a shot. Just note that if you're running Chrome and didn't deploy a valid (non-staging) SSL certificate, you'll want to run that incognito.

You should get redirected to Keycloak's login screen:

<img src="images/image08.jpg" ></a>

Upon login, you should be redirected to the AWS access portal:

<img src="images/image09.jpg" ></a>

Click on "AWSReadOnlyAccess" or whatever permission set you've assigned, and away you go!

## Usernames Instead of Emails

If you run into this, or really just want to use usernames (e.g. kfox) instead of emails for Keycloak + AWS, read on...

Back in Keycloak, I've deleted my original user, and recreated it as (don't forget to set the credentials):

<img src="images/image10.jpg" ></a>

In AWS IAM Identity Center, I've recreated my user with a 'kfox' username vs. 'kfox@foxlab.ca':

<img src="images/image11.jpg" ></a>

In Keycloak, select "Client scopes" on the left menu and "Create client scope".

Give it a Name, set the Type to "Default", the Protocol to "SAML" and hit "Save".

<img src="images/image12.jpg" ></a>

On the next page, select the "Mappers" tab.

Click "Configure a new mapper", select "User Attribute Mapper for NameID".

Give it a Name (e.g. "AWS-Username"), set the "Name ID Format" to 'emailAddress' (shown below), set the "User Attribute" to "username" and click "Save":

<img src="images/image13.jpg" ></a>

Click "Clients" on the left menu, select the AWS Client ID, and then cliick the "Client Scopes" tab.

Click "Add client scope" and select the newly created "aws" (or whatever you named it) SAML scope - click "Add -> Default".

<img src="images/image14.jpg" ></a>

Now head back to your AWS Portal sign-in, and you should be able to sign-in using just a username:

<img src="images/image15.jpg" ></a>
