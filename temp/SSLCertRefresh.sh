certbot certonly --manual --preferred-challenges=dns -d *.derektank.com -d derektank.com -m tank.derek@gmail.com --agree-tos --no-eff-email

#Text parsing to pull the certbot DNS TXT record

#Route53 command to update TXT Record

#Pause and wait command (or call out to google checker) to press enter only after DNS records have proliferated

FULLCHAIN=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ~/fullchain.pem) #Requires update to filepath
PRIVKEY=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ~/privkey.pem)

jq -n --arg cert "$FULLCHAIN" --arg key "$PRIVKEY" '{"NGINXSSLCert": $cert, "NGINXSSLPrivkey": $key}' > ~/secret.json

aws secretsmanager update-secret --secret-id derektank.com_SSL --region us-west-2 --secret-string file://~/secret.json
