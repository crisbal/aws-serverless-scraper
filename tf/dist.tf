# In this file we build the various lambdas zips.
# This is probably not ideal in real-world projects, we want to get these zips from somewhere
# (build artifacts of another project), but to keep things simple we build them here.

locals {
  src_folder  = "${path.module}/../src"
  dist_folder = "${path.module}/../dist"

  files_scrape_listing = {
    for filename in setunion(
      fileset(local.src_folder, "scrape_listing/setup.py"),
      fileset(local.src_folder, "scrape_listing/scrape_listing/**/*.py"),
    ) :
    filename => filemd5("${local.src_folder}/${filename}")
  }
}

resource "random_uuid" "lamda_code_random_uuid_scrape_listing" {
  keepers = local.files_scrape_listing
}

resource "null_resource" "create_lambda_code_scrape_listing" {
  provisioner "local-exec" {
    command = <<EOT
        TARGET=${local.dist_folder}/lambda_code_scrape_listing_${random_uuid.lamda_code_random_uuid_scrape_listing.result}
        python -m pip install --target $TARGET ${local.src_folder}/scrape_listing
    EOT
  }

  triggers = local.files_scrape_listing
}

data "archive_file" "lambda_code_scrape_listing_zip" {
  type        = "zip"
  source_dir  = "${local.dist_folder}/lambda_code_scrape_listing_${random_uuid.lamda_code_random_uuid_scrape_listing.result}"
  output_path = "${local.dist_folder}/lambda_code_scrape_listing.zip"

  depends_on = [null_resource.create_lambda_code_scrape_listing]
}
