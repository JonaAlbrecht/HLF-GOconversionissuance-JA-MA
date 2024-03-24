#this creates the crypto material for buyer organisation using fabric-samples binary "fabric-ca-client"

createCertificateForeproducer() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/

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
  echo "Register peer0"
  echo

  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  echo
  echo "Register peer1"
  echo

  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name peer1 --id.secret peer1pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  echo
  echo "Register user"
  echo

  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  echo
  echo "Register the org admin"
  echo

  fabric-ca-client register --caname ca.eproducer.GOnetwork.com --id.name org2admin --id.secret org2adminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/eproducerx/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com

  # --------------------------------------------------------------
  # Peer 0
  echo
  echo "## Generate the peer0 msp"
  echo

  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/msp --csr.hosts peer0.eproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo

  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts peer0.eproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/tlsca/tlsca.eproducer.GOnetwork.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/ca/ca.eproducer.GOnetwork.com-cert.pem

  # --------------------------------------------------------------------------------
  #  Peer 1
  echo
  echo "## Generate the peer1 msp"
  echo

  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/msp --csr.hosts peer1.eproducer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the peer1-tls certificates"
  echo

  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts peer1.eproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer1.eproducer.GOnetwork.com/tls/server.key
  # -----------------------------------------------------------------------------------

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/users
  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/users/User1@eproducer.GOnetwork.com

  echo
  echo "## Generate the user msp"
  echo

  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/users/User1@eproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/eproducer.GOnetwork.com/users/Admin@eproducer.GOnetwork.com

  echo
  echo "## Generate the org admin msp"
  echo

  fabric-ca-client enroll -u https://org2admin:org2adminpw@localhost:8054 --caname ca.eproducer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/users/Admin@eproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/eproducer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/eproducer.GOnetwork.com/users/Admin@eproducer.GOnetwork.com/msp/config.yaml

}

createCertificateForeproducer