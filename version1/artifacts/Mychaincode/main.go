package main

import (
	"log"

	"github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/artifacts/Mychaincode/GOnetwork"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {
	chaincode, err := contractapi.NewChaincode(&GOnetwork.SmartContract{})
	if err != nil {
		log.Panicf("Error create transfer asset chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting asset chaincode: %v", err)
	}
}