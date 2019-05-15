# Terraforming GCP [![build-status](https://infra.ci.cf-app.com/api/v1/teams/main/pipelines/terraforming-gcp/jobs/deploy-pas/badge)](https://infra.ci.cf-app.com/teams/main/pipelines/terraforming-gcp)

## How Does One Use This?

Please note that the master branch is generally *unstable*. If you are looking for something
"tested", please consume one of our [releases](https://github.com/pivotal-cf/terraforming-gcp/releases).

## What Does This Do?

You will get a booted ops-manager VM plus some networking, just the bare bones basically.

## Looking to setup a different IAAS

We have have other terraform templates to help you!

- [aws](https://github.com/pivotal-cf/terraforming-aws)
- [azure](https://github.com/pivotal-cf/terraforming-azure)

This list will be updated when more infrastructures come along.

## Prerequisites

Your system needs the `gcloud` cli, as well as `terraform`:

```bash
brew update
brew install Caskroom/cask/google-cloud-sdk
brew install terraform
```

## Deploying Ops Manager

Depending if you're deploying PAS, PKS or Control Plane you need to perform the following steps:

1. `cd` into the proper directory:
    - [terraforming-pas/](terraforming-pas/)
    - [terraforming-pks/](terraforming-pks/)
    - [terraforming-control-plane/](terraforming-control-plane/)
1. Create [`terraform.tfvars`](/README.md#var-file) file
1. Run terraform apply:
  ```bash
  terraform init
  terraform plan -out=plan
  terraform apply plan
  ```

## Notes

You will need a key file for your [service account](https://cloud.google.com/iam/docs/service-accounts)
to allow terraform to deploy resources. If you don't have one, you can create a service account and a key for it:

```bash
gcloud iam service-accounts create ACCOUNT_NAME --display-name "Some Account Name"
gcloud iam service-accounts keys create "terraform.key.json" --iam-account "ACCOUNT_NAME@PROJECT_ID.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding PROJECT_ID --member 'serviceAccount:ACCOUNT_NAME@PROJECT_ID.iam.gserviceaccount.com' --role 'roles/owner'
```

You will need to enable the following Google Cloud APIs:
- [Identity and Access Management](https://console.developers.google.com/apis/api/iam.googleapis.com)
- [Cloud Resource Manager](https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/)
- [Cloud DNS](https://console.developers.google.com/apis/api/dns/overview)
- [Cloud SQL API](https://console.developers.google.com/apis/api/sqladmin/overview)
- [Compute Engine API](https://console.developers.google.com/apis/library/compute.googleapis.com)

### Var File

Copy the stub content below into a file called `terraform.tfvars` and put it in the root of this project.
These vars will be used when you run `terraform  apply`.
You should fill in the stub values with the correct content.

```hcl
env_name         = "some-environment-name"
project          = "your-gcp-project"
region           = "us-central1"
zones            = ["us-central1-a", "us-central1-b", "us-central1-c"]
dns_suffix       = "gcp.some-project.cf-app.com"
opsman_image_url = "https://storage.googleapis.com/ops-manager-us/pcf-gcp-2.0-build.264.tar.gz"

buckets_location = "US"

ssl_cert = <<SSL_CERT
-----BEGIN CERTIFICATE-----
some cert
-----END CERTIFICATE-----
SSL_CERT

ssl_private_key = <<SSL_KEY
-----BEGIN RSA PRIVATE KEY-----
some cert private key
-----END RSA PRIVATE KEY-----
SSL_KEY

service_account_key = <<SERVICE_ACCOUNT_KEY
{
  "type": "service_account",
  "project_id": "your-gcp-project",
  "private_key_id": "another-gcp-private-key",
  "private_key": "-----BEGIN PRIVATE KEY-----another gcp private key-----END PRIVATE KEY-----\n",
  "client_email": "something@example.com",
  "client_id": "11111111111111",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/"
}
SERVICE_ACCOUNT_KEY
```

### Var Details
- env\_name: **(required)** An arbitrary unique name for namespacing resources. Max 23 characters.
- project: **(required)** ID for your GCP project.
- region: **(required)** Region in which to create resources (e.g. us-central1)
- zones: **(required)** Zones in which to create resources. Must be within the given region. Currently you must specify exactly 3 unique Zones for this terraform configuration to work. (e.g. [us-central1-a, us-central1-b, us-central1-c])
- opsman\_image\_url **(required)** Source URL of the Ops Manager image you want to boot.
- service\_account\_key: **(required)** Contents of your service account key file generated using the `gcloud iam service-accounts keys create` command.
- dns\_suffix: **(required)** Domain to add environment subdomain to (e.g. foo.example.com). Trailing dots are not supported.
- buckets\_location: **(optional)** Loction in which to create buckets. Defaults to US.
- ssl\_cert: **(conditionally required)** SSL certificate for HTTP load balancer configuration. Required unless `ssl_ca_cert` is specified.
- ssl\_private\_key: **(conditionally required)** Private key for above SSL certificate. Required unless `ssl_ca_cert` is specified.
- ssl\_ca\_cert: **(conditionally required)** SSL CA certificate used to generate self-signed HTTP load balancer certificate. Required unless `ssl_cert` is specified.
- ssl\_ca\_private\_key: **(conditionally required)** Private key for above SSL CA certificate. Required unless `ssl_cert` is specified.
- opsman\_storage\_bucket\_count: **(optional)** Google Storage Bucket for BOSH's Blobstore.
- create\_iam\_service\_account\_members: **(optional)** Create IAM Service Account project roles. Default to `true`.

## DNS Records
- pcf.*$env_name*.*$dns_suffix*: Points at the Ops Manager VM's public IP address.
- \*.sys.*$env_name*.*$dns_suffix*: Points at the HTTP/S load balancer in front of the Router.
- doppler.sys.*$env_name*.*$dns_suffix*: Points at the TCP load balancer in front of the Router. This address is used to send websocket traffic to the Doppler server.
- loggregator.sys.*$env_name*.*$dns_suffix*: Points at the TCP load balancer in front of the Router. This address is used to send websocket traffic to the Loggregator Trafficcontroller.
- \*.apps.*$env_name*.*$dns_suffix*: Points at the HTTP/S load balancer in front of the Router.
- \*.ws.*$env_name*.*$dns_suffix*: Points at the TCP load balancer in front of the Router. This address can be used for application websocket traffic.
- ssh.sys.*$env_name*.*$dns_suffix*: Points at the TCP load balancer in front of the Diego brain.
- tcp.*$env_name*.*$dns_suffix*: Points at the TCP load balancer in front of the TCP router.

## Isolation Segments (optional)
- isolation\_segment: **(optional)** When set to `true` creates HTTP load-balancer across 3 zones for isolation segments.
- iso\_seg\_with\_firewalls: **(optional)** When set to `true` creates firewall rules to lock down ports on the isolation segment.
- iso\_seg\_ssl\_cert: **(optional)** SSL certificate for Iso Seg HTTP load balancer configuration. Required unless `iso_seg_ssl_ca_cert` is specified.
- iso\_seg\_ssl\_private\_key: **(optional)** Private key for above SSL certificate. Required unless `iso_seg_ssl_ca_cert` is specified.
- iso\_seg\_ssl\_ca\_cert: **(optional)** SSL CA certificate used to generate self-signed Iso Seg HTTP load balancer certificate. Required unless `iso_seg_ssl_cert` is specified.
- iso\_seg\_ssl\_ca\_private\_key: **(optional)** Private key for above SSL CA certificate. Required unless `iso_seg_ssl_cert` is specified.

## Cloud SQL Configuration (optional)
- external\_database: **(optional)** When set to `true`, a cloud SQL instance will be deployed for the Ops Manager and PAS.

## Ops Manager (optional)
- opsman\_sql\_db\_host: **(optional)** The host the user can connect from. Can be an IP address. Changing this forces a new resource to be created.
- opsman\_image\_url **(optional)** Source URL of the Ops Manager image you want to boot (if not provided you get no Ops Manager).

## PAS (optional)
- pas\_sql\_db\_host: **(optional)** The host the user can connect from. Can be an IP address. Changing this forces a new resource to be created.

## PAS Cloud Controller's Google Cloud Storage Buckets (optional)
- create\_gcs\_buckets: **(optional)** When set to `false`, buckets will not be created for PAS Cloud Controller. Defaults to `true`.

## Internetless (optional)
- internetless: **(optional)** When set to `true`, all traffic going outside the 10.* network is denied. DNS records like '*.apps.DOMAIN' will be pointed to the HAProxy static IP rather than the LB address.

## Running

Note: please make sure you have created the `terraform.tfvars` file above as mentioned.

### Tearing down environment

**Note:** This will only destroy resources deployed by Terraform. You will need to clean up anything deployed on top of that infrastructure yourself (e.g. by running `om delete-installation`)

```bash
terraform destroy
```
