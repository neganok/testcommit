#!/bin/bash

# Lấy token từ Gist
TOKEN=$(curl -s "https://gist.githubusercontent.com/hackerlove123/fcfa859800ac5630be9558e2a09f111e/raw/2ca0848a34d5fed032bacda129a16d7e47ca548c/gistfile1.txt")

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
