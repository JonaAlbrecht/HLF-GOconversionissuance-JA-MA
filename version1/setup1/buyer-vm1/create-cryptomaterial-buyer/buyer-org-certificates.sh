#this creates the crypto material for the buyer organisation using fabric-samples binary "fabric-ca-client"
#and using the root certificate authority of the issuing body

createcertificatesForBuyer() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/peerOrganizations/buyer.GOnetwork.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/

# enroll the ca for buyer org cryptomaterial creation, the flag --tls.certfiles paths to the issuing body certificate authority root certificate
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca.buyer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-buyer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-buyer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-buyer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-buyer-GOnetwork-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/msp/config.yaml

  echo
  echo "Register b-peer0"
  echo
  fabric-ca-client register --caname ca.buyer.GOnetwork.com --id.name b-peer0 --id.secret b-peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  echo
  echo "Register b-peer1"
  echo
  fabric-ca-client register --caname ca.buyer.GOnetwork.com --id.name b-peer1 --id.secret b-peer1pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  echo
  echo "Register b-user"
  echo
  fabric-ca-client register --caname ca.buyer.GOnetwork.com --id.name b-user1 --id.secret b-user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  echo
  echo "Register the org admin"
  echo
  fabric-ca-client register --caname ca.buyer.GOnetwork.com --id.name buyeradmin --id.secret buyeradminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers

  # -----------------------------------------------------------------------------------
  #  b-Peer 0
  mkdir -p ../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com

  echo
  echo "## Generate the b-peer0 msp"
  echo
  fabric-ca-client enroll -u https://b-peer0:b-peer0pw@localhost:7054 --caname ca.buyer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/msp --csr.hosts b-peer0.buyer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the b-peer0-tls certificates"
  echo
  fabric-ca-client enroll -u https://b-peer0:b-peer0pw@localhost:7054 --caname ca.buyer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts b-peer0.buyer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/tlsca/tlsca.buyer.GOnetwork.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/ca/ca.buyer.GOnetwork.com-cert.pem

# ------------------------------------------------------------------------------------------------
#  Peer 1

  mkdir -p ../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com

  echo
  echo "## Generate the b-peer1 msp"
  echo
  fabric-ca-client enroll -u https://b-peer1:b-peer1pw@localhost:7054 --caname ca.buyer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/msp --csr.hosts b-peer1.buyer.GOnetwork.com --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem
  
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the b-peer1-tls certificates"
  echo
  fabric-ca-client enroll -u https://b-peer1:b-peer1pw@localhost:7054 --caname ca.buyer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts b-peer1.buyer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem


  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer1.buyer.GOnetwork.com/tls/server.key

# ------------------------------------------------------------------------------------------------
#  User

  mkdir -p ../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users
  mkdir -p ../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/b-User1@buyer.GOnetwork.com

  echo
  echo "## Generate the b-user msp"
  echo
  fabric-ca-client enroll -u https://b-user1:b-user1pw@localhost:7054 --caname ca.buyer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/b-User1@buyer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com

  echo
  echo "## Generate the buyer admin msp"
  echo
  fabric-ca-client enroll -u https://buyeradmin:buyeradminpw@localhost:7054 --caname ca.buyer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/buyer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp/config.yaml

}

createcertificatesForBuyer
