#!/bin/bash

CLOSURE_HOME=/opt/node_modules
#CLOSURE_LIBRARY="${CLOSURE_HOME}/closure-library"
CLOSURE_LIBRARY="${CLOSURE_HOME}/google-closure-library"

# Find how far you need to back up to get from base.js to the root of the file system
BASE_JS_DEPTH=$((`echo ${CLOSURE_HOME} | grep -o "/" | wc -l | sed s/\ //g` + 3))
BASE_JS_PATH_TO_ROOT=""
for ((i=0; i<BASE_JS_DEPTH; i++))
do
  BASE_JS_PATH_TO_ROOT="${BASE_JS_PATH_TO_ROOT}../"
done

# Figure out what directory this script is in
ABSPATH="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
DIRECTORY=`dirname "$ABSPATH"`

# Combine them
ROOT_WITH_PREFIX="${BASE_JS_PATH_TO_ROOT%?}${DIRECTORY}"

# root_with_prefix must be relative to base.js
# CMD="${CLOSURE_LIBRARY}/closure/bin/build/depswriter.py \
#   --root_with_prefix=\"frontend/js ${ROOT_WITH_PREFIX}\" \
#   > frontend/js/deps.js"
CMD="${CLOSURE_LIBRARY}/closure/bin/build/depswriter.py \
  --root_with_prefix=\"backoffice/js ${ROOT_WITH_PREFIX}\" \
  > backoffice/js/deps.js"

eval ${CMD}
