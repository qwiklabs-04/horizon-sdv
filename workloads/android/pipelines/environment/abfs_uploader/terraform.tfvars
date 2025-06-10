project_id               = "sdvc-2108202401"
region                   = "europe-west1"
zone                     = "europe-west1-d"
alert_notification_email = "wojciech.kobryn@accenture.com"

abfs_gerrit_uploader_count            = 1
abfs_gerrit_uploader_machine_type     = "n2d-standard-4"
abfs_gerrit_uploader_datadisk_size_gb = "1024"
abfs_gerrit_uploader_datadisk_type    = "pd-balanced"
abfs_docker_image_uri                 = "europe-docker.pkg.dev/abfs-binaries/abfs-containers-alpha/abfs-alpha:latest"
abfs_gerrit_uploader_manifest_server  = "android.googlesource.com"
abfs_gerrit_uploader_git_branch       = ["main"]
abfs_manifest_file                    = "default.xml"
abfs_license                          = ""
