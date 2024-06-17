#this creates the crypto material for eproducer organisation using fabric-samples binary "fabric-ca-client"
#and using the root certificate authority of the issuing body 

cd $(dirname $0)

createCertificateForeproducer() {
  
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/
  
# enroll the ca for eproducer org cryptomaterial creation, the flag --tls.certfiles paths to the issuing body certificate authority root certificate
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca.eproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-eproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-eproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-eproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-eproducer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "Register e-peer0"
  echo

  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name e-peer0 --id.secret e-peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  echo
  echo "Register e-peer1"
  echo

  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name e-peer1 --id.secret e-peer1pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem


  echo
  echo "Register Trusted User"
  echo

# this creates the trusted user who is authorized to transfer electricity GOs, which is ensured via Attribute-based access control
# the trusted user is enrolled by the eproducer CA bc it is upon the eproducer organisation to ensure GOs are only transferred by a trusted member of their organisation
  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name eTrustedUser --id.secret eTrustedUserpw --id.type client --id.attrs 'electricitytrustedUser=true:ecert,TrustedUser=true:ecert' --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  echo
  echo "Register the org admin"
  echo

  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name eproduceradmin --id.secret eproduceradminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com

  

  # --------------------------------------------------------------
  # Peer 0
  echo
  echo "## Generate the e-peer0 msp"
  echo

  fabric-ca-client enroll -u https://e-peer0:e-peer0pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/msp --csr.hosts e-peer0.eproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the e-peer0-tls certificates"
  echo

  fabric-ca-client enroll -u https://e-peer0:e-peer0pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts e-peer0.eproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

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
# Peer 1

  echo
  echo "## Generate the e-peer1 msp"
  echo

  fabric-ca-client enroll -u https://e-peer1:e-peer1pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/msp --csr.hosts e-peer1.eproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the e-peer1-tls certificates"
  echo

  fabric-ca-client enroll -u https://e-peer1:e-peer1pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts e-peer1.eproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer1.eproducer.GOnetwork.com/tls/server.key

  echo
  echo "## Generate the org admin msp"
  echo

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/Admin/Admin@eproducer.GOnetwork.com

  fabric-ca-client enroll -u https://eproduceradmin:eproduceradminpw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/Admin/Admin@eproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem
# ----------------------------------------------------------------------------------
# Admin and Trusted User

  #copy the eproducer Node Organisational Unit file into Admin folder
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/Admin/Admin@eproducer.GOnetwork.com/msp/config.yaml

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/TrustedUser
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/TrustedUser/eTrustedUser@eproducer.GOnetwork.com

  echo
  echo "## Generate the Trusted User msp"
  echo

  fabric-ca-client enroll -u https://eTrustedUser:eTrustedUserpw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/TrustedUser/eTrustedUser@eproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  #copy the Node OU configuration of the eproducer file into the Trusted User msp folder --> this is necessary for attribute-based chaincode invoke  
  cp "${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml" "${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/TrustedUser/eTrustedUser@eproducer.GOnetwork.com/msp/config.yaml"
  
# Caliper Testing
  #if doing a caliper test run, uncomment the next two lines -- also uncomment lines in network-down script
  cp -r ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/ ${PWD}/../../../../testing/crypto-config/peerOrganizations/
}

createCertificateForeproducer