(use sh)

(defn main
  [& args]
  # Choose a file
  (def file ($< ls | fzf))
  (print "You chose: " file))
