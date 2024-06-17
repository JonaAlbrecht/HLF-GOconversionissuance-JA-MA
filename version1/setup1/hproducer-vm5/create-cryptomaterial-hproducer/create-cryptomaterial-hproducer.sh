#this creates the crypto material for the hydrogen producer organisation using fabric-samples binary "fabric-ca-client"
#and using the root certificate authority of the issuing body 

cd $(dirname $0)

createCertificateForhproducer() {
  
  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/
  
# enroll the ca for hydrogen producer org cryptomaterial creation, the flag --tls.certfiles paths to the hydrogen producer certificate authority root certificate
  fabric-ca-client enroll -u https://admin:adminpw@localhost:11054 --caname ca.hproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-hproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-hproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-hproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-hproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "Register h-peer0"
  echo
  sleep 1

  fabric-ca-client register --caname ca.hproducer.GOnetwork.com --id.name h-peer0 --id.secret h-peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  echo
  echo "Register h-peer1"
  echo

  fabric-ca-client register --caname ca.hproducer.GOnetwork.com --id.name h-peer1 --id.secret h-peer1pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  echo
  echo "Register Trusted User for hydrogen producer"
  echo

# this creates the Trusted User for the hydrogen organisation which will be authorized to transfer hydrogen GOs 
  fabric-ca-client register --caname ca.hproducer.GOnetwork.com --id.name hTrustedUser --id.secret hTrustedUserpw --id.type client --id.attrs 'hydrogentrustedUser=true:ecert,TrustedUser=true:ecert' --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem


  echo
  echo "Register the org admins"
  echo

#this creates the admin
  fabric-ca-client register --caname ca.hproducer.GOnetwork.com --id.name outhproduceradmin --id.secret outhproduceradminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers
  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com

# --------------------------------------------------------------
# Peer 0
  echo
  echo "## Generate the h-peer0 msp"
  echo

  fabric-ca-client enroll -u https://h-peer0:h-peer0pw@localhost:11054 --caname ca.hproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/msp --csr.hosts h-peer0.hproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the h-peer0-tls certificates"
  echo

  fabric-ca-client enroll -u https://h-peer0:h-peer0pw@localhost:11054 --caname ca.hproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts h-peer0.hproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/tlsca/tlsca.hproducer.GOnetwork.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/ca/ca.hproducer.GOnetwork.com-cert.pem
# -----------------------------------------------------------------------------------
#Peer 1

  echo
  echo "## Generate the h-peer1 msp"
  echo

  fabric-ca-client enroll -u https://h-peer1:h-peer1pw@localhost:11054 --caname ca.hproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/msp --csr.hosts h-peer1.hproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the h-peer1-tls certificates"
  echo

  fabric-ca-client enroll -u https://h-peer1:h-peer1pw@localhost:11054 --caname ca.hproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts h-peer1.hproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/server.key

# --------------------------------------------------------------------------
# Admin and Trusted User

  echo
  echo "## Generate the Admin msp"
  echo

  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/Admin/oAdmin@hproducer.GOnetwork.com

  fabric-ca-client enroll -u https://outhproduceradmin:outhproduceradminpw@localhost:11054 --caname ca.hproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/Admin/oAdmin@hproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/Admin/oAdmin@hproducer.GOnetwork.com/msp/config.yaml

  #Trusted User

  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser
  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser/hTrustedUser@hproducer.GOnetwork.com

  echo
  echo "## Generate the Trusted User msp"
  echo

  fabric-ca-client enroll -u https://hTrustedUser:hTrustedUserpw@localhost:11054 --caname ca.hproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser/hTrustedUser@hproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/hproducer/tls-cert.pem

  #copy the Node OU configuration file into the Trusted User msp folder --> this is necessary for attribute-based chaincode invoke  
  cp "${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml" "${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser/hTrustedUser@hproducer.GOnetwork.com/msp/config.yaml"
# Caliper Testing
  #if doing a caliper test run, uncomment the line -- also uncomment lines in network-down script
  cp -r ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/ ${PWD}/../../../../testing/crypto-config/peerOrganizations/
}

createCertificateForhproducer