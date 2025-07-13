############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("startupmodule")
#endregion

############################################################
import * as sci from "./scimodule.js"

############################################################
export serviceStartup = ->
    log "serviceStartup"
    # other startup moves
    sci.prepareAndExpose()
    return
