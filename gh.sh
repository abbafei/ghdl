#!/bin/sh


WGET_CMD="wget -O -"




get_iteminfo(){
	local GH_USER="$1"
	local GH_ITEMTYPE="$2"

	echo "$($WGET_CMD "https://api.github.com/users/$GH_USER/$GH_ITEMTYPE")"
}


get_index(){
	local GH_ITEMTYPE="$1"
	local GH_ITEMINFO="$2"
	
	local LEN="$(echo "$GH_ITEMINFO" | jq "length")"
	local i=0
	while [ "$i" -lt "$LEN" ]; do
		echo "$i"
		local i="$(expr "$i" + 1)"
	done
}


get_info_id(){
	local GH_ITEMTYPE="$1"
	local GH_ITEMINFO="$2"
	local GH_ITEMADDR="$3"

	echo "$(echo "$GH_ITEMINFO" | jq ".[$GH_ITEMADDR]")"
}


get_itemspec(){
	local GH_ITEMTYPE="$1"
	local GH_INFO="$2"

	case "$GH_ITEMTYPE" in repos) local NAME_KEY='name';; gists) local NAME_KEY='id';; esac
	echo "$(echo "$GH_INFO" | jq --raw-output ".$NAME_KEY")"
}


get_info_name(){
	local GH_ITEMTYPE="$1"
	local GH_ITEMINFO="$2"
	local GH_SPEC="$3"

	for i in $(get_index "$GH_ITEMTYPE" "$GH_ITEMINFO"); do
		local I_NAME="$(get_itemspec "$GH_ITEMTYPE" "$(get_info_id "$GH_ITEMTYPE" "$GH_ITEMINFO" "$i")")"
		if [ "$I_NAME" = "$GH_SPEC" ]; then
			echo "$(get_info_id "$GH_ITEMTYPE" "$GH_ITEMINFO" "$i")"
			return
		fi
	done
	return 1
}


get_item(){
	(
		GH_ITEMTYPE="$1"
		GH_INFO="$2"

		GH_SPEC="$(get_itemspec "$GH_ITEMTYPE" "$GH_INFO")"
		mkdir -p "$GH_SPEC"
		cd "$GH_SPEC"
		case "$GH_ITEMTYPE" in repos) local NAME_KEY='git_url';; gists) local NAME_KEY='git_pull_url';; esac
		git clone "$(echo "$GH_INFO" | jq --raw-output ".$NAME_KEY" )" code
		(cd code; git pull --all)

		if [ "$GH_ITEMTYPE" = "repos" ] && [ "$(echo "$GH_INFO" | jq ".has_wiki")" = "true" ]; then
			git clone "$(echo "$GH_INFO" | jq --raw-output ".clone_url" | sed -e 's/\.git$//' ).wiki" wiki
			(if [ ! -z "$(find . -name wiki -type d)" ]; then cd wiki; git status 2>&1 >/dev/null && git pull --all; fi)
		fi 
	)
}


get_items(){
	local GH_ITEMTYPE="$1"
	local GH_ITEMINFO="$2"

	for i in $(get_index "$GH_ITEMTYPE" "$GH_ITEMINFO"); do
		GH_INFO="$(get_info_id "$GH_ITEMTYPE" "$GH_ITEMINFO" "$i")"
		GH_SPEC="$(get_itemspec "$GH_ITEMTYPE" "$GH_INFO")"
		(
			mkdir -p "$GH_ITEMTYPE"
			cd "$GH_ITEMTYPE"
			get_item "$GH_ITEMTYPE" "$GH_INFO"
		)
	done
}



GH_USER="$1"
GH_ITEMTYPE="$2"
GH_ITEM="$3"

HELPMSG="
Usage: $0 user [itemtype [item]]
	WARNING: script input, and api results, are not escaped
 - itemtype=(repos|gists)
	If provided, only download items of that type.
 - item=<itemspec>
    If provided, only download that item.
"


if [ "$1" = "--help" ] || [ -z "$GH_USER" ]; then
	echo "$HELPMSG"
else
	(
		mkdir -p "$GH_USER"
		cd "$GH_USER"
		if [ -z "$GH_ITEMTYPE" ]; then
			for GH_ITEMTYPE in 'gists' 'repos'; do
				GH_ITEMINFO="$(get_iteminfo "$GH_USER" "$GH_ITEMTYPE")"
				get_items "$GH_ITEMTYPE" "$GH_ITEMINFO"
			done
		else
			if [ -z "$GH_ITEM" ]; then
				GH_ITEMINFO="$(get_iteminfo "$GH_USER" "$GH_ITEMTYPE")"
				get_items "$GH_ITEMTYPE" "$GH_ITEMINFO"
			else
				(
					mkdir -p "$GH_ITEMTYPE"
					cd "$GH_ITEMTYPE"
					get_item "$GH_ITEMTYPE" "$(get_info_name "$GH_ITEMTYPE" "$(get_iteminfo "$GH_USER" "$GH_ITEMTYPE")" "$GH_ITEM")"
				)
			fi
		fi
	)
fi
