# !/bin/sh

set -e

rm -fr build
mkdir build

elm="./node_modules/elm/bin/elm"
uglifyjs="./node_modules/uglify-js/bin/uglifyjs"

js1="build/elm_1.js"
js2="build/elm_2.js"
min="build/elm.js"

$elm make --optimize --output=$js1 src/Main.elm

$uglifyjs $js1 --output=$js2 --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe'
$uglifyjs $js2 --output=$min --mangle

echo "Compiled size: $(cat $js1 | wc -c) bytes  ($js1)"
echo "Minified size: $(cat $min | wc -c) bytes  ($min)"
echo "Gzipped size: $(cat $min | gzip -c | wc -c) bytes"

rm $js1 $js2

cp src/index.html build/index.html
cp src/style.css build/style.css
