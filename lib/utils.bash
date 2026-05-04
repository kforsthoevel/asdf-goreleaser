#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/goreleaser/goreleaser"
TOOL_NAME="goreleaser"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		grep -v nightly |
		sed 's/^v//'
}

list_all_versions() {
	list_github_tags
}

get_arch() {
	local arch
	arch=$(uname -m | tr '[:upper:]' '[:lower:]')
	case ${arch} in
	arm64 | aarch64) arch='arm64' ;;
	x86_64) arch='x86_64' ;;
	i386) arch='i386' ;;
	armv6*) arch='arm6' ;;
	esac
	echo "${arch}"
}

get_platform() {
	local plat
	plat=$(uname | tr '[:upper:]' '[:lower:]')
	case ${plat} in
	darwin) plat='Darwin' ;;
	linux) plat='Linux' ;;
	mingw* | msys* | cygwin*) plat='Windows' ;;
	esac
	echo "${plat}"
}

get_ext() {
	if [ "$(get_platform)" = "Windows" ]; then
		echo "zip"
	else
		echo "tar.gz"
	fi
}

get_download_url() {
	local version="$1"
	local arch
	arch="$(get_arch)"
	local platform
	platform="$(get_platform)"
	local ext
	ext="$(get_ext)"
	echo "$GH_REPO/releases/download/v${version}/goreleaser_${platform}_${arch}.${ext}"
}

download_release() {
	local version="$1"
	local filename="$2"
	local url
	url="$(get_download_url "$version")"

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp "$ASDF_DOWNLOAD_PATH/$TOOL_NAME" "$install_path/$TOOL_NAME"
		chmod +x "$install_path/$TOOL_NAME"

		test -x "$install_path/$TOOL_NAME" || fail "Expected $install_path/$TOOL_NAME to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
