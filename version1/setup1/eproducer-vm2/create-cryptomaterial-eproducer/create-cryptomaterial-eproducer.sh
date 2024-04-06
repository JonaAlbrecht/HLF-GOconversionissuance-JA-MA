#this creates the crypto material for eproducer organisation using fabric-samples binary "fabric-ca-client"
#and using the root certificate authority of the issuing body 

createCertificateForeproducer() {
  
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/
  
# enroll the ca for buyer org cryptomaterial creation, the flag --tls.certfiles paths to the issuing body certificate authority root certificate
  fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 --caname ca.issuer.GOnetwork.com --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-issuer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-issuer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-issuer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-issuer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "Register e-peer0"
  echo

  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name e-peer0 --id.secret e-peer0pw --id.type peer --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register e-peer1"
  echo

  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name e-peer1 --id.secret e-peer1pw --id.type peer --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register SmartMeter"
  echo

# this creates the Smart Meter x509 certificate with the attributes "trusted device = true, maxefficiency = 50 kW and technologyType = solar, emission intensity of 41grams of CO2 per kilowatthour"
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name SmartMeter1 --id.secret Meter1pw --id.type client --id.attrs 'electricitytrustedDevice=true:ecert,maxEfficiency=50:ecert,technologyType=solar:ecert,emissionIntensity=41:ecert' --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register the org admin"
  echo

  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name eproduceradmin --id.secret eproduceradminpw --id.type admin --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com

  

  # --------------------------------------------------------------
  # Peer 0
  echo
  echo "## Generate the e-peer0 msp"
  echo

  fabric-ca-client enroll -u https://e-peer0:e-peer0pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/msp --csr.hosts e-peer0.eproducer.GOnetwork.com --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the e-peer0-tls certificates"
  echo

  fabric-ca-client enroll -u https://e-peer0:e-peer0pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts e-peer0.eproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/tlsca/tlsca.eproducer.GOnetwork.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/ca/ca.eproducer.GOnetwork.com-cert.pem

  # --------------------------------------------------------------------------------
  #  Peer 1
  echo
  echo "## Generate the e-peer1 msp"
  echo

  fabric-ca-client enroll -u https://e-peer1:e-peer1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/msp --csr.hosts e-peer1.eproducer.GOnetwork.com --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the e-peer1-tls certificates"
  echo

  fabric-ca-client enroll -u https://e-peer1:e-peer1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts e-peer1.eproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/server.key
  # -----------------------------------------------------------------------------------

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com

  echo
  echo "## Generate the SmartMeter msp"
  echo

  fabric-ca-client enroll -u https://SmartMeter1:Meter1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/Admin@eproducer.GOnetwork.com

  #copy the Node OU configuration file into the Smart Meter msp folder --> this is necessary for attribute-based chaincode invoke  
  cp "${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml" "${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp/config.yaml"

  echo
  echo "## Generate the org admin msp"
  echo

  fabric-ca-client enroll -u https://eproduceradmin:eproduceradminpw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/Admin@eproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/Admin@eproducer.GOnetwork.com/msp/config.yaml

}

createCertificateForeproducer