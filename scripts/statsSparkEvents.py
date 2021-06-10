#!/usr/bin/python3
"""
Example of a line parsed:
{
  "Event": "SparkListenerTaskEnd",
  "Stage ID": 39,
  "Stage Attempt ID": 0,
  "Task Type": "ShuffleMapTask",
  "Task End Reason": {
    "Reason": "Success"
  },
  "Task Info": {
    "Task ID": 7620,
    "Index": 572,
    "Attempt": 0,
    "Launch Time": 1580131506471,
    "Executor ID": "29",
    "Host": "mpfr3-cnode-001",
    "Locality": "PROCESS_LOCAL",
    "Speculative": false,
    "Getting Result Time": 0,
    "Finish Time": 1580131507032,
    "Failed": false,
    "Killed": false,
    "Accumulables": [
      {
        "ID": 399,
        "Name": "internal.metrics.input.recordsRead",
        "Update": 1,
        "Value": 611,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 398,
        "Name": "internal.metrics.input.bytesRead",
        "Update": 2165667,
        "Value": 2942746292,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 397,
        "Name": "internal.metrics.shuffle.write.writeTime",
        "Update": 1641060,
        "Value": 2656669919,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 396,
        "Name": "internal.metrics.shuffle.write.recordsWritten",
        "Update": 1,
        "Value": 611,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 395,
        "Name": "internal.metrics.shuffle.write.bytesWritten",
        "Update": 2165842,
        "Value": 2942788769,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 386,
        "Name": "internal.metrics.peakExecutionMemory",
        "Update": 33587200,
        "Value": 23617351303,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 385,
        "Name": "internal.metrics.diskBytesSpilled",
        "Update": 0,
        "Value": 0,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 384,
        "Name": "internal.metrics.memoryBytesSpilled",
        "Update": 0,
        "Value": 0,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 381,
        "Name": "internal.metrics.resultSize",
        "Update": 1943,
        "Value": 1293632,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 380,
        "Name": "internal.metrics.executorCpuTime",
        "Update": 22395570,
        "Value": 32238391888,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 379,
        "Name": "internal.metrics.executorRunTime",
        "Update": 545,
        "Value": 465076,
        "Internal": true,
        "Count Failed Values": true
      },
      {
        "ID": 378,
        "Name": "internal.metrics.executorDeserializeCpuTime",
        "Update": 1283225,
        "Value": 899016422,
        "Internal": true,
        "Count Failed Values": true
      }
    ]
  },
  "Task Metrics": {
    "Executor Deserialize Time": 0,
    "Executor Deserialize CPU Time": 1283225,
    "Executor Run Time": 545,
    "Executor CPU Time": 22395570,
    "Result Size": 1943,
    "JVM GC Time": 0,
    "Result Serialization Time": 0,
    "Memory Bytes Spilled": 0,
    "Disk Bytes Spilled": 0,
    "Shuffle Read Metrics": {
      "Remote Blocks Fetched": 0,
      "Local Blocks Fetched": 0,
      "Fetch Wait Time": 0,
      "Remote Bytes Read": 0,
      "Remote Bytes Read To Disk": 0,
      "Local Bytes Read": 0,
      "Total Records Read": 0
    },
    "Shuffle Write Metrics": {
      "Shuffle Bytes Written": 2165842,
      "Shuffle Write Time": 1641060,
      "Shuffle Records Written": 1
    },
    "Input Metrics": {
      "Bytes Read": 2165667,
      "Records Read": 1
    },
    "Output Metrics": {
      "Bytes Written": 0,
      "Records Written": 0
    },
    "Updated Blocks": []
  }
}

"""


import os
import pandas as pd

def main(fileEvents):
    df = pd.read_json(fileEvents, lines=True)
    dfTask = df.loc[df["Event"] == "SparkListenerTaskEnd"]
    #dfTask = dfTask.loc[dfTask["Task End Reason"].str.contains("Success")]
    dfTask.dropna(axis=1, how='all', inplace=True)
    dfTask.to
