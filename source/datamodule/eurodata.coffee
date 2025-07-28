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
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "euroMRR" then await requestMRR()
            when "euroHICP" then await requestHICP()
            when "euroGDPG" then await requestGDPG()
    else 
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
    try 
        # prc_hicp_manr has no seasonal adjustment
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
    ## Here we want Annualized QoQ growth of Real GDP 
    #  -> Adjusted for inflation, Seasonality and Calendar 
    try
        ## Key buildup = freq.unit.s_adj.na_item.geo
        # freq: Q -> Quarterly
        # unit: CLV_I10 -> Chained Linked Volume Index from 2010 (inflation adjusted)
        # s_adj: SCA -> Saesonally and Calendar adjusted
        # na_item: B1GQ -> Gross domestic product at market prices
        # geo: EA20 -> EuroArea with the 20 Member states from 2023
        response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/namq_10_gdp/Q.CLV_I10.SCA.B1GQ.EA20?format=JSON") 
        gdpData = await response.json()

        # olog gdpData

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
            if i > 300 then throw new Error("Something is wrong with the indices...")
        i++
        gdpBefore = allValues[indices[indexKeys[i]]]
        
        if typeof latestGDP != "number" then latestGDP = parseFloat(latestGDP)
        if typeof gdpBefore != "number" then gdpBefore = parseFloat(gdpBefore)

        gdpgQ = (100.00 * latestGDP / gdpBefore ) - 100.00
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        olog { latestGDP, gdpBefore, gdpgQ, gdpgA, data }    
        
    catch err then log err
    return

############################################################
export getData = -> data
