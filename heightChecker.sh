#!/bin/bash

####################################################################################################################
# File name: heightChecker.sh                                                                                      #
# Author: cc001                                                                                                    #
# Last modified: 2016-10-13                                                                                        #
#                                                                                                                  #
# Script to list the current blockheights and Lisk versions of                                                     #
# nodes you want to monitor. Add your own nodes as you wish.                                                       #
# The Color shows if the height and version is uptodate.                                                           #
#                                                                                                                  #
# Script provided by delegate cc001 6787154358850114730L                                                           #
# If you like this script, please vote for me as Delegate, Thanks!                                                 #
#                                                                                                                  #
####################################################################################################################


## Mainnet ##
nodesMainnet=(
  # Examples. Use whatever you want to monitor
  http://wallet.shiftnrg.nl:9305
  http://wallet2.shiftnrg.nl:9305
  http://wallet3.shiftnrg.nl:9305
  "-" # Used only for optical separation
  http://explorernode.shiftnrg.nl:9305
  http://explorernode2.shiftnrg.nl:9305
  "-"
  http://seatrips.shiftnrg.nl:9305
  http://seatrips2.shiftnrg.nl:9305
  http://seatrips3.shiftnrg.nl:9305
  "-"
  http://shiftcommunitywallet.shiftnrg.nl:9305
  )
## Testnet ##
nodesTestnet=(
  http://seatripstestnet.shiftnrg.nl:9405
  http://seatripstestnet2.shiftnrg.nl:9405
)

# used for coloring the heights
okHeightDiff=2 # If difference is bigger -> YELLOW
maxHeightDiff=3 # If the difference is bigger -> RED

# widths of the columns
textcol=45
numcol=8
versioncol=7

# shown text when no connection is possible
stringNA="NA"

# seconds to wait if no answer
connectTimeout=2

# used colors.
GREEN=$'\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC=$'\033[0m'

#############################################################
# DON'T MODIFY STUFF BELOW HERE (except you know what you do)
#############################################################

findmax() {
  local max=0
  for i in $@; do
    if (( $i > $max )); then
      max=$i
    fi
  done
  echo $max
}

getHeight() {
  answer=`curl -s --connect-timeout $connectTimeout "$1/api/loader/status/sync" | grep "height"`
  if [ -z $1 ]; then
    height=""
  elif [ ! -z $answer ]; then
    height=`echo $answer | jq '.height'`
  else
    height="$stringNA"
  fi
  echo $height
}

getVersion() {
  answer=`curl -s --connect-timeout $connectTimeout "$1/api/peers/version" | grep "version"`
  if [ -z $1 ]; then
    version=""
  elif [ ! -z "$answer" ]; then
    version=`echo $answer | jq '.version' | cut -d '"' -f 2 `
  else
    version="$stringNA"    
  fi
  echo $version
}

showBlockheights() {
  if [ "$1" == "MAINNET" ]; then
    nodes="${nodesMainnet[@]} $2"
  elif [ "$1" == "TESTNET" ]; then
    nodes="${nodesTestnet[@]} $2"
  elif [ "$1" == "ARGUMENTS" ]; then
    nodes=$2
  fi
  
  blockHeights=()
  versions=()
  counter=0
  for i in $nodes
  do
    if [ -z $i ] || [ "$i" == "-" ]; then
      blockHeights+=("")
      versions+=("")
    else
      blockHeights+=($(getHeight $i))
      versions+=($(getVersion $i))
    fi
    counter=$((counter + 1))
  done
  
  maxHeight=$(findmax ${blockHeights[@]})
  
  IFS=$'\n' sorted=($(sort -r <<<"${versions[*]}"))
  unset IFS
  i=0
  maxVersion=${sorted[$i]}
  while [ "$maxVersion" == $stringNA ]
  do
    i=$i+1
    maxVersion=${sorted[$i]}
  done

  printf "${YELLOW}------------------- $1 BLOCKHEIGHTS --------------------${NC}\n"
  printf "${GREEN}%-*s%*d  %-*s${NC}\n" $textcol "Highest block and version:" $numcol "$maxHeight" $versioncol "$maxVersion"
  printf "${YELLOW}%0.s-${NC}" $(seq 1 $(expr $textcol + $numcol + $versioncol + 1))
  printf "\n"

  counter=0
  for i in $nodes
  do
    index=$((counter++))
    height=${blockHeights[$index]}
    version=${versions[$index]}
    if [ "$height" == $stringNA ] || [ "$height" == "" ]; then
      diff=$maxHeightDiff
    else
      diff=$(expr $height - $maxHeight)
      if [ $diff -lt 0 ]
      then
        diff=$(expr $diff \* -1)
      fi
    fi
    if [ -z $i ]; then
      test=1 # do nothing
    elif [ $diff -lt $okHeightDiff ]; then
      color=${GREEN}
    elif [ $diff -lt $maxHeightDiff ]; then
      color=${YELLOW}
    else
      color=${RED}
    fi
    if [ -z $i ] || [ "$version" == "" ]; then
      test=1 # do nothing
    elif [ "$version" == $stringNA ]; then
      versioncolor=${RED}
    elif [ "$version" == "$maxVersion" ]; then
      versioncolor=${GREEN}
    else
      versioncolor=${RED}
    fi
    
    printf "%-*s$color%*s${NC}  $versioncolor%-*s${NC}\n" $textcol "$i" $numcol "$height" $versioncol $version
  done
  printf "\n"
}

clear
showBlockheights "MAINNET" "$@"
showBlockheights "TESTNET" "$@"

