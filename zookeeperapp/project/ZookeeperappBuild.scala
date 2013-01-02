import sbt._
import sbt.Keys._

object ZookeeperappBuild extends Build {

  lazy val dependencies = {
    val zookeeper: ModuleID = "org.apache.zookeeper" % "zookeeper" % "3.4.5" % "compile" excludeAll(
      ExclusionRule(organization = "com.sun.jdmk"),
      ExclusionRule(organization = "com.sun.jmx"),
      ExclusionRule(organization = "javax.jms")
      )//not needed, but cause error: FAILED DOWNLOADS

    val commonsLang = "org.apache.commons" % "commons-lang3" % "3.1"
    val commonsIo = "org.apache.commons" % "commons-io" % "1.3.2"
    Seq(zookeeper, commonsLang, commonsIo)
  }

  lazy val zookeeperapp = Project(
    id = "zookeeperapp",
    base = file("."),
    settings = Project.defaultSettings ++ Seq(
      name := "ZookeeperApp",
      organization := "org.docear.helloworld",
      version := "0.1-SNAPSHOT",
      scalaVersion := "2.9.1",
      resolvers += "schleichardts Github" at "http://schleichardt.github.com/jvmrepo/",
      libraryDependencies ++= dependencies
      // add other settings here
    ) ++ seq(com.github.retronym.SbtOneJar.oneJarSettings: _*)
  )
}
