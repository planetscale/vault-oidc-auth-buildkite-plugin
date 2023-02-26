#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export VAULT_STUB_DEBUG=/dev/tty

@test "vault_addr is not set" {
  export BUILDKITE_PIPELINE_SLUG="foo"

  run bash -c "$PWD/hooks/environment"
  assert_success
  assert_output --partial "Skipping Vault authentication"

  unset BUILDKITE_PIPELINE_SLUG
}

@test "successful authentication with defaults" {
  export BUILDKITE_PIPELINE_SLUG="foo"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR="http://vault:8200"

  stub buildkite-agent \
    'oidc request-token --audience vault : echo eyJfoobar'

  stub vault \
    'write -field=token -address=http://vault:8200 auth/buildkite/login role=foo jwt=eyJfoobar : echo s.mocktoken'

  run bash -c "$PWD/hooks/environment"
  assert_success
  assert_output --partial "Successfully authenticated with Vault"

  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR
}

@test "successful authentication with overrides" {
  export BUILDKITE_PIPELINE_SLUG="foo"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR="http://vault:8200"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_PATH="auth/jwt"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_ROLE="bar"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_AUDIENCE="my-aud"

  stub buildkite-agent \
    'oidc request-token --audience my-aud : echo eyJfoobar'

  stub vault \
    'write -field=token -address=http://vault:8200 auth/jwt/login role=bar jwt=eyJfoobar : echo s.mocktoken'

  run bash -c "$PWD/hooks/environment"
  assert_success
  assert_output --partial "Successfully authenticated with Vault"

  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_PATH
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_ROLE
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_AUDIENCE
}
