(use sh)
(import spork/json)

(defn disks []
  "Get information on all the disks in the system"
  (def disks-json ($< lsblk -o "name,serial,size,uuid,path" --json))
  (as-> disks-json _
        (json/decode _)
        (get _ "blockdevices")))

(defn choose-disk []
  "Interactivly choose a disk"
  (def disks-text (as-> (disks) _
                      (map (fn [disk] (string/format "%s\tsize:%s\tserial:%s" (get disk "path") (get disk "size") (get disk "serial"))) _)
                      (string/join _ "\n")))
  (string/trim
    ($< echo ,disks-text | fzf --preview "lsblk -o name,size,ro,type,mountpoint,label,parttypename $(echo {} | cut -f1 -d'\t')" --preview-window up --preview-label "Disk Details")))

(defn main
  [& args]
  (def disk (choose-disk))
  (print "You chose: " disk))
