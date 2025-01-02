# Datomic transactor, Java and Clojure nix flake

Ever wanted to `cd` into a directory and have the Datomic transactor, Java and Clojure installed?

If so, this repo is for you.

## Installation

Install [Nix and Direnv](https://determinate.systems/posts/nix-direnv/),
enable [Nix with flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes_permanently_in_NixOS)
and [hook direnv into your shell](https://direnv.net/docs/hook.html).

I am not an expert on these matters, so you may have to google it yourself if you do not already
have installed these things. [](https://mitchellh.com/writing/nix-with-dockerfiles)

## Usage

```bash
cd <folder-of-this-repo>

$ which java
/nix/store/62vbkdvd43x2a9gv0sgsl9fskkhvl00z-zulu-ca-jdk-21.0.4/bin/java

$ java -version
openjdk version "21.0.4" 2024-07-16 LTS
OpenJDK Runtime Environment Zulu21.36+17-CA (build 21.0.4+7-LTS)
OpenJDK 64-Bit Server VM Zulu21.36+17-CA (build 21.0.4+7-LTS, mixed mode, sharing)

# Launch the transactor:
$ transactor.sh # notice the absence of ./
Launching with Java options -server -Xms1g -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=50
System started
(transactor.sh does not exit)

# In a separate terminal:
$ clojure -X:run
Starting
[{:db/id 17592186045418,
  :movie/title "The Goonies",
  :movie/genre "action/adventure",
  :movie/release-year 1985}
 {:db/id 17592186045419,
  :movie/title "Commando",
  :movie/genre "action/adventure",
  :movie/release-year 1985}
 {:db/id 17592186045420,
  :movie/title "Repo Man",
  :movie/genre "punk dystopia",
  :movie/release-year 1984}]
Exiting

# Stop the transactor, do whatever, start the transactor again. And then:
$ clojure -X:read-only
#            ^^^^^^^^^ Reading only this time 
Starting
[{:db/id 17592186045418,
  :movie/title "The Goonies",
  :movie/genre "action/adventure",
  :movie/release-year 1985}
 {:db/id 17592186045419,
  :movie/title "Commando",
  :movie/genre "action/adventure",
  :movie/release-year 1985}
 {:db/id 17592186045420,
  :movie/title "Repo Man",
  :movie/genre "punk dystopia",
  :movie/release-year 1984}]
Exiting
# ^^ The data is still there
```

Yes, that's some Datomic entities transacted into and read from a "proper" Datomic transactor (using the dev protocol and H2 as storage).

## And ... ?

Well, at least it works, right*? *At least on my machine. 😄

The point is that all the versions of Java, the transactor and Clojure
are locked and pinned. And thus you do not *need* a system wide Java installation (or anything else besides
what is mentioned in the Installation section). In some future case where the JVM breaks backwards compatibility,
this repo should still work (as it bundles its own JVM). With this setup you can also of course tweak
the versions per repo (instead of system wide) and also share an easily reproducible environment for others
to use. Just `cd` into the repo, and you should be good to go.

Hope this is useful for someone! 😊

## Further reading

* Mitchell Hashimoto is a [big fan of Nix](https://mitchellh.com/writing/nix-with-dockerfiles).

* [Fasterthanlime aka Amos on nix](https://fasterthanli.me/search?q=nix).

* [NixOS & Nix Flakes - A Guide for Beginners](https://thiscute.world/en/posts/nixos-and-flake-basics/)

How much do you need to know about `nix` to use it? I do not know much, and yet somehow I'm getting by 
just fine. ¯\\_(ツ)_/¯