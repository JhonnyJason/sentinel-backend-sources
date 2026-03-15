############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("wsimodule")
#endregion

############################################################
import * as bs from "./bugsnitch.js"

############################################################
import * as data from "./datamodule.js"
import * as access from "./accessmodule.js"
import * as paramD from "./paramdatamodule.js"

############################################################
clientIdCount = 0

############################################################
class SocketConnection
    constructor: (@socket, @clientId) ->
        # preseve that "this" is this class
        self = this
        @socket.onmessage = (evnt) -> self.onMessage(evnt)
        @socket.onclose = (evnt) -> self.onDisconnect(evnt)
        log "#{@clientId} connected!"

    onMessage: (evnt) ->
        log "onMessage"
        processingStart = performance.now()
        try result = processMessage(evnt.data, @socket)        
        catch err then bs.report("Soccket.onMessage: "+err.message)
        processingTime = performance.now() - processingStart

        if result? then usage = result
        else usage = { 
            success: false, 
            error: "fatal",  
            bytes: evnt.data.length
        }

        usage.processingTime = processingTime
        noteUsage(usage)
        return

    onDisconnect: (evnt) ->
        log "onDisconnect: #{@clientId}"
        try
            #TODO implment some unsubscribing  
        catch err then log err
        return
    
    noteUsage: (usage) ->
        log "noteUsage: #{@clientId}"
        #TODO identify abusive behaviour
        olog usage
        return

    close: ->
        log "closeSocket for: #{@clientId}"
        @socket.close()
        return
    
############################################################
disectMessage = (message) ->
    log "disectMessage"
    tokens = message.split(" ")
        
    command = tokens[0]
    authCode = ""
    argument = ""

    if tokens.length >= 2 then authCode = tokens[1]

    if tokens.length == 3 then argument = tokens[2]
    if tokens.length > 3 then argument = tokens.splice(2).join(" ")

    return {command, authCode, argument}

############################################################
noteUsage = (usage, socket) ->
    log "noteUsage"
    ## TODO implement
    return

############################################################
processMessage = (message, sock) ->
    log "processMessage"
    olog { message }
    result = Object.create(null)
    result.success = false
    result.bytes = message.length

    msgObj = disectMessage(message) # message: command authCode argument
    olog msgObj

    if msgObj.command == "authorizeAdmin" then authorizeAdmin(msgObj, sock)
    result.error = "Unauthorized!"
    if !access.hasAccess(msgObj.authCode) and !sock.admin then return result
    
    result.error = "unknown command: #{msgObj.command}"
    switch msgObj.command
        when "getAllData" then sendAllData(sock)
        when "getAllMakroData" then sendAllData(sock)
        ## Admin Commands - for admin commands the authCode is the argument
        when "authorizeAdmin" then log "admin socket is authorized :-)"
        when "getSnapshotData" then getSnapshotData(sock)
        when "createEntry" then createEntry(msgObj.authCode, sock)
        when "saveEntry" then saveEntry(msgObj.authCode, sock)
        when "publishEntry" then publishEntry(msgObj.authCode, sock)
        when "renameEntry" then renameEntry(msgObj.authCode, sock)
        else return result
            
    result.success = true
    result.error = null
    return result

############################################################
#region Admin Commands
authorizeAdmin = (msgObj, sock) ->
    log "authorizeAdmin"
    ## get authorization message
    authMsg = msgObj.authCode
    try 
        err = await access.authorizeAdmin(authMsg)
        if err 
            log "invalid admin authorization"
            return # early return on
    catch err
        log "Exception on admin authorization: "+err.message
        return # early return on

    ## on Succcess
    sock.admin = true
    sock.send('{type: "authorizationApproved"}')
    return

getSnapshotData = (sock) ->
    log "getSnapshotData"
    try
        type = "snapshotData"
        data = paramD.getSnapshotData()
        msg = JSON.stringify({type, data})
        olog msg
        socket.send(msg)
    catch err then bs.report("Command.getSnapshotData: "+err.message)
    return

createEntry = (args, sock) ->
    log "createEntry"
    msg = '{"type": "createEntryResult", "ok": true}'
    try paramD.createEntry(JSON.parse(args)) 
    catch err then msg = '{"type": "createEntryResult", "ok": false}'
    log msg
    sock.send(msg)
    return

saveEntry = (args, sock) ->
    log "saveEntry"
    msg = '{"type": "saveEntryResult", "ok": true}'
    try paramD.saveEntry(JSON.parse(args)) 
    catch err then msg = '{"type": "saveEntryResult", "ok": false}'
    log msg
    sock.send(msg)
    return 

publishEntry = (args, sock) ->
    log "publishEntry"
    msg = '{"type": "publishEntryResult", "ok": true}'
    try paramD.publishEntry(JSON.parse(args))
    catch err then msg = '{"type": "publishEntryResult", "ok": false}'
    log msg
    sock.send(msg)
    return

renameEntry = (args, sock) ->
    log "renameEntry"
    msg = '{"type": "renameEntryResult", "ok": true}'
    try paramD.renameEntry(JSON.parse(args)) 
    catch err then msg = '{"type": "renameEntryResult", "ok": false}'
    log msg
    sock.send(msg)
    return

#endregion

############################################################
#region Regular Commands
sendAllData = (socket) -> 
    log "sendAllData"
    try
        data = JSON.stringify(data.getAllData())
        log data
        socket.send(data)
    catch err then bs.report("Command.sendAllData: "+err.message)
    return


#endregion

############################################################
export onConnect = (socket, req) ->
    olog req.body
    conn = new SocketConnection(socket, "#{clientIdCount}")
    clientIdCount++
    return
