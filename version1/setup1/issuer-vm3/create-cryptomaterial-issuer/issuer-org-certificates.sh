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
  echo "Register SmartMeter belonging to E-producer organisation"
  echo

  # this creates the Smart Meter x509 certificate with the attributes "trusted device = true, maxefficiency = 50 kW and technologyType = solar, emission intensity of 41grams of CO2 per kilowatthour"
  # note that the Smart Meter is being registered by the Issuer Certificate authority since, in a real world scenario - the Issuing Body or a third party representative (Auditor) have to audit the production device specification 
  # the Smart Meter therefore technically belongs to the Issuer Organisation. 
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name SmartMeter1 --id.secret Meter1pw --id.type client --id.attrs 'organization=eproducerMSP:ecert,electricitytrustedDevice=true:ecert,maxEfficiency=50:ecert,technologyType=solar:ecert,emissionIntensity=41:ecert' --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  echo
  echo "Register OutputMeter"
  echo

  # this creates the Output Meter "measuring" the output electrolysis process x509 certificate with the attributes "trusted device = true, maxOutput = 10000 kilos of hydrogen per hour; kwhperkilo: varies between 50, i.e. the kilowatthours input needed per kilo hydrogen ouptut, conversion efficiency of 0.8 and the technology type, set to PEM electrolyser"
  # the Output Meter is registered with the Issuing Body Certificate Authority because as a data source to the blockchain network, in a real-world scenario, the attributes in the certificate would be based on an audit carried out by the Issuing Body or a representative 
  fabric-ca-client register --caname ca.issuer.GOnetwork.com --id.name OutputMeter1 --id.secret OutputMeter1pw --id.type client --id.attrs 'organization=hproducerMSP:ecert,hydrogentrustedDevice=true:ecert,maxOutput=10000:ecert,kwhperkilo=50:ecert,conversionEfficiency=0.8:ecert,technologyType=PEMelectrolyser:ecert,emissionIntensity=20:ecert' --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

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
# User of the issuing body

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

#--------------------------------------------------------------------------------------------------
# Smart Meter e-producer

  # the cryptomaterial of the Smart Meter is stored both with the Issuing Body and the eproducer
  mkdir -p ../../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter
  mkdir -p ../../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com
  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/SmartMeter
  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com

  echo
  echo "## Generate the SmartMeter msp"
  echo

  fabric-ca-client enroll -u https://SmartMeter1:Meter1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  #copy the issuer Node Organisational Unit configuration file into the Smart Meter msp folder --> this is necessary for attribute-based chaincode invoke  
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp/config.yaml
  mkdir -p ${PWD}/../../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com
  cp -r ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com ${PWD}/../../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com
# -----------------------------------------------------------------------------------
# Output Meter of hydrogen producer

  mkdir -p ../../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter
  mkdir -p ../../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com
  mkdir -p ../../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com/msp
  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/OutputMeter
  mkdir -p ../crypto-config/peerOrganizations/issuer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com

  echo
  echo "## Generate the OutputMeter msp"
  echo

  fabric-ca-client enroll -u https://OutputMeter1:OutputMeter1pw@localhost:10054 --caname ca.issuer.GOnetwork.com -M ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com/msp --tls.certfiles ${PWD}/fabric-ca/issuer/tls-cert.pem

  #copy the Node OU configuration file into the Output Meter msp folder --> this is necessary for attribute-based chaincode invoke  
  cp ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com/msp/config.yaml
  mkdir -p ${PWD}/../../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/
  cp -r ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com ${PWD}/../../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/

# Caliper Testing
  #if doing a caliper test run, uncomment the next line -- also uncomment lines in network-down script
  cp -r ${PWD}/../crypto-config/peerOrganizations/issuer.GOnetwork.com/ ${PWD}/../../../../testing/crypto-config/peerOrganizations/

}

createcertificatesForIssuer

