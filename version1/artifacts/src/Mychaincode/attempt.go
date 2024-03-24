package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	sc "github.com/hyperledger/fabric-protos-go/peer"
)

type SmartContract struct {

}

type ElectricityGO struct {
	AssetID string `json:"AssetID"`
	CreationDateTime string `json:"CreationTime"`
	signCertID string `json:signCertID`
}

type ElectricityGOprivatedetails struct {
	AssetID string `json:"AssetID"`
	OwnerID string `json:"OwnerID"`
	AmountMWh string `json: "AmountMWh"`
	Emissions string `json: Emissions`
	ProductionMethod string `json: "ProductionMethod"`
}

type greenHydrogenGO struct {
	AssetID string `json:"AssetID"`
	CreationDateTime string `json:"CreationTime"`
	signCertID string `json:"signCertID"`
}

type greenHydrogenGOprivatedetails struct {
	AssetID string `json:"AssetID"`
	OwnerID string `json:"OwnerID"`
	Tonsproduced string `json: "Tonsproduced"`
	Emissions string `json: Emissions`
	ProductionMethod string `json: "ProductionMethod"`
}

func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {
	function, args := APIstub.GetFunctionAndParameters()

	switch function {
	case "createElectricityGO":
		return s.createElectricityGO(APIstub, args)
	case "initLedger":
		return s.initLedger(APIstub, args)
	case "queryGO":
		return s.queryGO(APIstub, args)
	case "conversionIssuanceHydrogen":
		return s.conversionIssuanceHydrogen(APIstub, args)
	case "transferElectricityGO":
		return s.transferGO(APIstub, args)
	case "retireElectricityGO":
		return s.retireElectricityGO(APIstub, args)
	case "retireHydrogenGO":
		return s.retireHydrogenGO(APIstub, args)
	default:
		return shim.Error("Invalid smart contract name")
	}
}
func (s *SmartContract) createElectricityGO(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	type eGOTransientInput struct {
		AssetID string `json:"AssetID"`
		CreationDateTime string `json:"CreationTime"`
		signCertID string `json:"signCertID`
		OwnerID string `json:"OwnerID"`
		AmountMWh string `json: "AmountMWh"`
		Emissions string `json: Emissions`
		ProductionMethod string `json: "ProductionMethod"`
	}
	if len(args) != 0 {
		return shim.Error("Incorrect number of arguments passed. Expected transient map")
	}

	transMap, err := APIstub.GetTransient()
	if err != nil {
		return shim.Error("Error getting transient data: " + err.Error())
	}

	eGODataAsBytes, ok := transMap["GO"]
	if !ok {
		return shim.Error("GO must be a key in transient map")
	}

	if len(eGODataAsBytes) == 0 {
		return shim.Error("GO value must be non-empty")
	}

	var eGOInput eGOTransientInput
	err = json.Unmarshal(eGODataAsBytes, &eGOInput)
	if err != nil {
		return sim.Error("failed to decode JSON input of: " + string(eGODataAsBytes) + ". The error is: " + err.Error())
	}

	if len(eGOInput.AssetID) == 0 {
		return shim.Error("Proposed AssetID must be a non-empty string")
	}
	if len(eGOInput.CreationDateTime) == 0 {
		return shim.Error("Creation Datetime field must be a non-empty string")
	}
	if len(eGOInput.signCertID) == 0 {
		return shim.Error("GO proposal must be signed with a production device certificate")
	}
	if len(eGOInput.OwnerID) == 0 {
		return shim.Error("OwnerID field must be a non-empty string")
	}
	if len(eGOInput.AmountMWh) == 0 {
		return shim.Error("GO proposal must specify an amount of MWh")
	}
	if len(eGOInput.Emissions) == 0 {
		return shim.Error("GO proposal must specify emissions amount")
	}
	if len(eGOInput.ProductionMethod) == 0 {
		return shim.Error("ProductionMethod field must be a non-empty string")
	}

	//check if the GO AssetID is already in use
	eGODataAsBytes, err := APIstub.GetPrivateData("eGOcollection", eGOInput.AssetID)
	if err != nil {
		return shim.Error("Failed to get data: " + err.Error())
	} else if eGODataAsBytes != nil {
		fmt.Println("This GO Asset ID already exists" + eGOInput.AssetID)
		return shim.Error("This GO Asset ID already exists: " + eGOInput.AssetID)
	}
	
	//get the hash of the audited production device certificate
	
	devicehash, err := APIstub.GetPrivateDataHash("eGOcollection", eGOInput.signCertID)
	if err != nil {
		return shim.Error("Failed to get private data hash" + err.Error())
	}
	

	var electricitygo = ElectricityGO{AssetID: eGOInput.AssetID,  }
}


func (s *SmartContract) queryGO(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) !=1 {
		return shim.Error("Wrong number of arguments, expecting 1")	
	}

	query, _ := APIstub.GetState(args[0])
	return shim.Success(query)
}