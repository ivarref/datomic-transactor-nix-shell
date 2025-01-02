(ns demo
  (:require [datomic.api :as d]
            [clojure.pprint :as pp]))

; Code from:
; https://docs.datomic.com/peer-tutorial/peer-tutorial.html

(def db-uri "datomic:dev://localhost:4334/hello")

(d/create-database db-uri)

(def conn (d/connect db-uri))

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

(defn demo [_]
  (println "Starting")
  @(d/transact conn movie-schema)
  @(d/transact conn first-movies)
  (let [db (d/db conn)]
    (pp/pprint (d/q all-movies-q db)))
  (println "Exiting"))

(defn read-only [_]
  (println "Starting")
  (let [db (d/db conn)]
    (pp/pprint (d/q all-movies-q db)))
  (println "Exiting"))

