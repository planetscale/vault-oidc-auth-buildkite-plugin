# Vault OIDC Authentication Buildkite Plugin

Authenticate to Hashicorp Vault with Buildkite OIDC (JWT) tokens.

In early 2023 Buildkite began offering per-pipeline OIDC tokens. These short-lived
tokens can be used to authenticate individual pipeline jobs to a Vault instance.

## Example

Add the following to your `pipeline.yml`:

```yaml
steps:
  - command: ./run_build.sh
    plugins:
      - planetscale/vault-oidc-auth#v1.1.1:
          vault_addr: "https://my-vault-server"  # required.
          path: auth/buildkite                   # optional. default "auth/buildkite"
          role: some-role                        # optional. default "$BUILDKITE_PIPELINE_SLUG"
          audience: vault                        # optional. default "vault"
          env_prefix: DEV_                       # optional. default "". (prefix to add to exported env variable names)
          set_vault_addr: false                  # optional. default "true". (set VAULT_ADDR env var to the value of 'vault_addr')
```

If authentication is successful a `VAULT_TOKEN` is added to the environment, as well as `VAULT_ADDR` if `set_vault_addr` is true.

Setting the `env_prefix` will add a prefix to the exported `VAULT_TOKEN` and `VAULT_ADDR` environment variables, eg: `enf_prefix: PROD_` will result in `PROD_VAULT_TOKEN` and `PROD_VAULT_ADDR`.

## Vault Configuration

Configure an instance of the [JWT](https://developer.hashicorp.com/vault/docs/auth/jwt) Vault auth backend at `auth/buildkite`:

```console
vault auth enable -path=buildkite jwt
vault write auth/buildkite/config jwks_url=https://agent.buildkite.com/.well-known/jwks
```

Get your Buildkite organization ID from the [GraphQL console](https://buildkite.com/user/graphql/console):

```
query getOrganizationID {organization(slug: "planetscale") {uuid}}
```

Create an auth role for a pipeline including the organization ID from above. Do this for each pipeline you wish to authenticate to Vault:

```console
vault write auth/buildkite/role/my-repo -<<EOF
{
  "bound_audiences": ["vault"],
  "policies": ["default"],
  "user_claim": "pipeline_slug",
  "bound_claims": {
    "organization_id": ["ORG_ID_GOES_HERE"],
    "pipeline_slug": "my-repo"
  },
  "role_type": "jwt",
  "token_type": "batch",
  "token_explicit_max_ttl": "2h"
}
EOF
```

## Developing

To run the linters:

```shell
docker-compose run --rm lint-shellcheck
docker-compose run --rm lint-plugin
```

To run the tests:

```shell
docker-compose run --rm tests
```

## Contributing

1. Fork the repo
2. Make the changes
3. Run the tests
4. Commit and push your changes
5. Send a pull request
