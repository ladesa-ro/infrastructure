description = "Pinned zizmor binary for GitHub Actions security analysis."
binaries = ["zizmor"]

platform "linux" {
  source = "https://github.com/zizmorcore/zizmor/releases/download/v1.29.0/zizmor-x86_64-unknown-linux-gnu.tar.gz"
}

platform "linux" "arm64" {
  source = "https://github.com/zizmorcore/zizmor/releases/download/v1.29.0/zizmor-aarch64-unknown-linux-gnu.tar.gz"
}

version "1.29.0" {}

sha256sums = {
  "https://github.com/zizmorcore/zizmor/releases/download/v1.29.0/zizmor-x86_64-unknown-linux-gnu.tar.gz": "dd96df044a6e8538d5f423790f453bdd03d49e5b2bcc38214acc41a2f1297839",
  "https://github.com/zizmorcore/zizmor/releases/download/v1.29.0/zizmor-aarch64-unknown-linux-gnu.tar.gz": "415eaa7c0a06479a701b8e44a3e812c1047decc848ec4bede7bd6bbf49f22d20",
}
