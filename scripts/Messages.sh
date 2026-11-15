#!/bin/sh
set -eu

cd "$(dirname "$0")"
mkdir -p po
"${XGETTEXT:-xgettext}" --language=JavaScript --from-code=UTF-8 \
    --keyword= --keyword=i18n:1 --keyword=i18nc:1c,2 \
    --keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
    --add-comments=TRANSLATORS: --package-name="UniFi Status" \
    --output=po/plasma_applet_com.democe.unifistatus.pot \
    contents/config/*.qml contents/ui/*.qml
