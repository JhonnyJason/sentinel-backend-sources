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

    if cfg.testRun?
        switch(cfg.testRun)
            when "japanMRR" then await requestMRR()
            when "japanHICP" then await requestHICP()
            when "japanGDPG" then await requestGDPG()
    else 
        await requestMRR()
        await requestHICP()
        await requestGDPG()

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
        
        params = new URLSearchParams({
            appId: cfg.estatAPIKey,
            lang: "E",
            statsDataId: "0003427113",
            cdArea: "00000",
            cdCat01: "0001",
            cdTab: "3",
            # cdTime: "#{lastYear}01"
            metaGetFlg: "N",
            cntGetFlg: "N",
            explanationGetFlg:"N",
            annotationGetFlg: "N",
            sectionHeaderFlg: "1",
            replaceSpChars: "0"
        })

        url = "http://api.e-stat.go.jp/rest/3.0/app/json/getStatsData?#{params.toString()}"
        response = await fetch(url)
        hicpData = await response.json()
        hicpData = hicpData.GET_STATS_DATA.STATISTICAL_DATA.DATA_INF.VALUE

        timeToValue = {}

        for d in hicpData when d["@time"].startsWith(lastYear) || d["@time"].startsWith(thisYear)
            timeToValue[d["@time"]] = d["$"]

        orderedTimeLine = Object.keys(timeToValue).sort().reverse()
        # olog orderedTimeLine
        hicp = parseFloat(timeToValue[orderedTimeLine[0]])
        data.hicp = "#{hicp.toFixed(2)}%"
        olog data

    catch err then log err
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    try
    
        url = "https://www.e-stat.go.jp/en/stat-search/file-download?statInfId=000040283486&fileKind=1" # Quarterly Estimates of Real GDP (seasonally adjusted) -> csv file
        response = await fetch(url) 
        gdpCSV = await response.text()

        csvLines = gdpCSV.split("\n")
        csvLines = csvLines.slice(-10)

        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"

        isRelevant = (line) ->
            return line.startsWith("#{lastYear}/ 1- 3.") || line.startsWith("#{thisYear}/ 1- 3.") || line.startsWith("/ 4- 6.") || line.startsWith("/ 7- 9.") || line.startsWith("/ 10- 12.")

        relevantLines = csvLines.filter(isRelevant)
        # olog relevantLines
        t = relevantLines[relevantLines.length - 1].split(",")
        gdpg = parseFloat(t[1])
        data.gdpg = "#{gdpg.toFixed(2)}%"

        olog { data }    

        return

    catch err then log err
    return

############################################################
export getData = -> data
