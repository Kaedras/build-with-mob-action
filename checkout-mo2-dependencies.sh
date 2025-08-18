#!/bin/bash

set -e

Owner=""
Branch=""
DependenciesS=""

usage() {
  echo "Usage: $(basename $0) -Owner <owner> -Branch <branch> -Dependencies <dependencies>"
}

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -Owner)
      Owner="$2"
      shift 2
      ;;
    -Branch)
      Branch="$2"
      shift 2
      ;;
    -Dependencies)
      DependenciesS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      return 1
      ;;
  esac
done

if [ -z "$Owner" ] || [ -z "$Branch" ] || [ -z "$DependenciesS" ]; then
  echo "Error: Missing required parameters."
  usage
  exit 1
fi

switch_branch() {
  if [ $# -ne 1 ]; then
    echo "switch_branch: invalid parameter count"
    exit 1
  fi
  local Folder=$1
  local name="$(basename "$Folder")"

  pushd "$Folder" 1> /dev/null

  local remote="origin"

  if [ "$Owner" != "ModOrganizer2" ]; then

    remote="$Owner"
    url=$(git remote -v | grep ModOrganizer2 | head -1 | awk '{print $2}' | sed "s/ModOrganizer2/$Owner/")

    if git remote -v | grep -q "$Owner/"; then
      git remote set-url "$remote" "$url"
    else
      git remote add "$remote" "$url"
    fi

    # try to fetch
    if ! git fetch --depth 1 "$Owner" > /dev/null 2>&1; then
      echo "No remote $remote for $name found, falling back to ModOrganizer2."
      Owner="ModOrganizer2"
      remote="origin"
    fi

    if ! git checkout "$remote/$Branch" > /dev/null 2>&1; then
      echo "No branch $Owner/$Branch found for $name, staying on current branch."
    else
      echo "Switch to branch $Owner/$Branch for $name."
    fi

    # Restore previous directory
    popd 1> /dev/null

  fi
}

simpleRepositoryNames=("usvfs" "cmake_common")

# Create build directory
mkdir -p build
pushd build 1> /dev/null

echo "Initializing repositories... "
DependenciesS=$(echo "$DependenciesS" | tr ' ' '\n' | sort -u)
for repo in $DependenciesS; do
  fullname="$repo"
  # Check if the repository name is in the simple repository names list
  for value in "${simpleRepositoryNames[@]}"; do
    if [ "$value" == "$fullname" ]; then
      fullname="modorganizer-$fullname"
      break
    fi
  done

  git clone "https://github.com/ModOrganizer2/$fullname.git" "$repo"
done

echo "Switching branches... "
for dir in */; do
  if [ -d "$dir" ] && [ "$dir" != ".git/" ]; then
    echo "Switching branch for ${dir%/}..."
    switch_branch "$dir"
  fi
done

popd 1> /dev/null
