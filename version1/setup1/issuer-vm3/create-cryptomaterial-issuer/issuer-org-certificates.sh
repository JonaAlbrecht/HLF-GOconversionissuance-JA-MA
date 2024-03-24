#this creates the crypto material for issuer organisation using fabric-samples binary "fabric-ca-client"
#entity names use the prefix i- because all identities of all organisations are being registered on the same root certificate autority

createcertificatesForIssuer() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/
  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/

  fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 --caname ca.issuer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

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
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/config.yaml

  echo
  echo "Register i-peer0"
  echo
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name i-peer0 --id.secret i-peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register i-peer1"
  echo
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name i-peer1 --id.secret i-peer1pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register user"
  echo
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name i-user1 --id.secret i-user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register the org admin"
  echo
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name issueradmin --id.secret issueradminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers

  # -----------------------------------------------------------------------------------
  #  Peer 0
  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com

  echo
  echo "## Generate the i-peer0 msp"
  echo
  fabric-ca-client enroll -u https://i-peer0:i-peer0pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/msp --csr.hosts i-peer0.issuer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the i-peer0-tls certificates"
  echo
  fabric-ca-client enroll -u https://i-peer0:i-peer0pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts i-peer0.issuer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/tlsca/tlsca.issuer.GOnetwork.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/ca/ca.issuer.GOnetwork.com-cert.pem

  # ------------------------------------------------------------------------------------------------

  # Peer1

  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com

  echo
  echo "## Generate the i-peer1 msp"
  echo
  fabric-ca-client enroll -u https://i-peer1:i-peer1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/msp --csr.hosts i-peer1.issuer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the i-peer1-tls certificates"
  echo
  fabric-ca-client enroll -u https://i-peer1:i-peer1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts i-peer1.issuer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer1.issuer.GOnetwork.com/tls/server.key

  # --------------------------------------------------------------------------------------------------

  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users
  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/i-User1@issuer.GOnetwork.com

  echo
  echo "## Generate the user msp"
  echo
  fabric-ca-client enroll -u https://i-user1:i-user1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/i-User1@issuer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com

  echo
  echo "## Generate the issuer admin msp"
  echo
  fabric-ca-client enroll -u https://issueradmin:issueradminpw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp/config.yaml

}

createcertificatesForIssuer

