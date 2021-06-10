from pyspark import SQLContext
from pyspark.sql import Row
from pyspark import SparkContext
from pyspark.sql.functions import regexp_replace
from datetime import datetime

t0 = datetime.now()
infile = "/srw/all_messages_per_dossier.csv"
df0 = sqlContext.read.load(infile, format='com.databricks.spark.csv', header='true', inferSchema='true')
t1 = datetime.now()
print "duration "+str((t1-t0).total_seconds() * 1000) + " ms"
df1 = df0.withColumn('message', regexp_replace('message', "'", "`"))
df1.write.csv('/srw/test_py.csv')
t2 = datetime.now()
print "duration "+str((t2-t1).total_seconds() * 1000) + " ms"
