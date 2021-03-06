# Copyright 2019 The Jetstack cert-manager contributors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@io_bazel_rules_go//go:def.bzl", "go_library")
load("@io_k8s_repo_infra//defs:go.bzl", "go_genrule")

def openapi_library(name, tags, srcs, go_prefix, openapi_targets = [], openapi_extra_targets = [], dependency_targets = []):
    deps = [
        "@com_github_go_openapi_spec//:go_default_library",
        "@io_k8s_kube_openapi//pkg/common:go_default_library",
    ] + ["//%s:go_default_library" % target for target in openapi_targets] + dependency_targets
    go_library(
        name = name,
        srcs = srcs + [":zz_generated.openapi"],
        importpath = go_prefix + "/docs/generated/reference/generate/go_openapi",
        tags = tags,
        deps = deps,
    )
    go_genrule(
        name = "zz_generated.openapi",
        srcs = ["//hack/boilerplate:boilerplate.go.txt"],
        outs = ["zz_generated.openapi.go"],
        # In order for vendored dependencies to be imported correctly,
        # the generator must run from the repo root inside the generated GOPATH.
        # All of bazel's $(location)s are relative to the original working directory, however,
        # so we must save it first.
        cmd = " ".join([
            "$(location @io_k8s_kube_openapi//cmd/openapi-gen)",
            "--v 1",
            "--logtostderr",
            "--go-header-file $(location //hack/boilerplate:boilerplate.go.txt)",
            "--output-file-base zz_generated.openapi",
            "--output-package " + go_prefix + "/docs/generated/reference/generate/go_openapi",
            "--input-dirs " + ",".join([go_prefix + "/" + target for target in openapi_targets] + openapi_extra_targets),
            "&& cp $$GOPATH/src/" + go_prefix + "/docs/generated/reference/generate/go_openapi/zz_generated.openapi.go $(location :zz_generated.openapi.go)",
        ]),
        go_deps = deps,
        tools = ["@io_k8s_kube_openapi//cmd/openapi-gen"],
    )
