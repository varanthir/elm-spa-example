# !/bin/sh

set -e

rm -fr dist
mkdir dist

cp src/index.html dist/index.html
cp src/style.css dist/style.css

elmLive="./node_modules/elm-live/bin/elm-live.js"

$elmLive src/Main.elm --dir=dist --pushstate --proxy-prefix=/api --proxy-host=http://localhost:3000 -- --debug --output=dist/elm.js
