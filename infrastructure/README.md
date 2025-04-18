# Website

Terraform for hosting a secure static website hosted on AWS using S3. This is based around the following project:
[step by step guide](https://www.alexhyett.com/terraform-s3-static-website-hosting) for this code on Alex Hyett's [blog](https://www.alexhyett.com/terraform-s3-static-website-hosting).

The terraform will set up the following components:

- S3 bucket for www.yourdomain.com which will host your website files.
- S3 bucket for yourdomain.com which redirects to www.yourdomain.com.
- SSL certificate for yourdomain.com.
- Cloudfront distribution for www S3 bucket.
- Cloudfront distribution for S3 bucket redirect.
- Route 53 records for:
  - root
  - www

## Using this repository

### Update your provider settings

In `providers.tf` update the bucket (`yourdomain-terraform`) and region (`eu-west-1`) parameters to match your setup. Note, the `acm_provider` needs to point to `us-east-1` for Cloudfront to be able to use it.

### Update the variables

In `terraform.tfvars` update the variables with the name of your domain and S3 bucket. You can just replace `yourdomain` with your actual domain.

Generally you will want to call you S3 bucket the name of your domain but if that is not possible (due to a conflict) then you can call it something else.

## Commands to run

- `tofu init` - To initialise the project and download any required packages.
- `tofu plan` - To see what has changed compared to your current configuration.
- `tofu apply` - To apply your changes.

The terraform scripts are set up to validate your SSL certificate via email. So you should receive an email from AWS to `webmaster@yourdomain.com` when running apply which you need to approve in order for the SSL certificate to be validated.

Alternatively, I have left the code for DNS validation in which can be uncommented if you don't have email set up (`acm.tf` and `route53.tf`).

Note however, that DNS validation requires the domain nameservers to already be pointing to AWS. You won't actually know the nameservers until after the NS route 53 record has been created. Alternatively, you can follow the validation instructions from the ACM page for your domain and apply to where your nameservers are currently hosted. DNS validation can take 30 minutes or more during which the terraform script will still be running.

## Post Changes

Once the terraform scripts have been run successfully you will need to upload your scripts to your `www.yourdomain.com` S3 bucket.

At the very least you need an `index.html` and a `404.html` file.

This uploads the contents of a directory defined in the variable var.site_content to your S3 bucket by using the command:

```
aws s3 sync . s3://www.yourdomain.com
```

Whenever you make changes to the files in your S3 bucket you need to invalidate the Cloudfront cache.

```
aws cloudfront create-invalidation --distribution-id E3EDVELPIKTLHJ --paths "/*";
```

Where `E3EDVELPIKTLHJ` is the Cloudfront ID associated with your www S3 bucket.

To perform a further upload from hugo

```
$ tofu taint null_resource.remove_and_upload_to_s3
$ tofu apply -auto-approve
```
