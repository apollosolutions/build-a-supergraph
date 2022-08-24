#/bin/bash
set -euo pipefail

APOLLO_KEY=${APOLLO_KEY:-""}
CLUSTER_PREFIX=${CLUSTER_PREFIX:-"apollo-supergraph-k8s"}
ACCOUNT_ID=${ACCOUNT_ID:-""}
GRAPH_ID=$CLUSTER_PREFIX-$(echo $RANDOM | sha1sum | head -c 6)
HEADER=${HEADER:-""}

if [[ "$APOLLO_KEY" == "" ]]; then
  echo "Must provide APOLLO_KEY in environment" 1>&2
  exit 1
fi

if [[ $(which jq) == "" ]]; then
  echo "please install jq before continuing: https://stedolan.github.io/jq/"
  exit 1
fi

# if an account id is not provided, fetch it from Studio
if [[ $ACCOUNT_ID == "" ]]; then
  ACCOUNT_ARGS=(
    --silent
    --header "x-api-key: $APOLLO_KEY"
    --header 'content-type: application/json'
    --header 'apollographql-client-name: build-a-supergraph'
    --url 'https://graphql.api.apollographql.com/api/graphql'
    --data '{"query":"{ me { ... on User { memberships { permission account { id } } } } }"}'
  )

  if [[ $HEADER != "" ]]; then
    ACCOUNT_ARGS+=(--header "$HEADER")
  fi

  ACCOUNT_RESP=$(curl "${ACCOUNT_ARGS[@]}")
  ACCOUNT_COUNT=$(echo $ACCOUNT_RESP | jq -r ".data.me.memberships | length")

  # if more than one account exists, exit early
  if [[ $ACCOUNT_COUNT > 1 ]]; then
    echo "Apollo Studio returned more than one account."
    echo "Specify an account ID with ACCOUNT_ID=myaccount $0"
    echo "Accounts: "
    echo $(echo $ACCOUNT_RESP | jq -r ".data.me.memberships[].account.id")
    exit 1
  fi

  ACCOUNT_ID=$(echo $ACCOUNT_RESP | jq -r ".data.me.memberships[0].account.id")
fi

echo "Creating graph $GRAPH_ID on account $ACCOUNT_ID..."

CREATE_ARGS=(
  --silent
  --header "x-api-key: $APOLLO_KEY"
  --header 'content-type: application/json'
  --header 'apollographql-client-name: build-a-supergraph'
  --url 'https://graphql.api.apollographql.com/api/graphql'
  --data "{\"query\":\"mutation CreateGraph(\$accountId: ID!, \$newServiceId: ID!, \$name: String, \$onboardingArchitecture: OnboardingArchitecture) { newService(accountId: \$accountId, id: \$newServiceId, name: \$name, onboardingArchitecture: \$onboardingArchitecture) { id apiKeys { token } } }\",\"variables\":{\"accountId\":\"$ACCOUNT_ID\",\"newServiceId\":\"$GRAPH_ID\",\"name\":\"Build a Supergraph $(date +"%Y-%m-%d")\",\"onboardingArchitecture\":\"SUPERGRAPH\"}}"
)

if [[ $HEADER != "" ]]; then
  CREATE_ARGS+=(--header "$HEADER")
fi

CREATE_RESP=$(curl "${CREATE_ARGS[@]}")

IS_SUCCESS=$(echo $CREATE_RESP | jq -r ".data.newService")
if [[ "$IS_SUCCESS" == "null" ]]; then
  echo "Error creating graph"
  echo $CREATE_RESP | jq .
  exit 1
fi

GRAPH_KEY=$(echo $CREATE_RESP | jq -r ".data.newService.apiKeys[0].token")

echo ''
echo "New terraform variables:"
echo ''
echo "apollo_key      = \"$GRAPH_KEY\""
echo "apollo_graph_id = \"$GRAPH_ID\""
echo ''
