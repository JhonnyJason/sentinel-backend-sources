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
    await requestGDPG()
    return

############################################################
requestMRR = ->
    log "requestMRR"
    try
        response = await fetch("https://data-api.ecb.europa.eu/service/data/FM/B.U2.EUR.4F.KR.MRR_FR.LEV?lastNObservations=1")
        fullString = await response.text()
        
        # log fullString
        # hacky extraction of the searched for value
        tokens = fullString.split("generic:ObsDimension value=\"")
        tokens = tokens[1].split("\"/>")
        date = tokens[0].trim()

        mrr = parseFloat(tokens[1].trim().replace("<generic:ObsValue value=\"", ""))

        log date
        log mrr
        data.mrr = "#{mrr.toFixed(2)}%"
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
        # log indexKeys

        i = 0
        hicp = allValues[indices[indexKeys[i]]]
        while !hicp?
            i++
            hicp = allValues[indices[indexKeys[i]]]

        if typeof hicp != "number" then hicp = parseFloat(hicp)        
        data.hicp = "#{hicp.toFixed(2)}%"
        olog {hicp}

    catch err then log err
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    try
        # response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/namq_10_gdp/Q.CP_MEUR.NSA.B1GQ.EA20?format=JSON") # Quarterly
        response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/nama_10_gdp/A.CP_MEUR.B1GQ.EA20?format=JSON") # Annual
        gdpData = await response.json()

        allValues = gdpData.value
        indices = gdpData.dimension.time.category.index

        indexKeys = Object.keys(indices)
        indexKeys = indexKeys.sort().reverse()
        # log indexKeys

        i = 0
        latestGDP = allValues[indices[indexKeys[i]]]
        while !latestGDP?
            i++
            latestGDP = allValues[indices[indexKeys[i]]]
        
        i++
        gdpBefore = allValues[indices[indexKeys[i]]]
        
        if typeof latestGDP != "number" then latestGDP = parseFloat(latestGDP)
        if typeof gdpBefore != "number" then gdpBefore = parseFloat(gdpBefore)

        gdpg = (100.00 * latestGDP / gdpBefore ) - 100.00
        data.gdpg = "#{gdpg.toFixed(2)}%"
        olog { latestGDP, gdpBefore, gdpg }    
        
    catch err then log err
    return
