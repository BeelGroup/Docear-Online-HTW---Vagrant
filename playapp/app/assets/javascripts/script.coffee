$ ->
  if $("body").hasClass("discovery-websocket")
    websocket = new WebSocket(discoveryWebSocketUrl);
    websocket.onmessage = (evt) -> console.log evt.data
    websocket.onopen = (evt) -> $("#websocket-status").text("You are connected with WebSockets.")
    websocket.onclose = (evt) -> $("#websocket-status").text("You are diconnected with WebSockets.")