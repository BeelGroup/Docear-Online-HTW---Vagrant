import sbt._
import Keys._
import PlayProject._

object ApplicationBuild extends Build {

    val appName         = "playapp"
    val appVersion      = "1.0-SNAPSHOT"

    val appDependencies = Seq(
      // Add your project dependencies here,
    )

    val main = PlayProject(appName, appVersion, appDependencies, mainLang = JAVA).settings(
      javacOptions ++= Seq("-source", "1.6", "-target", "1.6")//for compatibility with Debian Squeeze
    )

}
