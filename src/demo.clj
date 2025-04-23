(ns demo
  (:require [datomic.api :as d]
            [clojure.pprint :as pp])
  (:import (datomic Datom)
           (java.util.concurrent BlockingQueue LinkedBlockingQueue TimeUnit)))

; Code from:
; https://docs.datomic.com/peer-tutorial/peer-tutorial.html

(set! *warn-on-reflection* true)

(def db-uri "datomic:sql://app?jdbc:sqlite:./transactor/storage/sqlite.db")

(def conn
  (do
    (d/delete-database db-uri)
    (d/create-database db-uri)
    (d/connect db-uri)))

(defn multicast-queue!
  [conn consumer-ids]
  (assert (vector? consumer-ids))
  (assert (pos-int? (count consumer-ids)))
  (let [multi-queues (mapv (fn [_] (LinkedBlockingQueue.)) consumer-ids)
        running? (atom true)
        push-counter (atom 0)
        input-queue (d/tx-report-queue conn)
        fut (future
              (while @running?
                (let [element (.poll ^BlockingQueue input-queue 1 TimeUnit/SECONDS)]
                  (when (some? element)
                    (doseq [q multi-queues]
                      (.put ^BlockingQueue q element))
                    (swap! push-counter inc))))
             :push-thread-done)
        close-fn (fn []
                   (do
                     (d/remove-tx-report-queue conn)
                     (reset! running? false)
                     @fut))]
    (with-meta (zipmap consumer-ids multi-queues)
               {:push-counter push-counter
                :close! close-fn})))

(def movie-schema [{:db/ident       :movie/title
                    :db/valueType   :db.type/string
                    :db/cardinality :db.cardinality/one
                    :db/unique      :db.unique/identity     ; https://docs.datomic.com/schema/schema-reference.html#db-unique
                    :db/doc         "The title of the movie"}

                   {:db/ident       :movie/genre
                    :db/valueType   :db.type/string
                    :db/cardinality :db.cardinality/one
                    :db/doc         "The genre of the movie"}

                   {:db/ident       :movie/release-year
                    :db/valueType   :db.type/long
                    :db/cardinality :db.cardinality/one
                    :db/doc         "The year the movie was released in theaters"}])

(def first-movies [{:movie/title        "The Goonies"
                    :movie/genre        "action/adventure"
                    :movie/release-year 1985}
                   {:movie/title        "Commando"
                    :movie/genre        "action/adventure"
                    :movie/release-year 1985}
                   {:movie/title        "Repo Man"
                    :movie/genre        "punk dystopia"
                    :movie/release-year 1984}])

(def all-movies-q '[:find [(pull ?e [*]) ...]               ; https://docs.datomic.com/query/query-data-reference.html#find-specs
                    :where [?e :movie/title]])

(defn get-tx-data [elem]
  (assert (some? (get elem :tx-data)))
  (->> (get elem :tx-data)
       (drop 1)
       (mapv (fn [^Datom dtm]
               [(.e dtm) (.a dtm) (.v dtm) (.tx dtm) (.added dtm)]))
       (sort)
       (vec)))

(def tx-data-expected
  [[17592186045418 72 "The Goonies" 13194139534313 true]
   [17592186045418 73 "action/adventure" 13194139534313 true]
   [17592186045418 74 1985 13194139534313 true]
   [17592186045419 72 "Commando" 13194139534313 true]
   [17592186045419 73 "action/adventure" 13194139534313 true]
   [17592186045419 74 1985 13194139534313 true]
   [17592186045420 72 "Repo Man" 13194139534313 true]
   [17592186045420 73 "punk dystopia" 13194139534313 true]
   [17592186045420 74 1984 13194139534313 true]])

(defn demo-unicast [_]
  (println "Starting unicast")
  @(d/transact conn movie-schema)
  (let [q (d/tx-report-queue conn)]
    @(d/transact conn first-movies)
    (let [element (.poll ^BlockingQueue q 3 TimeUnit/SECONDS)]
      (assert (not (nil? element)))
      (assert (= tx-data-expected (get-tx-data element)))))
  (println "Done unicast"))

(defn demo-multicast [_]
  (println "Starting multicast")
  @(d/transact conn movie-schema)
  (let [{:keys [q1 q2] :as qs} (multicast-queue! conn [:q1 :q2])
        {:keys [close!]} (meta qs)]
    @(d/transact conn first-movies)
    (let [elem-1 (.poll ^BlockingQueue q1 3 TimeUnit/SECONDS)
          elem-2 (.poll ^BlockingQueue q2 3 TimeUnit/SECONDS)]
      (assert (some? elem-1))
      (assert (some? elem-2))
      (assert (= tx-data-expected (get-tx-data elem-1)))
      (assert (= tx-data-expected (get-tx-data elem-2)))
      (assert (= :push-thread-done (close!)))))
  (println "Done multicast"))

(defn read-only [_]
  (println "Starting")
  (let [db (d/db conn)]
    (pp/pprint (d/q all-movies-q db)))
  (println "Exiting"))
