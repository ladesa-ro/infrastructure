description = "Pinned kubeconform binary for validating Kubernetes manifests against schema."
binaries = ["kubeconform"]

platform "linux" {
  source = "https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz"
}

platform "linux" "arm64" {
  source = "https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-arm64.tar.gz"
}

version "0.8.0" {}

sha256sums = {
  "https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz": "9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883",
  "https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-arm64.tar.gz": "1f53fc8e81258197a35e8603054162a5af1de8c5af13746c71ab680d9534ed87",
}
