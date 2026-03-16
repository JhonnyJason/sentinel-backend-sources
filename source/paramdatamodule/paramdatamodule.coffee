############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("paramdatamodule")
#endregion

############################################################
import * as cachedData from "cached-persistentstate"

############################################################
historicEntries  = Object.create(null)
published = null

############################################################
store = null
STOREKEY = "paramData"
############################################################
save = -> await cachedData.save(STOREKEY)

############################################################
export initialize = ->
    log "initialize"
    store = cachedData.load(STOREKEY)
    if !store.historicEntries? or !store.published?
        store = { historicEntries, published }
        cachedData.save(STOREKEY, store)
    else
        historicEntries = store.historicEntries
        published = store.published
    return

############################################################
#region exported functions
export getPublishedSnapshot = ->
    log "getPublishedSnapshot"
    return null unless published?
    entries = historicEntries[published.name]
    idx = published.version - 1

    return null unless entries?    
    snapshot = entries[idx]
    
    return null unless snapshot?
    return snapshot

export getSnapshotData = ->
    log "getSnapshotData"
    return null unless Object.keys(historicEntries).length > 0
    return store

export createEntry = ({ name, snapshot }) ->
    log "createEntry"
    historicEntries[name] = [] unless historicEntries[name]?
    historicEntries[name].push(snapshot)
    return save()

export saveEntry = ({ name, version, snapshot }) ->
    log "saveEntry"
    idx = version - 1
    throw new Error("Invalid Version Number!") unless idx >= 0
    historicEntries[name][idx] = snapshot
    return save()

export publishEntry = ({ name, version }) ->
    log "publishEntry"
    idx = version - 1
    throw new Error("Invalid Version Number!") unless idx >= 0
    throw new Error("Snapshot name does not exist!") unless historicEntries[name]?
    throw new Error("Version does not exist!") unless historicEntries[name][idx]?
    published = { name, version }
    store.published = published
    return save()

export renameEntry = ({ oldName, newName }) ->
    log "renameEntry"
    throw new Error("Old Snapshot name does not exist!") unless historicEntries[oldName]?
    throw new Error("New Snapshot name already exists!") unless !historicEntries[newName]?
    historicEntries[newName] = historicEntries[oldName]
    delete historicEntries[oldName]
    return save()

#endregion


############################################################
# sample snapshot - only for the purpose of knowing the structure
snapshot = {
  areaParams: {
    eurozone: { 
        infl: { a: 1.111, b: 0.444, c: -0.056 }
        mrr: { f: -2.2, n: 2.0, c: 5.5, s: 1.2 }
        gdpg: { a: 1.5, b: 0.5, c: -0.125 }
        cot: { n: 50, e: 1.6 } 
    },
    usa: {
        infl: { a: 1.111, b: 0.444, c: -0.056 }
        mrr: { f: -1.7, n: 2.7, c: 6.0, s: 1.2 }
        gdpg: { a: 1.383, b: 0.494, c: -0.099 }
        cot: { n: 50, e: 1.6 }

    }, 
    japan: { 
        infl: { a: 1.587, b: 0.331, c: -0.066 }
        mrr: { f: -1, n: 0.5, c: 3.5, s: 1.2 }
        gdpg: { a: 1.875, b: 0.25, c: -0.125 }
        cot: { n: 50, e: 1.6 }
    },
    uk: {
        infl: { a: 1.111, b: 0.444, c: -0.056 }
        mrr: { f: -2, n: 2.5, c: 6.0, s: 1.2 }
        gdpg: { a: 1.5, b: 0.5, c: -0.125 }
        cot: { n: 50, e: 1.6 }
    },
    canada: {
        infl: { a: 1.111, b: 0.444, c: -0.056 }
        mrr: { f: -2, n: 2.5, c: 6.0, s: 1.2 }
        gdpg: { a: 1.5, b: 0.5, c: -0.125 }
        cot: { n: 50, e: 1.6 }
    },
    australia: {
        infl: { a: 0.611, b: 0.556, c: -0.056 }
        mrr: { f: -2, n: 2.9, c: 7.0, s: 1.2 }
        gdpg: { a: 0.875, b: 0.75, c: -0.125 }
        cot: { n: 50, e: 1.6 }
    },
    switzerland: {
        infl: { a: 1.587, b: 0.331, c: -0.066 }
        mrr: { f: -1, n: 0.8, c: 4.0, s: 1.2 }
        gdpg: { a: 1.875, b: 0.25, c: -0.125 }
        cot: { n: 50, e: 1.6 }
    },
    newzealand: {
        infl: { a: 0.611, b: 0.556, c: -0.056 }
        mrr: { f: -2, n: 2.9, c: 7.0, s: 1.2 }
        gdpg: { a: 0.875, b: 0.75, c: -0.125 }
        cot: { n: 50, e: 1.6 }
    }
  },

  globalParams: {
    diffCurves: { 
        infl: { b: 1.25, d: 0.313 }
        mrr:  { b: 1.25, d: 0.313 }
        gdpg: { b: 1.25, d: 0.313 }
        cot:  { b: 1.25, d: 0.313 }
    },
    finalWeights: { 
        st: { i: 14, l: 28, g: 8, c: 51, f: 13  }   # short term
        ml: { i: 8, l: 8, g: 4, c: 5, f:13 }   # medium-long term
        lt: { i: 8, l: 5, g: 7, c: 1, f: 13 }   # long term
    }
  }
}
