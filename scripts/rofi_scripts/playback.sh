#!/bin/bash

current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='  '

if [[ -z $@ ]]; then
	echo -e '  play\n  stop\n  next\n  prev\n  random\n  volume up\n  volume down\n  toggle controls\n  playlist'
else
	case "$@" in
		*play) mpc -q toggle;;
		*volume*)
			volume="$@"
			[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
			[[ ${volume##* } == up ]] && direction=+ || direction=-

			mpc -q volume $direction$((${multiplier:-1} * 5));;
		*playlist)
			indicator=''
			mpc playlist | awk '{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }';;
		*controls*)
			mpd=~/.orw/scripts/bar/mpd.sh
			mode=$(awk -F '=' '/^current_mode/ { if ($2 == "controls") print "song_info"; else print "controls"}' $mpd)
			sed -i "/^current_mode/ s/=.*/=$mode/" $mpd;;
		*-*)
			song="$@"
			~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}";;
		*)
			mpc -q ${@#* }

			if [[ ${@##* } == stop ]]; then
				bar_name=$(ps aux | awk -F '[- ]' \
					'!/awk/ && /generate_bar.* -m/ { for(f = 9; f <= NF; f++) if($f == "n") { print $(f + 1); exit } }')

				[[ $bar_name ]] && cat <<- EOF > ~/.config/orw/bar/fifos/$bar_name.fifo
					PROGRESSBAR
					SONG_INFO not playing
					MPD_VOLUME
				EOF
			fi
	esac
fi
