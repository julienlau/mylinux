#!/usr/bin/env bash

verbose=0
URL=http://localhost:8000

for i in "$@"; do
    case $i in
        -u=*|--url=*)
            URL="${i#*=}"
            shift # past argument=value
            ;;
        -k=*|--key=*)
            KEY="${i#*=}"
            shift # past argument=value
            ;;
        -s=*|--secret=*)
            PASSWORD="${i#*=}"
            shift # past argument=value
            ;;
        -p=*|--path=*)
            MINIO_PATH="${i#*=}"
            shift # past argument=value
            ;;
        --verbose)
            verbose=1
            shift # past argument=value
            ;;
        -*|--*)
            echo "Unknown option $i"
            echo 'run using :'
            Example: ./s3curl.sh -u=http://example.url.com:9000 -k=admin -s=1234 -p=/
            exit 1
            ;;
        *)
            ;;
    esac
done

if [ -z $URL ]; then
  echo "You have NOT specified a MINIO URL!"
  exit 1
fi

if [ -z $KEY ]; then
  echo "You have NOT specified a KEY!"
  exit 1
fi

if [ -z ${PASSWORD} ]; then
  echo "You have NOT specified a PASSWORD!"
  exit 1
fi

if [ -z ${MINIO_PATH} ]; then
  echo "You have NOT specified a PATH!"
  exit 1
fi


MINIO_HOST="$URL"
MINIO_HOST=${MINIO_HOST##https://}
MINIO_HOST=${MINIO_HOST##http://}

# Static Vars
DATE=$(date -R --utc)
CONTENT_TYPE='application/zstd'
SIG_STRING="GET\n\n${CONTENT_TYPE}\n${DATE}\n${MINIO_PATH}"
SIGNATURE=`echo -en ${SIG_STRING} | openssl sha1 -hmac ${PASSWORD} -binary | base64`

opt=""
if [[ $verbose -eq 1 ]]; then
  opt="-v"
fi

curl $opt -k -H "Host: $MINIO_HOST" \
    -H "Date: ${DATE}" \
    -H "Content-Type: ${CONTENT_TYPE}" \
    -H "Authorization: AWS ${KEY}:${SIGNATURE}" \
    $URL${MINIO_PATH}
