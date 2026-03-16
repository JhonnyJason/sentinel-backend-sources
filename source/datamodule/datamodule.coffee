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
import * as paramdata from "./paramdatamodule.js"

############################################################
makroData = Object.create(null)

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
# export getAllMakroData = -> 
getAllMakroData = -> 
    log "getAllMakroData" 
    makroData.eurozone = eurodata.getData()
    makroData.usa = usdata.getData()
    makroData.japan = japandata.getData()
    makroData.switzerland = swissdata.getData()
    makroData.canada = canadadata.getData()
    makroData.australia = aussiedata.getData()
    makroData.newzealand = zealanddata.getData()
    makroData.uk = ukdata.getData()
    return makroData

############################################################
export getAllData = ->
    log "getAllData"
    data = getAllMakroData()
    pubShot = paramdata.getPublishedSnapshot()
    return data unless pubShot?

    data.eurozone._params = pubShot.areaParams.eurozone
    data.usa._params = pubShot.areaParams.usa
    data.japan._params = pubShot.areaParams.japan
    data.switzerland._params = pubShot.areaParams.switzerland
    data.canada._params = pubShot.areaParams.canada
    data.australia._params = pubShot.areaParams.australia
    data.newzealand._params = pubShot.areaParams.newzealand
    data.uk._params = pubShot.areaParams.uk
    
    data._params = pubShot.globalParams
    return data