#this creates the crypto material for the orderer organisation using fabric-samples binary "fabric-ca-client"
#the orderer gets enrolled with its own certificate authority

cd $(dirname $0)

createCertificateForOrderer() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com

  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/config.yaml

  echo
  echo "Register orderer"
  echo 

  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  echo
  echo "Register orderer2"
  echo

  fabric-ca-client register --caname ca-orderer --id.name orderer2 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  echo
  echo "Register orderer3"
  echo

  fabric-ca-client register --caname ca-orderer --id.name orderer3 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  echo
  echo "Register orderer3"
  echo

  fabric-ca-client register --caname ca-orderer --id.name orderer4 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  echo
  echo "Register the orderer admin"
  echo

  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com/orderers

  # ---------------------------------------------------------------------------
  #  Orderer

  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com

  echo
  echo "## Generate the orderer msp"
  echo

  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp --csr.hosts orderer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo

  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts orderer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem

  mkdir ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem

  # -----------------------------------------------------------------------
  #  Orderer 2

  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com

  echo
  echo "## Generate the orderer2 msp"
  echo

  fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp --csr.hosts orderer2.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the orderer2-tls certificates"
  echo

  fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls --enrollment.profile tls --csr.hosts orderer2.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem

  # ---------------------------------------------------------------------------
  #  Orderer 3
  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com

  echo
  echo "## Generate the orderer3 msp"
  echo

  fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp --csr.hosts orderer3.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the orderer3-tls certificates"
  echo

  fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls --enrollment.profile tls --csr.hosts orderer3.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
  # ---------------------------------------------------------------------------

#  Orderer 4
  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com

  echo
  echo "## Generate the orderer4 msp"
  echo

  fabric-ca-client enroll -u https://orderer4:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp --csr.hosts orderer4.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the orderer4-tls certificates"
  echo

  fabric-ca-client enroll -u https://orderer4:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls --enrollment.profile tls --csr.hosts orderer4.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
  # ---------------------------------------------------------------------------

  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com/users
  mkdir -p ../crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com

  echo
  echo "## Generate the admin msp"
  echo

  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/msp/config.yaml

# Caliper Testing
  #if doing a caliper test run, uncomment the next two lines -- also uncomment lines in network-down script
  mkdir -p ${PWD}/../../../../testing/crypto-config/ordererOrganizations/
  cp -r ${PWD}/../crypto-config/ordererOrganizations/GOnetwork.com/ ${PWD}/../../../../testing/crypto-config/ordererOrganizations/

}

createCertificateForOrderer