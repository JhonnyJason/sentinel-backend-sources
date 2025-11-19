############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("bugsnitchmodule")
#endregion

############################################################
import net from "node:net"

############################################################
socketPath = "/run/bugsnitch.sk"

############################################################
setReady = null
ready = new Promise (rslv) -> setReady = rslv

############################################################
export initialize = (c) ->
    log "initialize"
    if c.snitchSocket then socketPath = c.snitchSocket
    setReady()
    return

sendToBugsnitch = (msg) ->
    log "sendToBugsnitch"
    await ready
    sock = net.createConnection(socketPath)
    sock.on("connect", (() -> sock.end(msg)))
    sock.on("error", ((e) -> console.error(e)))
    sock.on("close", (() -> log "Connection closed!"))
    return

############################################################
export report = (error) ->
    log "report"
    console.error(error)
    if typeof error == "string"
        sendToBugsnitch(error)
        return
    
    try
        msg = "Error: "+error.message
        if error.cause then msg += "\n Cause: "+error.cause
        if error.stack then msg += "\n Stack: "+error.stack
        sendToBugsnitch(msg)
        return
    catch err then console.error("bugsnitch.report: unexpected errorObject!\n "+err.message)
    return

