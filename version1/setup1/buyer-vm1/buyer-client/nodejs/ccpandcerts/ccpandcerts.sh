function inline_cert {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function ccp {
    local PP0=$(inline_cert $6)
    local PP1=$(inline_cert $7)
    local CP=$(inline_cert $8)
    local IS=$(inline_cert $9)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${prefix}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${P1PORT}/$4/" \
        -e "s/\${CAPORT}/$5/" \
        -e "s#\${PEER0PEM}#$PP0#" \
        -e "s#\${PEER1PEM}#$PP1#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${ISSPEM}#$IS#" \
        ${PWD}/ccp-template.json
}

function client {
    local CLP=$(inline_cert $2)
    local CSK=$(inline_cert $3)
    sed -e "s/\${ORG}/$1/" \
        -e "s#\${CLIPEM}#$CLP#" \
        -e "s#\${CLISK}#$CSK#" \
        ${PWD}/client-cert-template.json
}

ORG=buyer
prefix=b
P0PORT=7051
P1PORT=8051
CAPORT=7054
PEER0PEM=${PWD}/../../../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/tlscacerts/tls-localhost-7054-ca-buyer-GOnetwork-com.pem
PEER1PEM=${PWD}/../../../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/tlscacerts/tls-localhost-7054-ca-buyer-GOnetwork-com.pem
CAPEM=${PWD}/../../../create-cryptomaterial-buyer/fabric-ca/buyer/ca-cert.pem
ISSPEM=${PWD}/../../../../issuer-vm3/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/tlscacerts/tls-localhost-10054-ca-issuer-GOnetwork-com.pem
CLIPEM=${PWD}/../../../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp/signcerts/cert.pem
CLISK=${PWD}/../../../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp/keystore/*

echo "$(ccp $ORG $prefix $P0PORT $P1PORT $CAPORT $PEER0PEM $PEER1PEM $CAPEM $ISSPEM)" > ${PWD}/ccp-buyer.json
echo "$(client $ORG $CLIPEM $CLISK)" > ${PWD}/client-cert-buyer.json