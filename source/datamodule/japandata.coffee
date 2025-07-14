############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("japandata")
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
    data.hicp = "i.JP"
    data.mrr = "r.JP"
    data.gdpg = "g.JP"
    return


############################################################
export getData = -> data