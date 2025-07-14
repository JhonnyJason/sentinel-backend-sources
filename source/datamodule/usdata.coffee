############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("usdata")
#endregion

############################################################
import { blsAPIKey } from "./configmodule.js"

############################################################
data = { 
    hicp: NaN,
    mrr: NaN,
    gdpg: NaN 
}

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.US"
    data.mrr = "r.US"
    data.gdpg = "g.US"

    log blsAPIKey
    return


############################################################
export getData = -> data