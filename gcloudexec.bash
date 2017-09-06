# exec $2++ on $1
function gcloudexec {
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" $1 --command "${@:2}"
}

# exec all of $2++ on $1
function gcloudexecall {
    for comnd in "${@:2}"; do
	gcloudexec $1 "${comnd}"
    done
}
