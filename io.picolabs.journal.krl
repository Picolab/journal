ruleset io.picolabs.journal {
  meta {
    name "Pico Journal"
    description <<
        Provides basic journalling for a pico.
    >>
    author "BAC & TEDRUB"
    shares __testing, entries, entriesBetween, tile
  }
  global {
    // ---------- Manifold Configuration/Dependencies 
    app = {"name":"journalling","version":"0.0"/* img: , pre: , ..*/};
    getEntries = function(){
      ent:entries.values().reverse().filter(function(v,k){k<3});
    } 
    bindings = function(){
      {
        "entries": getEntries()
      };
    }
    // ---------- 
    __testing = { "queries": [ { "name": "__testing" }
                             , { "name": "entries" }
                             , { "name": "entriesBetween", "args": [ "startDate", "endDate" ] }
                             , { "name": "tile" }
                             ]
                , "events": [ { "domain": "journal", "type": "new_entry", "attrs": [ "title", "memo" ] }
                            , { "domain": "manifold", "type": "apps" }
                            , { "domain": "manifold", "type": "tile" }
                            ]
                }
    entries = function() {
      ent:entries;
    }
    entriesBetween = function(startDate, endDate) {
      entries().filter(function(e){ startDate<=e{"timestamp"} && e{"timestamp"}<=endDate });
    }
  }
  // ---------- Manifold required API event calls  
  rule discovery { select when manifold apps send_directive("app discovered...", {"app": app, "rid": meta:rid, "bindings": bindings()} ); }
  rule tile { select when manifold tile send_directive("retrieved tile ", {"app": tile()}); }
  // ---------- 

  // ---------- journalling rules 
  rule initialize { // when app installed, raise initialized event.
    select when wrangler ruleset_added where rids >< meta:rid
    if not ent:entries then noop();
    fired {
      ent:entries := {};
      raise journal event "initialized";
    }
  }
  rule initial_entry { // when initialized, raise new_entry event with journal initialized memo.
    select when journal initialized
    fired {
      raise journal event "new_entry" attributes { "memo": "Journal Initialized", "title": "First Entry" }
    }
  }
  rule journal_new_entry {
    select when journal new_entry
    pre {
      timestamp = time:now();
      entry = event:attrs().put("timestamp", timestamp);
    }
    fired {
      ent:entries{timestamp} := entry;
      raise journal event "entry_added" attributes entry;
    }
  }
  // ---------- 
}
