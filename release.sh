#!/bin/bash
set -eu
NAME="$1"
[ -n "$NAME" ] || {
	echo "The project name has to be provided. Are you sure that you set PROJECT_NAME in .gitlab-ci.yml?" >&2
	exit 1
}

VERSION="$(echo "${CI_COMMIT_TAG}" | sed -nE 's/v([0-9]+)\.([0-9]+)\.([0-9]+).*/\1.\2.\3/p')"
CHANGELOG="$(awk '
		BEGIN {
			flag = 0
		}
		/^## / {
			if (!flag) {
				flag = 1
				next
			} else
				exit
		}
		flag {
			print
		}
	' CHANGELOG.md)"

declare -a args
for dist in "$NAME"-*.tar.gz "$NAME"-*.tar.xz "$NAME"-*.zip; do
	URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/$NAME/${VERSION}/${dist}"
	curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file "${dist}" "${URL}"
	args+=("--assets-link" "{\"name\":\"${dist}\",\"url\":\"${URL}\"}")
done

release-cli create \
	--name "Release ${CI_COMMIT_TAG#v}" \
	--tag-name "$CI_COMMIT_TAG" \
	--description "$CHANGELOG" \
	"${args[@]}"
