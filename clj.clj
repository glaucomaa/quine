(ns quine.core)

(def s "(ns quine.core)\n\n(def s %s)\n\n(print (format s (pr-str s)))\n")

(print (format s (pr-str s)))
