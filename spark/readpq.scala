
// cd /mnt/hdfs/LRI/ndvi/
// find satellite=*/tileid=*/year=20?? -type f -ctime -2 | xargs ls -lrt
// ls -lkqS /mnt/hdfs/LRI/ndvi/satellite=*/tileid=*/year=20??/*parquet*

// spark-shell --master yarn --deploy-mode client --driver-memory 2G --num-executors 2 --executor-cores 4 --executor-memory 4G -i readpq.scala --name "LRI - read parquet - JLU"| tee ~/readpq.log

import org.apache.log4j.Logger
import org.apache.log4j.Level

import java.time.format.DateTimeFormatter
import java.time.{LocalDate, LocalDateTime}
import java.io.{File, BufferedWriter, FileWriter}
import java.util.concurrent

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.scala.DefaultScalaModule
import org.apache.spark.sql.{SQLContext, SaveMode, Row}
// import org.apache.spark.{SparkConf, SparkContext} /spark version 1.x
// import org.apache.spark.implicits._ //spark version >= 2.0.0
import org.apache.spark.sql.SparkSession //spark version >= 2.0.0
import org.apache.spark.sql.types.{StructType,StructField,StringType}
import org.apache.spark.rdd.RDD
import org.apache.log4j.{Level, LogManager, PropertyConfigurator}
import scala.collection._ // concurrent.Map
import scala.collection.JavaConversions._ // important for 'foreach'
import org.apache.commons.io.FileUtils
import collection.JavaConverters._
import scala.util.Random

val random = new Random(270581)

val t0 = System.currentTimeMillis()

val zLogger = LogManager.getLogger("com.spark.jlu.readpq")

//spark version < 2.0.0
// val conf = new SparkConf().setAppName("LRI - read parquet - JLU").set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
// val sqlContext = new SQLContext(sc)
// import sqlContext.implicits._
//spark version >= 2.0.0
val sqlContext = SparkSession.builder().appName("LRI - read parquet - JLU").getOrCreate()
import sqlContext.implicits._

def biYear(year: Int) : Boolean = {
  if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
    true
  } else {
    false
  }
}

def nbDaysInYear(year: Int): Int = {
  if (biYear(year)) {
    366
  }  else {
    365
  }
}

def parquetCheckv1(): Unit = {
  val listSat = List("AQUA", "TERRA")
  val listTile = List("h10v04", "h20v03", "h20v04", "h27v12")
  val listSubtile = List("k07l06", "k08l06", "k09l05", "k09l06")
  val parqPathRoot = "file:///tmp/parquetv2-h17v04"
  val parqUrlRoot = "hdfs://modis"
  for (sat <- listSat) {
    for (tile <- listTile) {
      for (year <- 2006 to 2016) {
        /* val year=2014
        val tile="h10v04"
        val sat = "AQUA" */
        val parqPath = s"/satellite=$sat/tileid=$tile/year=$year/"
        val hdfsFiles = FileUtils.listFiles(new File(parqPathRoot + parqPath), Array("parquet"), true)
        //val hdfsFilenames = random.shuffle(hdfsFiles.toList).take(10).map{ f => f.getName() }
        val hdfsFilenames = hdfsFiles.map { f => f.getName() }
        val theDates = hdfsFilenames.par.map { f =>
          val parqfilename = parqPathRoot + parqPath + "/" + f
          val file = new File(parqfilename)
          val size = file.length //bytesize
          val lastMod = file.lastModified
          lazy val df = sqlContext.read.parquet(parqUrlRoot + parqPath + "/" + f)
          //df.printSchema()
          val names = df.select(inputFileName())
          //names.show
          //val pixelDF = df.filter("hhvviiiijjjj = 100414390001")
          //val t = pixelDF.select("t").take(1)
          val allTimes = df.filter("t >= 0").select("t").dropDuplicates().take(100000)
          if (allTimes.length > 1) {
            val theTimes = allTimes.toSet
            println(s"parquet file $f stores multiple dates in it $theTimes")
          }
          val theDays = allTimes.par.map(timeEp => {
            val tt = timeEp.getLong(0)
            val singletimedf = df.filter(s"t = $tt")
            val pixelId: String = singletimedf.head().getString(0)
            //val ndvi = df.filter(s"hhvviiiijjjj = $pixelId").select("ndvi").head().getFloat(0)
            //println(s"for pixel $pixelId -> NDVI = $ndvi")
            val time = new org.joda.time.DateTime(tt * 86400L * 1000L)
            val day = time.getDayOfYear
            println(s"parquet file $f corresponds to satellite=$sat/tileid=$tile/year=$year/day=$day/firstPixel=$pixelId ByteSize=$size lastModif=$lastMod")
            zLogger.info(s"parquet file $f corresponds to satellite=$sat/tileid=$tile/year=$year/day=$day/firstPixel=$pixelId ByteSize=$size lastModif=$lastMod")
            day.toInt
          })
          theDays.toList
        }.toList.flatten.sorted
        val numDate = theDates.size
        println(s"Parquet number of date entries found for $parqPath : $numDate")
        zLogger.info(s"Parquet number of date entries found for $parqPath : $numDate")
        println(s"List of dates found for $parqPath : $theDates")
        var missingDates: Array[Int] = Array()
        for (i <- (1 to nbDaysInYear(year))) {
          if ( !(theDates contains i) ) {
            missingDates = missingDates ++ Array(i)
          }
        }
        val numMiss = missingDates.size
        val listMiss = missingDates.toList
        println(s"Parquet number of date entries missing for $parqPath : $numMiss")
        println(s"List of dates missings for $parqPath : $listMiss")
      }
    }
  }
}

def parquetTest(): Unit = {
  val parqUrlRoot = "file:///tmp/parquetv2-h17v04"
  zLogger.info(s"parquetTest $parqUrlRoot")
  lazy val df = sqlContext.read.parquet(parqUrlRoot)
  df.printSchema()
  val sat = "AQUA"
  val tile = "h17v04"
  val subtile = "k09l06"
  //val pxIndex = "110404390001"
  val pxIndex = "170443202961"
  //val pixelDF = df.filter(s"satellite = '$sat' AND tileid = '$tile' AND subtileid = '$subtile' AND hhvviiiijjjj = $pxIndex")
  val pixelDF = df.filter(s"subtileid = '$subtile' AND hhvviiiijjjj = $pxIndex")
  val pixelCount = pixelDF.count()
  println(s"parquet database stores multiple dates $pixelCount for pixel $pxIndex")
  zLogger.info(s"parquet database stores multiple dates $pixelCount for pixel $pxIndex")
  val df2 = df.repartition(512).filter(s"subtileid = '$subtile' AND ndvi >= 0.8").orderBy($"ndvi".asc)
  df2.select(mean(df("ndvi"))).show()
  df2.write.parquet("/modis")
  pixelDF.show(100)
}


parquetTest()
val t1 = System.currentTimeMillis()
zLogger.info(s"parquetTest duration : " + (t1 - t0) + "ms")
println(s"parquetTest duration : " + (t1 - t0) + "ms")

System.exit(0).
