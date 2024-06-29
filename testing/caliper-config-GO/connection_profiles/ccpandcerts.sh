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


function setGlobalsforbuyer {
    ORG=buyer
    prefix=b
    P0PORT=7051
    P1PORT=8051
    CAPORT=7054
    #PEER0PEM=${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/tlscacerts/tls-localhost-7054-ca-buyer-GOnetwork-com.pem
    PEER0PEM=${PWD}/../../crypto-config/peerOrganizations/buyer.GOnetwork.com/tlsca/tlsca.buyer.GOnetwork.com-cert.pem
    #PEER1PEM=${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/tlscacerts/tls-localhost-7054-ca-buyer-GOnetwork-com.pem
    PEER1PEM=${PWD}/../../crypto-config/peerOrganizations/buyer.GOnetwork.com/tlsca/tlsca.buyer.GOnetwork.com-cert.pem
    #CAPEM=${PWD}/../create-cryptomaterial-buyer/fabric-ca/buyer/ca-cert.pem
    CAPEM=${PWD}/../../crypto-config/peerOrganizations/buyer.GOnetwork.com/ca/ca.buyer.GOnetwork.com-cert.pem
    #ISSPEM=${PWD}/../../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/tlscacerts/tls-localhost-10054-ca-issuer-GOnetwork-com.pem
    ISSPEM=${PWD}/../../crypto-config/peerOrganizations/issuer.GOnetwork.com/tlsca/tlsca.issuer.GOnetwork.com-cert.pem
}

function setGlobalsforeproducer {
    ORG=buyer
    prefix=b
    P0PORT=9051
    P1PORT=1051
    CAPORT=8054
    #PEER0PEM=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/tlscacerts/tls-localhost-8054-ca-eproducer-GOnetwork-com.pem
    PEER0PEM=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/tlsca/tlsca.eproducer.GOnetwork.com-cert.pem
    #PEER1PEM=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/tlscacerts/tls-localhost-8054-ca-eproducer-GOnetwork-com.pem
    PEER1PEM=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/tlsca/tlsca.eproducer.GOnetwork.com-cert.pem
    #CAPEM=${PWD}/../create-cryptomaterial-buyer/fabric-ca/eproducer/ca-cert.pem
    CAPEM=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/ca/ca.eproducer.GOnetwork.com-cert.pem
    #ISSPEM=${PWD}/../../issuer-vm3/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/tlscacerts/tls-localhost-10054-ca-issuer-GOnetwork-com.pem
    ISSPEM=${PWD}/../../issuer-vm3/crypto-config/peerOrganizations/issuer.GOnetwork.com/tlsca/tlsca.issuer.GOnetwork.com-cert.pem
}

function executebuyer {
    setGlobalsforbuyer
    echo "$(ccp $ORG $prefix $P0PORT $P1PORT $CAPORT $PEER0PEM $PEER1PEM $CAPEM $ISSPEM)" > ${PWD}/ccp-buyer.json
}

function executeeproducer {
    setGlobalsforeproducer
    echo "$(ccp $ORG $prefix $P0PORT $P1PORT $CAPORT $PEER0PEM $PEER1PEM $CAPEM $ISSPEM)" > ${PWD}/ccp-eproducer.json
}

executebuyer