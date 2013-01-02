package controllers;

import play.*;
import play.mvc.*;

import views.html.*;

import java.lang.System;

public class Application extends Controller {
  
  public static Result index() {
    return ok("app from port " + System.getProperty("http.port", "unknown port, start with -Dhttp.port=<port>"));
  }
  
}