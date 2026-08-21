description = "Node.js runtime used to run jscpd and cspell in the quality tooling image."
binaries = ["bin/node", "bin/npm", "bin/npx"]
strip = 1

platform "linux" {
  source = "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz"
}

platform "linux" "arm64" {
  source = "https://nodejs.org/dist/v${version}/node-v${version}-linux-arm64.tar.xz"
}

version "24.18.0" {}

sha256sums = {
  "https://nodejs.org/dist/v24.18.0/node-v24.18.0-linux-x64.tar.xz": "55aa7153f9d88f28d765fcdad5ae6945b5c0f98a36881703817e4c450fa76742",
  "https://nodejs.org/dist/v24.18.0/node-v24.18.0-linux-arm64.tar.xz": "58c9520501f6ae2b52d5b210444e24b9d0c029a58c5011b797bc1fe7105886f6",
}
