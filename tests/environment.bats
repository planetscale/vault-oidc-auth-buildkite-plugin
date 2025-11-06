#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# export VAULT_STUB_DEBUG=/dev/tty

@test "vault_addr is not set" {
  export BUILDKITE_PIPELINE_SLUG="foo"

  run bash -c "$PWD/hooks/environment && env"
  assert_success
  assert_output --partial "Skipping Vault authentication"

  unset BUILDKITE_PIPELINE_SLUG
}

@test "successful authentication with defaults" {
  export BUILDKITE_PIPELINE_SLUG="foo"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR="http://vault:8200"

  stub buildkite-agent \
    'oidc request-token --audience vault --claim "organization_id" : echo eyJfoobar'

  stub vault \
    'write -field=token -address=http://vault:8200 auth/buildkite/login role=foo jwt=eyJfoobar : echo s.mocktoken'

  run bash -c "source $PWD/hooks/environment && env"
  assert_success
  assert_output --partial "VAULT_TOKEN=s.mocktoken"

  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR
}

@test "successful authentication with overrides" {
  export BUILDKITE_PIPELINE_SLUG="foo"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR="http://vault:8200"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_PATH="auth/jwt"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_ROLE="bar"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_AUDIENCE="my-aud"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_SET_VAULT_ADDR="false"

  stub buildkite-agent \
    'oidc request-token --audience my-aud --claim "organization_id" : echo eyJfoobar'

  stub vault \
    'write -field=token -address=http://vault:8200 auth/jwt/login role=bar jwt=eyJfoobar : echo s.mocktoken'

  run bash -c "source $PWD/hooks/environment && env"
  assert_success
  assert_output --partial "VAULT_TOKEN=s.mocktoken"
  refute_output --regexp "^VAULT_ADDR=http://vault:8200$"

  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_PATH
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_ROLE
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_AUDIENCE
}

@test "env_prefix" {
  export BUILDKITE_PIPELINE_SLUG="foo"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR="http://vault:8200"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_ENV_PREFIX="FOO_"
  export BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_SET_VAULT_ADDR="true"

  stub buildkite-agent \
    'oidc request-token --audience vault --claim "organization_id" : echo eyJfoobar'

  stub vault \
    'write -field=token -address=http://vault:8200 auth/buildkite/login role=foo jwt=eyJfoobar : echo s.mocktoken'

  run bash -c "source $PWD/hooks/environment && env"
  assert_success
  assert_output --partial "FOO_VAULT_TOKEN=s.mocktoken"
  assert_output --partial "FOO_VAULT_ADDR=http://vault:8200"

  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_VAULT_ADDR
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_ENV_PREFIX
  unset BUILDKITE_PLUGIN_VAULT_OIDC_AUTH_SET_VAULT_ADDR
}
