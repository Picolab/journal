ruleset io.picolabs.journal {
  meta {
    name "Pico Journal"
    description <<
        Provides basic journalling for a pico.
    >>
    author "BAC"
    shares __testing, entries, entriesBetween
  }
  global {
    __testing = { "queries": [ { "name": "__testing" }
                             , { "name": "entries" }
                             , { "name": "entriesBetween", "args": [ "startDate", "endDate" ] }
                             ]
                , "events": [ { "domain": "journal", "type": "new_entry", "attrs": [ "memo" ] }
                            ]
                }
    entries = function() {
      ent:entries;
    }
    entriesBetween = function(startDate, endDate) {
      entries().filter(function(e){ startDate<=e{"timestamp"} && e{"timestamp"}<=endDate });
    }
  }
  rule initialize {
    select when wrangler ruleset_added where rids >< meta:rid
    if not ent:entries then noop();
    fired {
      ent:entries := {};
      raise journal event "initialized";
    }
  }
  rule initial_entry {
    select when journal initialized
    fired {
      raise journal event "new_entry" attributes { "memo": "journal initialized" }
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
}
