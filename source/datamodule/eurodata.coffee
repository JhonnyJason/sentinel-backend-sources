############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("eurodata")
#endregion

############################################################
import * as cfg from "./configmodule.js"

############################################################
data = { 
    hicp: NaN,
    mrr: NaN,
    gdpg: NaN 
}

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.EU"
    data.mrr = "r.EU"
    data.gdpg = "g.EU"

    heartbeatMS = cfg. statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return


############################################################
export getData = -> data

heartbeat = ->
    log "heartbeat"
    await requestMRR()
    await requestHICP()
    # await requestGDPG()
    return

############################################################
requestMRR = ->
    log "requestMRR"
    try
        response = await fetch("https://data-api.ecb.europa.eu/service/data/FM/B.U2.EUR.4F.KR.MRR_FR.LEV?lastNObservations=1")
        fullString = await response.text()
        
        log fullString
        # hacky extraction of the searched for value
        tokens = fullString.split("generic:ObsDimension value=\"")
        tokens = tokens[1].split("\"/>")
        date = tokens[0].trim()

        valuePercent = tokens[1].trim().replace("<generic:ObsValue value=\"", "")

        log date
        log valuePercent
        data.mrr = "#{valuePercent}%"
    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try # M.RCH_A.NSA.CP-HI00.EA20
        # response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/prc_hicp_manr?freq=M&unit=RCH_A&coicop=CP00&geo=EA20&time=2025-06&format=JSON") # Fails...
        response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/prc_hicp_manr/M.RCH_A.CP00.EA20?format=JSON")
        hicpData = await response.json()

        # log Object.keys(hicpData)
        # olog hicpData.value
        # olog hicpData.dimension.time

        allValues = hicpData.value
        indices = hicpData.dimension.time.category.index

        indexKeys = Object.keys(indices)
        indexKeys = indexKeys.sort().reverse()
        log indexKeys

        i = 0
        hicp = allValues[indices[indexKeys[i]]]
        while !hicp?
            i++
            hicp = allValues[indices[indexKeys[i]]]
        
        data.hicp = hicp
        
    catch err then log err
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    try
        response = await fetch("")
        fullString = await response.text()
        
    catch err then log err
    return
