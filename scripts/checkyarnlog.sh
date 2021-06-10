#!/bin/bash

logfile=$1

grep -e 'exit code' -e 'Exit code' -e 'Stack trace' -e 'Lost executor' -e 'Lost task' -e 'ERROR' -e 'ExecutorLostFailure' -e 'Container marked as failed' -e 'running beyond physical memory limits.' -e 'Missing an output location for shuffle' -e 'SparkException' -e 'java.lang.OutOfMemoryError' -e 'Failed to connect' -e 'Connection refused' $logfile 
