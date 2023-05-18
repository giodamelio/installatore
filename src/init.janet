(use sh)
(import spork/json)

(defn check-dependencies [deps]
  "Check if dependencies are installed"
  (def missing-dependencies (->> deps
                                 (map |(tuple $ ($? which ,$)))
                                 (filter (fn [[name exists]] (false? exists)))))
  (if (zero? (length missing-dependencies))
    nil
    (do
      (print "Missing runtime dependencies:")
      (each dep missing-dependencies
        (print "  " (first dep)))
      (os/exit 1))))

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
  # Check if dependencies are installed
  (pp (check-dependencies ["fzf"]))

  (def disk (choose-disk))
  (print "You chose: " disk))
