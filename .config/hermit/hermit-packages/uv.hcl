description = "uv is used to materialize the isolated Python quality tools."
binaries = ["*/uv", "*/uvx"]

platform "linux" {
  source = "https://github.com/astral-sh/uv/releases/download/${version}/uv-x86_64-unknown-linux-gnu.tar.gz"
}

platform "linux" "arm64" {
  source = "https://github.com/astral-sh/uv/releases/download/${version}/uv-aarch64-unknown-linux-gnu.tar.gz"
}

version "0.12.1" {}

sha256sums = {
  "https://github.com/astral-sh/uv/releases/download/0.12.1/uv-x86_64-unknown-linux-gnu.tar.gz": "90b2f223fb69d19db49e117da601f64978593417988530aa733d456141b4bcbb",
  "https://github.com/astral-sh/uv/releases/download/0.12.1/uv-aarch64-unknown-linux-gnu.tar.gz": "769d373e146692c639b5fbaae33b331c297a32e03d30448772051902df52bbf4",
}
