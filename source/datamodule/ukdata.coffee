############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("ukdata")
#endregion

############################################################
data = { 
    hicp: NaN,
    mrr: NaN,
    gdpg: NaN 
}

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.UK"
    data.mrr = "r.UK"
    data.gdpg = "g.UK"
    return


############################################################
export getData = -> data