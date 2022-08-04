# In this file we build the various lambdas zips.
# This is probably not ideal in real-world projects, we want to get these zips from somewhere
# (build artifacts of another project), but to keep things simple we build them here.

locals {
  src_folder  = "${path.module}/../src"
  dist_folder = "${path.module}/../dist"

  files_scraper_lambdas = {
    for filename in setunion(
      fileset(local.src_folder, "scraper-lambdas/setup.py"),
      fileset(local.src_folder, "scraper-lambdas/scraper_lambdas/**/*.py"),
    ) :
    filename => filemd5("${local.src_folder}/${filename}")
  }
}

resource "random_uuid" "lamda_code_random_uuid_scraper_lambdas" {
  keepers = local.files_scraper_lambdas
}

resource "null_resource" "create_lambda_code_scraper_lambdas" {
  provisioner "local-exec" {
    command = <<EOT
        TARGET=${local.dist_folder}/lambda_code_scraper_lambdas_${random_uuid.lamda_code_random_uuid_scraper_lambdas.result}
        python -m pip install --target $TARGET ${local.src_folder}/scraper-lambdas
    EOT
  }

  triggers = local.files_scraper_lambdas
}

data "archive_file" "lambda_code_scraper_lambdas_zip" {
  type        = "zip"
  source_dir  = "${local.dist_folder}/lambda_code_scraper_lambdas_${random_uuid.lamda_code_random_uuid_scraper_lambdas.result}"
  output_path = "${local.dist_folder}/lambda_code_scraper_lambdas.zip"

  depends_on = [null_resource.create_lambda_code_scraper_lambdas]
}
