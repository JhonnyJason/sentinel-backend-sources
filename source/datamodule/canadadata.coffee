############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("canadadata")
#endregion

############################################################
import * as cfg from "./configmodule.js"

############################################################
monthToName = {
    "01": "January"
    "02": "February"
    "03": "March"
    "04": "April"
    "05": "May"
    "06": "June"
    "07": "July"
    "08": "August"
    "09": "September"
    "10": "October"
    "11": "November"
    "12": "December"
}

############################################################
data = { 
    hicp: NaN,
    hicpMeta: {}
    mrr: NaN,
    mrrMeta: {}
    gdpg: NaN 
    gdpgMeta: {}
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
        
        # olog mrrData
        
        mrr = parseFloat(mrrData.observations[0].V39079.v)
        mrrDate = new Date(mrrData.observations[0].d)

        data.mrr = "#{mrr.toFixed(2)}%"
        data.mrrMeta = {
            source: '<a href="https://www.bankofcanada.ca/">Bank of Canada</a>',
            dataSet: "Policy Interest Rate (V39079)",
            date: mrrDate # DATE
        }

        olog data

    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try
        url = "https://www150.statcan.gc.ca/t1/wds/rest/getDataFromVectorsAndLatestNPeriods"
        bodyJSON = [{
            "vectorId": 41690973, # Raw CPI Level, no seasonal adjustment
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

        #Formated Date
        # log periods[0]
        ts = periods[0].split("-")
        dateString = "#{monthToName[ts[1]]} #{ts[0]}"

        hicp = 100.00 * latestIndex / indexBefore - 100
        data.hicp = "#{hicp.toFixed(2)}%"
        data.hicpMeta = {
            source: '<a href="https://www.statcan.gc.ca/en/start" target="_blank">Statistics Canada</a>',
            dataSet: "CPI monthly data (18-10-0004-01/v41690973)",
            date: dateString
        }

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

        olog periods
        log periods[0]
        ts = periods[0].split("-")
        if ts[1] == "01"
            dateString = "Q1 #{ts[0]}"
        if ts[1] == "04"
            dateString = "Q2 #{ts[0]}"
        if ts[1] == "07" 
            dateString = "Q3 #{ts[0]}"
        if ts[1] == "10" 
            dateString = "Q4 #{ts[0]}"
        

        # olog periods
        # log periods[0]
        # log periods[12]
        latestGDP = parseFloat(periodToValue[periods[0]])
        gdpBefore = parseFloat(periodToValue[periods[1]])

        gdpgQ = 100.00 * latestGDP / gdpBefore - 100
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        data.gdpgMeta = {
            source: '<a href="https://www.statcan.gc.ca/en/start" target="_blank">Statistics Canada</a>',
            dataSet: "Gross domestic product, expenditure-based, Canada, quarterly (36-10-0104-01/1.1.1.30.0.0.0.0.0.0) Real GDP SA QoQ% annualized",
            date: dateString
        }

        olog { gdpgQ, gdpgA, data }        
    catch err then log err
    return

############################################################
export getData = -> data
