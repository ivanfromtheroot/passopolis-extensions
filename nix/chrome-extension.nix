{ stdenv, closurecompiler, unzip, nodejs, python, lessc, zip, forge_src, keyzcar_src, chrome-config, node_packages }:
stdenv.mkDerivation {
    name = "passopolis-chrome-extension";
    buildInputs = [
      closurecompiler
      unzip
      nodejs
      python
      lessc
      zip
      node_packages.hogan
      node_packages."hogan.js"
    ];
    srcs = ../../extensions;

    phases = "unpackPhase buildPhase";
    buildPhase = ''
    cd login/

    mkdir -p ext/js

    # deps
    cat ${forge_src}/start.frag ${forge_src}/js/*js ${forge_src}/end.frag > ext/forge.js

    # TODO: the following is almost certainly not necessary but we're adding it
    # to remove diffs.
    cp ${forge_src}/js/* ext/
    cp ${keyzcar_src}/*js ext/

    cp common/*.js ext/
    cp chrome/*.js ext/
    cp chrome/*.js ext/js/
    cp ../api/js/cli/*.js ext/

    # TODO config in two places?
    cp ${chrome-config} ext/config.js
    cp ${chrome-config} ext/js/config.js

    cp -r ./frontend/static/css/ ext/css
    cp -r ./frontend/static/fonts/ ext/fonts
    cp -r ./frontend/static/img/ ext/img
    cp -r ./frontend/static/js/* ext/js

    lessc --strict-imports --strict-math=on --strict-units=on ./frontend/static/less/site.less > ext/css/site.css
    lessc --strict-imports --strict-math=on --strict-units=on ./frontend/static/less/mitro_popup2.less > ext/css/mitro_popup2.css

    python assign_scripts.py chrome chrome/manifest.json ext/

    # Due to iframe origins, we inject the HTML as Javascriptconfg (see makefile)
    python ./makejsresource.py common/infobar.html ext/infobar_html.js

    mkdir -p ext/html/
    for t in $(find frontend/templates/*mustache); do
        node ./mustache_renderer.js $t ext/html/$(basename $t .mustache).html
    done

    for t in $(find frontend/partials/*mustache); do
      hulk $t > ext/js/$(basename $t .mustache).js
    done

    # Remove tests
    find ext/ | egrep "(_test.js|_regtest.js|_regtest2.js)$" | xargs rm
    find ext/ | grep csv$ | xargs rm

    mkdir $out
    cp -r ext/* $out
    '';
}
