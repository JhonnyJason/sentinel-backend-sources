############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("japandata")
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
bojOrigin = "https://www.stat-search.boj.or.jp"

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.JP"
    data.mrr = "r.JP"
    data.gdpg = "g.JP"

    heartbeatMS = cfg.statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return

############################################################
heartbeat = ->
    log "heartbeat"
    await requestMRR()
    # await requestHICP()
    # await requestGDPG()
    return


############################################################
buildBOJUrl = (seriesCode, startYear, endYear) -> 
  baseUrl = "#{bojOrigin}/ssi/cgi-bin/famecgi2"
  params = new URLSearchParams({
    cgi: '$nme_r030_en',
    chkfrq: 'DD',
    rdoheader: 'DETAIL',
    rdodelimitar: 'COMMA',
    sw_freq: 'NONE',
    sw_yearend: 'NONE',
    sw_observed: 'NONE',
    hdnYyyyFrom: startYear,
    hdnYyyyTo: endYear,
    hdncode: seriesCode,
  })
  return "#{baseUrl}?#{params.toString()}";

############################################################
requestMRR = ->
    log "requestMRR"
    try
        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"
        url = buildBOJUrl("IR01'MADR1Z@D", lastYear, thisYear)
        response = await fetch(url)
        resultPage = await response.text()
        
        # log resultPage
        tokens = resultPage.split('<a href="')
        if tokens.length < 2 then throw new Error("Unexpected result Page: #{resultPage}")

        # log tokens.length

        i = 1
        while i < tokens.length
            url = tokens[i].split('"')[0]
            if url.endsWith(".csv") then break
            i++

        # log url
        url = new URL(url, bojOrigin)
        # log url
        response = await fetch(url.href)
        csvResult = await response.text()

        # log csvResult

        dateToValue =  {}
        csvLines = csvResult.trim().split("\n")
        for line in csvLines
            t = line.split(",")
            if !t[0].startsWith(thisYear) then continue
            if t[1] then dateToValue[t[0]] = t[1]

        # olog dateToValue
        dates = Object.keys(dateToValue).sort().reverse()
        # log dates

        mrr = parseFloat(dateToValue[dates[0]])
        data.mrr = "#{mrr.toFixed(2)}%"
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

############################################################
export getData = -> data
