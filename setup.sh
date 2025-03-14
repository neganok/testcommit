#!/bin/bash

# Lấy token từ Gist
TOKEN=$(curl -s "https://gist.githubusercontent.com/hackerlove123/fcfa859800ac5630be9558e2a09f111e/raw/996606df07570dbd120a34ea9ce7b2c6bb5489d0/gistfile1.txt")

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
