(declare-project
  :name "installatore"
  :description ```Barebones NixOS installer```
  :version "0.0.0"
  :dependencies ["spork"])

(declare-executable
  :name "installatore"
  :entry "src/init.janet"
  :install true)
