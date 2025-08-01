############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("zealanddata")
#endregion

# ############################################################
# import *  as yauzl from "yauzl"

# ############################################################
# promisify = (api) ->
#     return (...args) -> 
#         return new Promise (resolve, reject) ->
#             api(
#                 ...args, 
#                 (err, response) ->
#                     if err then  return reject(err);
#                     resolve(response);
#             )
        
# ############################################################
# yauzlFromBuffer = promisify(yauzl.fromBuffer)

import * as xlsx from "xlsx"

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
    data.hicp = "i.NZ"
    data.mrr = "r.NZ"
    data.gdpg = "g.NZ"

    heartbeatMS = cfg. statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return

# https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/b/b2/hb2-daily.xlsx # interest rates # column 0: daily dates, column 1: OCR

# https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/m/m1/hm1.xlsx # consumer prices # column 0: months, column 1: CPI LVL, column 3: CPI YoY%

# https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/m/m5/hm5.xlsx # gdp # coumn 0: months, column2: real SA GDP LVL, column 3: Real SA GDP QoQ%


############################################################
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "zealandMRR" then await requestMRR()
            when "zealandHICP" then await requestHICP()
            when "zealandGDPG" then await requestGDPG()
    else
        await requestMRR()
        await requestHICP()
        await requestGDPG()
    return

############################################################
requestMRR = ->
    log "requestMRR"
    try
        # response = await fetch("https://www.bankofengland.co.uk/boeapps/database/Bank-Rate.asp")
        # htmlResponse = await response.text()
        
        # parts = htmlResponse.split('<div class="featured-stat">')
        
        # if parts.length != 2 then throw new Error("Unexpected HTML structure!")
        # parts = parts[1].split('<p class="stat-figure">')
        # if parts.length != 2 then throw new Error("Unexpected HTML structure!")

        # parts = parts[1].split("</p>")
        # mrr = parseFloat(parts[0])
        # # log mrr

        # data.mrr = "#{mrr.toFixed(2)}%"
        # olog data

    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try
        url = "https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/m/m1/hm1.xlsx"
        response = await fetch(url)
        xlsxBuffer = await response.arrayBuffer()
        log "before reading xlsx"
        sheets = xlsx.read(xlsxBuffer)
        log "after reading xlsx"
        log sheets.SheetNames
        # xlsxBytes = await response.bytes()
        # xlsxBuffer = Buffer.from(xlsxBytes)
        # zipFile = await yauzlFromBuffer(xlsxBuffer, {lazyEntries: true})
        # log "entries: #{zipfile.entryCount}"
        return
        # log csvResponse

        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"
        yearBefore = "#{date.getFullYear() - 2}"
        
        keysToData = {}
        for m in months
            key = "#{thisYear} #{m}"
            keysToData[key] = true
            key = "#{lastYear} #{m}"
            keysToData[key] = true
            key = "#{yearBefore} #{m}"
            keysToData[key] = true
        olog keysToData

        latestKey = null
        csvLines = csvResponse.split("\n")
        for line in csvLines
            cells = line.split(",")
            key = cells[0].trim().replaceAll("\"", "")
            # log key

            if keysToData[key]
                value = parseFloat(cells[1].trim().replaceAll("\"", ""))
                keysToData[key] = value
                latestKey = key

        ts = latestKey.split(" ")
        latestKeyYear = parseInt(ts[0])
        yearBeforeKey = "#{latestKeyYear - 1} #{ts[1]}"

        olog keysToData
        hicpBefore = keysToData[yearBeforeKey]
        hicpNow = keysToData[latestKey]
        
        olog {hicpBefore, hicpNow}

        hicp = (100.0 * hicpNow / hicpBefore) - 100
        data.hicp = "#{hicp.toFixed(2)}%"
        
        olog {data}
    catch err then log err
    return

############################################################
requestGDPG = ->
    ## Here we want Annualized QoQ growth of Real GDP 
    #  -> Adjusted for inflation, Seasonality and Calendar 
    try
        # url = "https://www.ons.gov.uk/generator?format=csv&uri=/economy/grossdomesticproductgdp/timeseries/abmi/pn2"
        # response = await fetch(url)
        # csvData = await response.text()        
        # csvLines = csvData.split("\n")
        # olog csvLines

        # date = new Date()
        # thisYear = "#{date.getFullYear()}"
        # lastYear = "#{date.getFullYear() - 1}"

        # isRelevant = (label) ->
        #     # log "isRelevant"
        #     label = label.trim().replaceAll("\"", "")
        #     ts = label.split(" ")
        #     # olog ts
        #     return false unless ts[0] == thisYear || ts[0] == lastYear
        #     return true if ts[1] == "Q1" || ts[1] == "Q2" || ts[1] == "Q3" || ts[1] == "Q4"
        #     return false

        # # Here we assume that the last 2 relevant entries are the latest two consecutive Quarters
        # latestGDP = 0
        # gdpBefore = 0
        # for line in csvLines
        #     ts = line.split(",")
        #     if isRelevant(ts[0])
        #         log "#{ts[0]} was relevant!" 
        #         gdpBefore = latestGDP
        #         latestGDP = parseFloat(ts[1].trim().replaceAll("\"", ""))
                

        # gdpgQ = (100.00 * latestGDP / gdpBefore) - 100
        # gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        # data.gdpg = "#{gdpgA.toFixed(2)}%"
        # olog { gdpgQ, gdpgA, data }    
        
    catch err then log err
    return

############################################################
export getData = -> data
