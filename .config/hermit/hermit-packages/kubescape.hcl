description = "Pinned kubescape binary for Kubernetes security posture scanning."
binaries = ["kubescape"]

platform "linux" {
  source = "https://github.com/kubescape/kubescape/releases/download/v4.0.12/kubescape_4.0.12_linux_amd64.tar.gz"
}

platform "linux" "arm64" {
  source = "https://github.com/kubescape/kubescape/releases/download/v4.0.12/kubescape_4.0.12_linux_arm64.tar.gz"
}

version "4.0.12" {}

sha256sums = {
  "https://github.com/kubescape/kubescape/releases/download/v4.0.12/kubescape_4.0.12_linux_amd64.tar.gz": "707aec6c708b7e90c1aeba71d9f7ce8050a03a84c6c146227d8c050e8155a7bc",
  "https://github.com/kubescape/kubescape/releases/download/v4.0.12/kubescape_4.0.12_linux_arm64.tar.gz": "b7b1b42d5ded8d805ee4ba7e2cf9146989a6ec9d27e94266644d9948e102ed10",
}
