// This file is only used for CI
// It will cache the dependencies for the setup-go action
// which is required to run https://github.com/toml-lang/toml-test

module github.com/watermarkhu/matlab-toml

go 1.24

require github.com/toml-lang/toml-test/v2 v2.1.0
