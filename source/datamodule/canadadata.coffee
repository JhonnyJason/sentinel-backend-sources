############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("canadadata")
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
    data.hicp = "i.CA"
    data.mrr = "r.CA"
    data.gdpg = "g.CA"

    heartbeatMS = cfg. statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return


############################################################
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "canadaMRR" then await requestMRR()
            when "canadaHICP" then await requestHICP()
            when "canadaGDPG" then await requestGDPG()
    else
        await requestMRR()
        await requestHICP()
        await requestGDPG()
    return

############################################################
requestMRR = ->
    log "requestMRR"
    try
        url = "https://www.bankofcanada.ca/valet/observations/V39079/json?recent=1"
        response = await fetch(url)
        mrrData = await response.json()
        
        olog mrrData
        
        mrr = parseFloat(mrrData.observations[0].V39079.v)
        data.mrr = "#{mrr.toFixed(2)}%"

        olog data

    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try 
        url = "https://www150.statcan.gc.ca/t1/wds/rest/getDataFromVectorsAndLatestNPeriods"
        bodyJSON = [{
            "vectorId": 41690973, # Raw CPI Level
            "latestN": 13
        }]

        fetchOptions = {
            method: "POST",
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(bodyJSON)
        }
        response = await fetch(url, fetchOptions)
        hicpData = await response.json()
        # olog hicpData

        hicpData = hicpData[0].object.vectorDataPoint
        # olog hicpData
        
        periodToValue = {}
        for d in hicpData
            periodToValue[d.refPer] = d.value
        # olog periodToValue
        periods = Object.keys(periodToValue).sort().reverse()

        # olog periods
        # log periods[0]
        # log periods[12]
        latestIndex = parseFloat(periodToValue[periods[0]])
        indexBefore = parseFloat(periodToValue[periods[12]])

        hicp = 100.00 * latestIndex / indexBefore - 100
        data.hicp = "#{hicp.toFixed(2)}%"
        olog { data }

    catch err then log err
    return

############################################################
requestGDPG = ->
    ## Here we want Annualized QoQ growth of Real GDP 
    #  -> Adjusted for inflation, Seasonality and Calendar 
    try 
        url = "https://www150.statcan.gc.ca/t1/wds/rest/getDataFromCubePidCoordAndLatestNPeriods"
        
        bodyJSON = [{
            "productId": 36100104,
            "coordinate": "1.1.1.30.0.0.0.0.0.0",
            "latestN": 5
        }]

        fetchOptions = {
            method: "POST",
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(bodyJSON)
        }

        response = await fetch(url, fetchOptions)
        gdpData = await response.json()
        # olog gdpData

        gdpData = gdpData[0].object.vectorDataPoint
        # olog gdpData
        
        periodToValue = {}
        for d in gdpData
            periodToValue[d.refPer] = d.value
        # olog periodToValue
        periods = Object.keys(periodToValue).sort().reverse()

        # olog periods
        # log periods[0]
        # log periods[12]
        latestGDP = parseFloat(periodToValue[periods[0]])
        gdpBefore = parseFloat(periodToValue[periods[1]])

        gdpgQ = 100.00 * latestGDP / gdpBefore - 100
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        olog { gdpgQ, gdpgA, data }
        
    catch err then log err
    return

############################################################
export getData = -> data
