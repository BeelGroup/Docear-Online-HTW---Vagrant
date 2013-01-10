import sbt._
import Keys._
import PlayProject._

object ApplicationBuild extends Build {

    val appName         = "playapp"
    val appVersion      = "1.0-SNAPSHOT"

    val appDependencies = Seq(
      "org.apache.zookeeper" % "zookeeper" % "3.4.5" % "compile" excludeAll(
        ExclusionRule(organization = "com.sun.jdmk"),
        ExclusionRule(organization = "com.sun.jmx"),
        ExclusionRule(organization = "javax.jms")
        )//not needed, but cause error: FAILED DOWNLOADS
    )

    val main = PlayProject(appName, appVersion, appDependencies, mainLang = JAVA).settings(
      javacOptions ++= Seq("-source", "1.6", "-target", "1.6")//for compatibility with Debian Squeeze
    )

}
