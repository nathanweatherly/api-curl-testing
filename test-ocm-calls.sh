if [[ -z "$OCM_ACCESS_TOKEN" ]]; then
    echo "Please set OCM_ACCESS_TOKEN (https://cloud.redhat.com/openshift/token)"
    exit 1
fi

if [[ -z "$SLEEP_IN_MINUTES" ]]; then
    SLEEP_IN_MINUTES=10
    echo "Setting SLEEP_IN_MINUTES to default (${SLEEP_IN_MINUTES} minute(s))"
fi

SLEEP_IN_SECONDS=$(( SLEEP_IN_MINUTES * 60 ))

timestamp() {
  date +"%m-%d-%Y--%T"
}

BASE_RESULTS_DIR_PATH="$(dirname "${BASH_SOURCE[0]}")/results"

OUTPUT_DIR_PATH="$BASE_RESULTS_DIR_PATH/outputs-starting-at-$(timestamp)"

REFRESH_TOKEN_FILE_NAME="refresh_token_response.json"
CLUSTERS_RESPONSE_FILE_NAME="clusters_response.json"
SUBSCRIPTIONS_RESPONSE_FILE_NAME="subscriptions_response.json"

mkdir $OUTPUT_DIR_PATH

cd $OUTPUT_DIR_PATH

while :
do
	echo "Press [CTRL+C] to stop..."

    START_TIME=$(timestamp)

    mkdir $START_TIME

    REFRESH_TOKEN_RESPONSE=$(curl --location --request POST 'https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=refresh_token' \
    --data-urlencode 'client_id=cloud-services' \
    --data-urlencode "refresh_token=$OCM_ACCESS_TOKEN")

    echo $REFRESH_TOKEN_RESPONSE > $START_TIME/$REFRESH_TOKEN_FILE_NAME

    REFRESH_TOKEN=$(echo "$REFRESH_TOKEN_RESPONSE" | jq -r .access_token)

    CLUSTERS_RESPONSE=$(curl --location --request GET 'https://api.openshift.com/api/clusters_mgmt/v1/clusters' \
    --header "Authorization: Bearer $REFRESH_TOKEN")

    echo $CLUSTERS_RESPONSE > $START_TIME/$CLUSTERS_RESPONSE_FILE_NAME

    SUBSCRIPTIONS_RESPONSE=$(curl --location --request GET 'https://api.openshift.com/api/accounts_mgmt/v1/subscriptions' \
    --header "Authorization: Bearer $REFRESH_TOKEN")

    echo $SUBSCRIPTIONS_RESPONSE > $START_TIME/$SUBSCRIPTIONS_RESPONSE_FILE_NAME
    
    echo
    echo "Sleeping for $SLEEP_IN_MINUTES minutes..."
    sleep $SLEEP_IN_SECONDS
    echo

done

