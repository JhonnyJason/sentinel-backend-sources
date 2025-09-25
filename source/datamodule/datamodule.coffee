############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("datamodule")
#endregion

############################################################
import * as eurodata from "./eurodata.js"
import * as usdata from "./usdata.js"
import * as japandata from "./japandata.js"
import * as swissdata from "./swissdata.js"
import * as canadadata from "./canadadata.js"
import * as aussiedata from "./aussiedata.js"
import * as zealanddata from "./zealanddata.js"
import * as ukdata from "./ukdata.js"

############################################################
allData = { default: "no-data" }

############################################################
export initialize = ->
    log "initialize"
    eurodata.initialize()
    usdata.initialize()
    japandata.initialize()
    swissdata.initialize()
    canadadata.initialize()
    aussiedata.initialize()
    zealanddata.initialize()
    ukdata.initialize()
    return

############################################################
export getAllData = -> 
    log "getAllData" 
    ## Todo simply return the finished persistent JSON
    allData.eurozone = eurodata.getData()
    allData.usa = usdata.getData()
    allData.japan = japandata.getData()
    allData.switzerland = swissdata.getData()
    allData.canada = canadadata.getData()
    allData.australia = aussiedata.getData()
    allData.newzealand = zealanddata.getData()
    allData.uk = ukdata.getData()
    return allData