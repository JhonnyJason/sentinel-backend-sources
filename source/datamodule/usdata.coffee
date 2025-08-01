############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("usdata")
#endregion

############################################################
import * as cfg from "./configmodule.js"

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
    data.hicp = "i.US"
    data.mrr = "r.US"
    data.gdpg = "g.US"

    # log "BLS API: #{cfg.blsAPIKey}"
    # log "BEA API #{cfg.beaAPIKey}"
    # log "FRED API #{cfg.fredAPIKey}"

    heartbeatMS = cfg.statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return


############################################################
export getData = -> data

heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "usMRR" then await requestMRR()
            when "usHICP" then await requestHICP()
            when "usGDPG" then await requestGDPG()
    else 
        await requestMRR()
        await requestHICP()
        await requestGDPG()
    return

############################################################
requestMRR = ->
    log "requestMRR"
    try
        url = "https://api.stlouisfed.org/fred/series/observations?series_id=DFEDTARU&api_key=#{cfg.fredAPIKey}&file_type=json&sort_order=desc&limit=1"
        response = await fetch(url)
        mrrData = await response.json()
        
        # olog mrrData.observations[0]
        mrr = parseFloat(mrrData.observations[0].value)
        mrrDate = new Date(mrrData.observations[0].date)

        data.mrr = "#{mrr.toFixed(2)}%"
        
        data.mrrMeta = {
            source: '<a href="https://fred.stlouisfed.org/">FRED</a>',
            dataSet: "Federal Funds Target Range - Upper Limit (DFEDTARU)",
            date: mrrDate # DATE
        }
        # olog { mrr }
        olog data
    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try
        # no Seasonal adjustment on Dataset CUUR0000SA0
        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"

        bodyJSON = {
            registrationkey: cfg.blsAPIKey,
            seriesid:["CUUR0000SA0"],
            startyear: lastYear,
            endyear: thisYear,
        }

        url = "https://api.bls.gov/publicAPI/v2/timeseries/data/"
        fetchOptions = {
            method: "POST",
            headers: {
             'Content-Type': 'application/json'
            }
            body: JSON.stringify(bodyJSON)
        }

        response = await fetch(url, fetchOptions)
        hicpData = await response.json()
        
        if hicpData.status != "REQUEST_SUCCEEDED" then throw new Error(hicpData.message)
        hicpData = hicpData.Results.series[0].data

        # olog hicpData
        for d in hicpData when d.latest? and d.latest == "true"
            latestValue = parseFloat(d.value)
            period = d.period
            dateString = "#{d.periodName} #{d.year}"
            break

        for d in hicpData when d.period == period and d.year == lastYear
            valueBefore = parseFloat(d.value)
            break

        
        hicp = (100.0 * latestValue / valueBefore) - 100
        data.hicp = "#{hicp.toFixed(2)}%"

        data.hicpMeta = {
            source: '<a href="https://www.bls.gov/" target="_blank">U.S Bureau of Labor Statistics</a>',
            dataSet: "Consumer Price Index for All Urban Consumers (CUUR0000SA0)",
            date: dateString
        }

        olog data

    catch err then log err
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    try
        ## Table T10106 is inflation adjusted
        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"
        yearBefore = "#{date.getFullYear() - 2}"
        url = "https://apps.bea.gov/api/data?&UserId=#{cfg.beaAPIKey}&method=GetData&datasetname=NIPA&TableName=T10106&Frequency=Q&Year=#{thisYear},#{lastYear}, #{yearBefore}"
        response = await fetch(url) 
        allGDPData = await response.json()

        isRelevantResult = (result) -> result.LineDescription == "Gross domestic product"  
        # isRelevantResult = (result) -> result.LineDescription == "Gross domestic product (Real, SAAR)"
        gdpData = allGDPData.BEAAPI.Results.Data.filter(isRelevantResult)

        ## checking what we have available here :-)        
        # gdpData = allGDPData.BEAAPI.Results.Data
        # # olog gdpData
        # vals = new Set()

        # vals.add(d.LineDescription) for d in gdpData
        # olog new Array(...vals)

        # return

        periodToData = {}
        for d in gdpData
            periodToData[d.TimePeriod] = d.DataValue.replaceAll(",", "")

        # olog periodToData
        periodList = Object.keys(periodToData).sort().reverse()
        # log periodList
        if periodList.length < 5 then throw new Error("To few Results found! Received only #{periodList}")

        latestGDP = parseFloat(periodToData[periodList[0]])
        gdpBefore = parseFloat(periodToData[periodList[1]]) # last Quarter

        #format Period
        ts = periodList[0].split("Q")
        dateString = "Q#{ts[1]} #{ts[0]}"

        gdpgQ = (100.00 * latestGDP / gdpBefore ) - 100.00
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)
        data.gdpg = "#{gdpgA.toFixed(2)}%"

        data.gdpgMeta = {
            source: '<a href="https://www.bea.gov/" target="_blank">U.S. Bureau of Economic Analysis</a>',
            dataSet: "GDP (NIPA / T10106) Real GDP SA QoQ% annualized",
            date: dateString
        }

        olog { latestGDP, gdpBefore, data }    

    catch err then log err
    return
