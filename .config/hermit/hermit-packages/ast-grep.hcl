description = "Pinned ast-grep binary for structural code search and lint."
binaries = ["ast-grep"]

platform "linux" {
  source = "https://github.com/ast-grep/ast-grep/releases/download/0.45.1/app-x86_64-unknown-linux-gnu.zip"
}

platform "linux" "arm64" {
  source = "https://github.com/ast-grep/ast-grep/releases/download/0.45.1/app-aarch64-unknown-linux-gnu.zip"
}

version "0.45.1" {}

sha256sums = {
  "https://github.com/ast-grep/ast-grep/releases/download/0.45.1/app-x86_64-unknown-linux-gnu.zip": "76fb6555be6734fb5057dba8d2fb756430f374bb9e1af694cf1ce00e13238d63",
  "https://github.com/ast-grep/ast-grep/releases/download/0.45.1/app-aarch64-unknown-linux-gnu.zip": "9ee7ec49aada3dc05135d21977af089a33fc3154ada25bab102daca90b5098f2",
}
