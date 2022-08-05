# In this file we build the various lambdas zips.
# This is probably not ideal in real-world projects, we want to get these zips from somewhere
# (build artifacts of another project), but to keep things simple we build them here.

locals {
  src_folder  = var.python_package_path
  dist_folder = "${path.root}/../dist"

  scraper_source_files = {
    for filename in setunion(
      fileset(local.src_folder, "setup.py"),
      fileset(local.src_folder, "${var.package_name}/**/*.py"),
    ) :
    filename => filemd5("${local.src_folder}/${filename}")
  }
}

resource "random_uuid" "scraper_code_random_uuid" {
  keepers = local.scraper_source_files
}

resource "null_resource" "scraper_code" {
  provisioner "local-exec" {
    command = <<EOT
        TARGET=${local.dist_folder}/scraper_${var.package_name}_${random_uuid.scraper_code_random_uuid.result}
        python -m pip install --target $TARGET ${var.python_package_path}
    EOT
  }

  triggers = local.scraper_source_files
}

data "archive_file" "scraper_code_zip" {
  type        = "zip"
  source_dir  = "${local.dist_folder}/scraper_${var.package_name}_${random_uuid.scraper_code_random_uuid.result}"
  output_path = "${local.dist_folder}/scraper_${var.package_name}_${random_uuid.scraper_code_random_uuid.result}.zip"

  depends_on = [null_resource.scraper_code]
}
