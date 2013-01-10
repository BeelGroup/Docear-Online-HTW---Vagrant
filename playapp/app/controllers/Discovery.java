package controllers;

import play.Logger;
import play.libs.F;
import play.mvc.Controller;
import play.mvc.Result;
import play.mvc.WebSocket;

public class Discovery  extends Controller {
    public static Result index() {
        return ok(views.html.discovery.render());
    }

    public static WebSocket<String> websocket() {
        return new WebSocket<String>() {
            public void onReady(WebSocket.In<String> in, WebSocket.Out<String> out) {
                Logger.debug("connected with discovery websocket");
                in.onMessage(new F.Callback<String>() {
                    public void invoke(String event) {
                        Logger.debug("discovery websocket got message: " + event);
                    }
                });
                in.onClose(new F.Callback0() {
                    public void invoke() {
                        Logger.debug("discovery websocket connection closed");
                    }
                });

                // Send a single 'Hello!' message
                out.write("Hello!");

            }

        };
    }


}