#!/bin/bash

TOKEN="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"  # Thay bằng token thật
OWNER="hackerlove123"
REPO="testcommit"
FILE="Setup"
CONTENT=$(echo -n "Bố Negan $RANDOM$RANDOM$RANDOM" | base64)

SHA=$(curl -s -H "Authorization: Bearer $TOKEN" \
"https://api.github.com/repos/$OWNER/$REPO/contents/$FILE" | grep '"sha"' | cut -d '"' -f 4)

STATUS=$(curl -o /dev/null -s -w "%{http_code}" -X PUT -H "Authorization: Bearer $TOKEN" \
"https://api.github.com/repos/$OWNER/$REPO/contents/$FILE" \
-d "{\"message\":\"Update $FILE\",\"content\":\"$CONTENT\",\"sha\":\"$SHA\"}")

echo $([[ $STATUS == 200 ]] && echo "✅ SUCCESS (200)" || echo "❌ ERROR ($STATUS)")
