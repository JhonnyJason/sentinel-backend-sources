############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("serverstatemodule")
#endregion

############################################################
currentState = {
    preInitTime: Date.now()
    state: "preInit"
    latestError: null
    connectedClients: 0
}

############################################################
export initialize = ->
    log "initialize"
    currentState.state = "initialized"
    currentState.initTime = Date.now()
    return

export setRunning = ->
    currentState.state = "running"
    currentState.startupTime = Date.now()
    return

export addClient = -> currentState.connectedClients++
export removeClient = -> currentState.connectedClients--

export setError = (err) ->
    errObj = {
        timestamp: Date.now(),
        message: err.message
    }
    currentState.latestError = errObj

export getState = -> currentState
