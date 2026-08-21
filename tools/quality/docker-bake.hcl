group "default" {
  targets = ["actionlint", "shellcheck", "zizmor", "python-lint", "kubeconform", "node-tools", "ast-grep", "kubescape"]
}

target "base" {
  context    = "."
  dockerfile = "tools/quality/Containerfile"
  target     = "base"
}

target "actionlint" {
  inherits   = ["base"]
  target     = "actionlint"
  tags       = ["infra-quality/actionlint:local"]
  cache-from = ["type=gha,scope=infra-quality-actionlint"]
  cache-to   = ["type=gha,scope=infra-quality-actionlint,mode=max"]
}

target "shellcheck" {
  inherits   = ["base"]
  target     = "shellcheck"
  tags       = ["infra-quality/shellcheck:local"]
  cache-from = ["type=gha,scope=infra-quality-shellcheck"]
  cache-to   = ["type=gha,scope=infra-quality-shellcheck,mode=max"]
}

target "zizmor" {
  inherits   = ["base"]
  target     = "zizmor"
  tags       = ["infra-quality/zizmor:local"]
  cache-from = ["type=gha,scope=infra-quality-zizmor"]
  cache-to   = ["type=gha,scope=infra-quality-zizmor,mode=max"]
}

target "python-lint" {
  inherits   = ["base"]
  target     = "python-lint"
  tags       = ["infra-quality/python-lint:local"]
  cache-from = ["type=gha,scope=infra-quality-python-lint"]
  cache-to   = ["type=gha,scope=infra-quality-python-lint,mode=max"]
}

target "kubeconform" {
  inherits   = ["base"]
  target     = "kubeconform"
  tags       = ["infra-quality/kubeconform:local"]
  cache-from = ["type=gha,scope=infra-quality-kubeconform"]
  cache-to   = ["type=gha,scope=infra-quality-kubeconform,mode=max"]
}

target "node-tools" {
  inherits   = ["base"]
  target     = "node-tools"
  tags       = ["infra-quality/node-tools:local"]
  cache-from = ["type=gha,scope=infra-quality-node-tools"]
  cache-to   = ["type=gha,scope=infra-quality-node-tools,mode=max"]
}

target "ast-grep" {
  inherits   = ["base"]
  target     = "ast-grep"
  tags       = ["infra-quality/ast-grep:local"]
  cache-from = ["type=gha,scope=infra-quality-ast-grep"]
  cache-to   = ["type=gha,scope=infra-quality-ast-grep,mode=max"]
}

target "kubescape" {
  inherits   = ["base"]
  target     = "kubescape"
  tags       = ["infra-quality/kubescape:local"]
  cache-from = ["type=gha,scope=infra-quality-kubescape"]
  cache-to   = ["type=gha,scope=infra-quality-kubescape,mode=max"]
}
