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
    mrr: NaN,
    gdpg: NaN 
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
        
        # olog mmrData.observations[0]
        mrr = parseFloat(mrrData.observations[0].value)
        data.mrr = "#{mrr.toFixed(2)}%"
        
        olog { mrr }
        olog data

    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try
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
            break

        for d in hicpData when d.period == period and d.year == lastYear
            valueBefore = parseFloat(d.value)
            break

        
        hicp = (100.0 * latestValue / valueBefore) - 100
        data.hicp = "#{hicp.toFixed(2)}%"

        oloc { hicp }
        olog data

    catch err then log err
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    try
        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"
        yearBefore = "#{date.getFullYear() - 2}"
        url = "https://apps.bea.gov/api/data?&UserId=#{cfg.beaAPIKey}&method=GetData&datasetname=NIPA&TableName=T10105&Frequency=Q&Year=#{thisYear},#{lastYear}, #{yearBefore}"
        response = await fetch(url) 
        allGDPData = await response.json()

        isRelevantResult = (result) -> result.LineDescription == "Gross domestic product"  
        gdpData = allGDPData.BEAAPI.Results.Data.filter(isRelevantResult)
        # olog gdpData

        periodToData = {}
        for d in gdpData
            periodToData[d.TimePeriod] = d.DataValue.replaceAll(",", "")

        # olog periodToData
        periodList = Object.keys(periodToData).sort().reverse()
        # log periodList
        if periodList.length < 5 then throw new Error("To few Results found! Received only #{periodList}")

        latestGDP = parseFloat(periodToData[periodList[0]])
        gdpBefore = parseFloat(periodToData[periodList[4]])

        gdpg = (100.00 * latestGDP / gdpBefore ) - 100.00
        data.gdpg = "#{gdpg.toFixed(2)}%"

        olog { latestGDP, gdpBefore, gdpg }    

    catch err then log err
    return
