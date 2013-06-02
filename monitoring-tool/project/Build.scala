import sbt._
import sbt.Keys._

object Build extends Build {

  val seleniumVersion = "2.32.0"

  lazy val rootProject = Project(id = "monitoring-tool", base = file("."), settings = Project.defaultSettings ++ Seq(
      name := "monitoring-tool"
    , organization := "org.docear"
    , version := "0.1-SNAPSHOT"
    , scalaVersion := "2.10.1"
    , libraryDependencies ++= Seq(
      "org.seleniumhq.selenium" % "selenium-java" % seleniumVersion % "test"
      , "org.seleniumhq.selenium" % "selenium-htmlunit-driver" % seleniumVersion % "test"
      ,  "com.novocode" % "junit-interface" % "0.8" % "test->default"
    )
  ) ++ seq(com.github.retronym.SbtOneJar.oneJarSettings: _*)
  )
}
