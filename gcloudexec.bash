PROJECT="centered-seat-178501"
ZONE="us-central1-f"

# exec $2++ on $1
function gcloudexec {
    gcloud compute --project $PROJECT \
	   ssh --zone $ZONE $1 --command "${@:2}"
}

# exec all of $2++ on $1
function gcloudexecall {
    for comnd in "${@:2}"; do
	gcloudexec $1 "${comnd}"
    done
}
