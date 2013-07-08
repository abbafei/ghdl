#!/bin/sh


WGET_CMD="wget -O -"


get_repo () {
	(
		REPO_INFO="$1"
		REPONAME="$(echo "$REPO_INFO" | jq --raw-output ".name" )"
		mkdir -p "$REPONAME"
		cd "$REPONAME"
		if [ true ]; then
			git clone "$(echo "$REPO_INFO" | jq --raw-output ".git_url" )" code && (cd code; git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pr/*' )
			(cd code; git pull --all)
		fi
		if [ "$(echo "$REPO_INFO" | jq ".has_wiki")" = "true" ]; then
			git clone "$(echo "$REPO_INFO" | jq --raw-output ".clone_url" | sed -e 's/\.git$//' ).wiki" wiki
			(cd wiki; git status 2>&1 >/dev/null && git pull --all)
		fi 
	)
}


get_gist () {
	(
		GIST_INFO="$1"
		GISTNAME="$(echo "$GIST_INFO" | jq --raw-output ".id" )"
		mkdir -p "$GISTNAME"
		cd "$GISTNAME"
		git clone "$(echo "$GIST_INFO" | jq --raw-output ".git_pull_url" )" code
		(cd code; git pull --all)
	)
}



get_repos () { (
	GH_USER="$1"
	GH_ITEMTYPE="$2"
	GH_ITEM="$3"
	
	mkdir -p "repos"
	cd "repos"
	if [ "$GH_ITEM" = "" ]; then
		GH_REPOINFO="$($WGET_CMD "https://api.github.com/users/$GH_USER/repos")"
		for i in $(echo "$GH_REPOINFO" | jq "keys | .[]" ); do
			get_repo "$(echo "$GH_REPOINFO" | jq ".[$i]")"
		done
	else
		get_repo "$($WGET_CMD "https://api.github.com/repos/$GH_USER/$GH_ITEM")"
	fi
) }



get_gists () { (
	GH_USER="$1"
	GH_ITEMTYPE="$2"
	GH_ITEM="$3"
	
	mkdir -p "gists"
	cd "gists"
	GH_GISTINFO="$($WGET_CMD "https://api.github.com/users/$GH_USER/gists")"
	for i in $(echo "$GH_GISTINFO" | jq "keys | .[]" ); do
		get_gist "$(echo "$GH_GISTINFO" | jq ".[$i]")"
	done
) }



GH_USER="$1"
GH_ITEMTYPE="$2"
GH_ITEM="$3"


if [ ! "$GH_USER" = "" ]; then (
	mkdir -p "$GH_USER"
	cd "$GH_USER"
	if [ "$GH_ITEMTYPE" = "gists" ]; then
		get_gists "$GH_USER" "$GH_ITEMTYPE" "$GH_ITEM"
	elif [ "$GH_ITEMTYPE" = "repos" ]; then
		get_repos "$GH_USER" "$GH_ITEMTYPE" "$GH_ITEM"
	else
		get_repos "$GH_USER" "$GH_ITEMTYPE" "$GH_ITEM"
		get_gists "$GH_USER" "$GH_ITEMTYPE" "$GH_ITEM"
	fi
) else
	echo "Usage [user] [itemtype] [item]
	WARNING: script input, and api results, are not escaped"
fi
