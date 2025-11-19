############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("scimodule")
#endregion

############################################################
#region modules from the Environment
import { WebSocketServer } from "ws"

############################################################
import * as scicore from "./scicoremodule.js"

############################################################
import { onConnect } from "./wsimodule.js"

############################################################
import "./accesssci.js"

#endregion

############################################################
wsS = new WebSocketServer({noServer: true})
wsS.on("connection", onConnect)

############################################################
wsUpgradeHandler = (req, sock, head) ->
    wsS.handleUpgrade(req, sock, head, ((ws) -> wsS.emit("connection", ws, req)))
    return


############################################################
export prepareAndExpose = ->
    log "prepareAndExpose"
    scicore.setUpgradeHandler(wsUpgradeHandler)
    await scicore.sciStartServer()
    log "Server listening!"
    return
