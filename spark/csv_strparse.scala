// spark-shell --master yarn --deploy-mode client --num-executors 2 --executor-cores 1  --executor-memory 3G -i csv_strparse.scala --name "JLU"| tee ~/spark.log

import org.apache.log4j.Logger
import org.apache.log4j.Level

import java.time.format.DateTimeFormatter
import java.time.{LocalDate, LocalDateTime}
import java.io.{File, BufferedWriter, FileWriter}
import java.util.concurrent

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.scala.DefaultScalaModule
import org.apache.spark.sql.{Dataset, DataFrame, SparkSession, SQLContext, SaveMode, Row}
import org.apache.spark.{SparkConf, SparkContext}
import org.apache.spark.sql.types.{StructType,StructField,StringType}
import org.apache.spark.sql.functions.regexp_replace
import org.apache.spark.rdd.RDD
import org.apache.log4j.{Level, LogManager, PropertyConfigurator}
import scala.collection._ // concurrent.Map
import scala.collection.JavaConversions._ // important for 'foreach'
import org.apache.commons.io.FileUtils
import collection.JavaConverters._
import scala.util.Random


val random = new Random(270581)
val zLogger = LogManager.getLogger("com.aosis.spark.jlu")

case class MyData(dossier_ref: Int, first_idx: Int, first_message: String, all_messages: String, message: String)

val t0 = System.currentTimeMillis()
val spark = SparkSession.builder().getOrCreate()
val infile = "/srw/all_messages_per_dossier.csv"
val ds0 = spark.read.format("csv").option("header", "true").option("inferSchema","true").load(infile).as[MyData]
val t1 = System.currentTimeMillis()
zLogger.info(s"duration : " + (t1 - t0) + "ms")
println(s"duration : " + (t1 - t0) + "ms")
val ds1 = ds0.withColumn("message", regexp_replace($"message", "'", "`")).as[MyData]
ds1.write.csv("/srw/test_scala.csv")
val t2 = System.currentTimeMillis()
zLogger.info(s"duration : " + (t2 - t1) + "ms")
println(s"duration : " + (t2 - t1) + "ms")
exit()
