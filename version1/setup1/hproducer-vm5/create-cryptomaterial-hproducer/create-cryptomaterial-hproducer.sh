#this creates the crypto material for the hydrogen producer organisation using fabric-samples binary "fabric-ca-client"
#and using the root certificate authority of the issuing body 

createCertificateForhproducer() {
  
  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/
  
# enroll the ca for hydrogen producer org cryptomaterial creation, the flag --tls.certfiles paths to the issuing body certificate authority root certificate
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
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "Register h-peer0"
  echo

  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name h-peer0 --id.secret h-peer0pw --id.type peer --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register h-peer1"
  echo

  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name h-peer1 --id.secret h-peer1pw --id.type peer --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

 
  echo
  echo "Register OutputMeter"
  echo

# this creates the Output Meter "measuring" the output electrolysis process x509 certificate with the attributes "trusted device = true, maxOutput = 10000 kilos of hydrogen per hour; kwhperkilo: varies between 50, i.e. the kilowatthours input needed per kilo hydrogen ouptut, conversion efficiency of 0.8 and the technology type, set to PEM electrolyser"
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name OutputMeter1 --id.secret OutputMeter1pw --id.type client --id.attrs 'hydrogentrustedDevice=true:ecert,maxOutput=100:ecert,kwhperkilo=50:ecert,conversionEfficiency=0.8:ecert,technologyType=PEMelectrolyser:ecert,emissionIntensity=20:ecert' --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register the org admins"
  echo

#this creates the admin for output meter
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name outhproduceradmin --id.secret outhproduceradminpw --id.type admin --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers
  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com

  # --------------------------------------------------------------
  # Peer 0
  echo
  echo "## Generate the h-peer0 msp"
  echo

  fabric-ca-client enroll -u https://h-peer0:h-peer0pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/msp --csr.hosts h-peer0.hproducer.GOnetwork.com --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the h-peer0-tls certificates"
  echo

  fabric-ca-client enroll -u https://h-peer0:h-peer0pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts h-peer0.hproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/tlsca/tlsca.hproducer.GOnetwork.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/ca/ca.hproducer.GOnetwork.com-cert.pem

  # --------------------------------------------------------------------------------
  #  Peer 1
  echo
  echo "## Generate the h-peer1 msp"
  echo

  fabric-ca-client enroll -u https://h-peer1:h-peer1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/msp --csr.hosts h-peer1.hproducer.GOnetwork.com --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/msp/config.yaml

  echo
  echo "## Generate the h-peer1-tls certificates"
  echo

  fabric-ca-client enroll -u https://h-peer1:h-peer1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls --enrollment.profile tls --csr.hosts h-peer1.hproducer.GOnetwork.com --csr.hosts localhost --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer1.hproducer.GOnetwork.com/tls/server.key
  # -----------------------------------------------------------------------------------
  #Output Meter

  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter
  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com

  echo
  echo "## Generate the OutputMeter msp"
  echo

  fabric-ca-client enroll -u https://OutputMeter1:OutputMeter1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  #copy the Node OU configuration file into the Smart Meter msp folder --> this is necessary for attribute-based chaincode invoke  
  cp "${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml" "${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com/msp/config.yaml"

  mkdir -p ../crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/oAdmin@hproducer.GOnetwork.com

  echo
  echo "## Generate the OutputMeter admin msp"
  echo

  fabric-ca-client enroll -u https://outhproduceradmin:outhproduceradminpw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/oAdmin@hproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/../../issuer-vm3/create-cryptomaterial-issuer/fabric-ca/issuer/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/oAdmin@hproducer.GOnetwork.com/msp/config.yaml

}

createCertificateForhproducer