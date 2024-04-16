package GOnetwork

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/pkg/statebased"
	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

type ElectricityGO struct {
	AssetID string `json:"AssetID"`
	CreationDateTime string `json:"CreationDateTime"`
	GOType string `json:"GOType"`
}

type ElectricityGOprivatedetails struct {
	AssetID string `json:"AssetID"`
	OwnerID string `json:"OwnerID"`
	AmountMWh float64 `json:"AmountMWh"`
	Emissions float64 `json:"Emissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
}

type GreenHydrogenGO struct {
	AssetID string `json:"AssetID"`
	CreationDateTime string `json:"CreationDateTime"`
	GOType string `json:"GOType"`
}

type GreenHydrogenGOprivatedetails struct {
	AssetID string `json:"AssetID"`
	OwnerID string `json:"OwnerID"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	InputEmissions float64 `json:"InputEmissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	UsedMWh float64 `json:"UsedMWh"`
}

type GreenHydrogenGObacklog struct {
	Backlogkey string `json:"Backlogkey"`
	GOType string `json:"GOType"`
}

type GreenHydrogenGObacklogprivatedetails struct {
	Backlogkey string `json:"Backlogkey"`
	OwnerID string `json:"OwnerID"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	UsedMWh float64 `json:"UsedMWh"`
}

type CancellationstatementElectricity struct {
	ECancellationkey string `json:"eCancellationkey"`
	CancellationTime string `json:"CancellationTime"`
	OwnerID string `json:"OwnerID"`
	AmountMWh float64 `json:"AmountMWh"`
	Emissions float64 `json:"Emissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
}

type CancellationstatementHydrogen struct {
	HCancellationkey string `json:"hCancellationkey"`
	CancellationTime string `json:"CancellationTime"`
	OwnerID string `json:"OwnerID"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	InputEmissions float64 `json:"InputEmissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	UsedMWh float64 `json:"UsedMWh"`
}

type FunctionAndDuration struct {
	FunctionName string
	Duration time.Duration
}

// AveragefunctiondurationCalculator transfers function durations to a different goroutine 
// such that it doesnt block the chaincode execution
var AveragefunctiondurationCalculator chan *FunctionAndDuration

type Count struct {
	mx *sync.Mutex
	count int
}

func NewCount() *Count {
	return &Count{mx: new(sync.Mutex), count: 0}
}

var EGOcount = NewCount()
var HGOcount = NewCount()
var ECancellations = NewCount()
var HCancellations = NewCount()

func (s *SmartContract) CreateElectricityGO(ctx contractapi.TransactionContextInterface) error {
	
	type eGOTransientInput struct {
		AmountMWh json.Number `json:"AmountMWh"`
		Emissions json.Number `json:"Emissions"`
		ElapsedSeconds json.Number `json:"ElapsedSeconds"`
		ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	}

	type eGOTransientData struct {
		AmountMWh float64 `json:"AmountMWh"`
		Emissions float64 `json:"Emissions"`
		ElapsedSeconds float64 `json:"ElapsedSeconds"`
		ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	}

	err := ctx.GetClientIdentity().AssertAttributeValue("electricitytrustedDevice", "true")
	if err != nil {
		return fmt.Errorf("submitting Sensor not authorized to create eGO asset, not a trusted electricity Smart Meter: %v", err)
	}

	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return fmt.Errorf("error getting transient: %v", err)
	}

	eGODataAsBytes, ok := transientMap["eGO"]
	if !ok {
		return fmt.Errorf("GO must be a key in transient map:%v", ok)
	}

	if len(eGODataAsBytes) == 0 {
		return fmt.Errorf("GO value must be non-empty")
	}

	// eGO asset ID is of the format "eGO1", "eGO2" and so on...
	currentCounteGO := EGOcounter()
	eGOID := "eGO"+strconv.Itoa(int(currentCounteGO))
	
	var eGOInputJSONformat eGOTransientInput
	var eGOInput eGOTransientData

	err = json.Unmarshal(eGODataAsBytes, &eGOInputJSONformat)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input of: " + string(eGODataAsBytes) + ". The error is: " + err.Error())
	}

	eGOInput.AmountMWh, err = eGOInputJSONformat.AmountMWh.Float64()
	if err != nil {
		return fmt.Errorf("failed to convert Json.number into float:%v", err)
	}
	eGOInput.Emissions, err = eGOInputJSONformat.Emissions.Float64()
	if err != nil {
		return fmt.Errorf("failed to convert Json.number into float:%v", err)
	}
	eGOInput.ElapsedSeconds, err = eGOInputJSONformat.ElapsedSeconds.Float64()
	if err != nil {
		return fmt.Errorf("failed to convert Json.number into float:%v", err)
	}
	eGOInput.ElectricityProductionMethod = eGOInputJSONformat.ElectricityProductionMethod

	if eGOInput.AmountMWh == 0 {
		return fmt.Errorf("go proposal must specify an amount of MWh")
	}
	if eGOInput.Emissions == 0 {
		return fmt.Errorf("go proposal must specify emissions amount")
	}
	if len(eGOInput.ElectricityProductionMethod) == 0 {
		return fmt.Errorf("electricity Production Method must be a non-empty string")
	}

	//check if the GO AssetID is already in use
	testifexist, err := ctx.GetStub().GetPrivateData("privateDetails-eGO", eGOID)
	if err != nil {
		return fmt.Errorf("Failed to get data: " + err.Error())
	} else if testifexist != nil {
		return fmt.Errorf("This GO Asset ID already exists: " + eGOID)
	}
	
	// need to change this such that eproducerMSP is an attribute in the certificate. 
	//get ID of submitting Client Identity
	clientID, err := getClientOrgID(ctx)
	if err != nil {
		return fmt.Errorf("error while retrieving Client Org ID")
	}
	
	maxEfficiency, err := getmaxEfficiencyeGO(ctx)
	if err != nil {
		return fmt.Errorf("error getting max Efficiency")
	}

	impliedefficiency := eGOInput.AmountMWh/eGOInput.ElapsedSeconds
	maxEfficiencyint, err := strconv.Atoi(maxEfficiency)
	if err != nil {
        return fmt.Errorf("max Efficiency could not be converted to a string %v", err.Error())
    }
	maxEfficiencyfloat := float64(maxEfficiencyint)
	
	if maxEfficiencyfloat < impliedefficiency {
		return fmt.Errorf("GO rejected - Efficiency is suspiciously high")
	}

	emissionIntensity, err := getEmissionIntensityeGO(ctx)
	if err != nil {
		return fmt.Errorf("error getting emission intensity: %v", err)
	}
	emissionIntensityint, err := strconv.Atoi(emissionIntensity)
	if err != nil {
		return fmt.Errorf("error converting emission intensity to integer: %v", err)
	}
	emissionIntensityfloat := float64(emissionIntensityint)

	impliedemissionIntensity := (eGOInput.Emissions/eGOInput.ElapsedSeconds)*3600
	if emissionIntensityfloat > impliedemissionIntensity {
		return fmt.Errorf("go rejected - Emissions are suspiciously low")
	}

	technologytypeeGO, err := getTechnologyTypeeGO(ctx)
	if err != nil {
		return fmt.Errorf("error getting technology type: %v", err)
	}
	if technologytypeeGO != eGOInput.ElectricityProductionMethod {
		return fmt.Errorf("different production method expected")
	}

	now1, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("error getting timestamp:%v", err)
	}
	creationtime1 := now1.String()

	eGO := ElectricityGO{
		AssetID: eGOID,
		CreationDateTime: creationtime1,
		GOType: "Electricity",
	}

	eGOpublicBytes, err := json.Marshal(eGO)
	if err != nil {
		return fmt.Errorf("failed to create eGO json:%v", err.Error())
	}

	errorb := ctx.GetStub().PutState(eGOID, eGOpublicBytes)
	if errorb != nil {
		return fmt.Errorf("failed to put asset in public data:%v", errorb)
	}

	// State-based endorsement. Not yet implemented. still tbd whether it is needed
	//peerID, error := getPeerOrgID(ctx)
	//if error != nil {
		//return fmt.Errorf("error getting peer Org ID:%v", error)
	//}
	//endorsingOrgs := []string{peerID}
	//err = setGOEndorsementpolicy(ctx, eGO.AssetID, endorsingOrgs)
	//if err != nil {
	//	return fmt.Errorf("failed setting state based endorsement for buyer and seller")
	//}

	eGOprivate := ElectricityGOprivatedetails{
		AssetID: eGOID,
		OwnerID: clientID,
		AmountMWh: eGOInput.AmountMWh,
		Emissions: eGOInput.Emissions,
		ElectricityProductionMethod: eGOInput.ElectricityProductionMethod,
	}

	eGOprivateBytes, err := json.Marshal(eGOprivate)
	if err != nil {
		return fmt.Errorf("failed to create eGO json")
	}

	// Write private immutable asset properties into owner's private data collection
	err = ctx.GetStub().PutPrivateData("privateDetails-eGO", eGOID, eGOprivateBytes)
	if err != nil {
		return fmt.Errorf("unable to create asset private data: %v", err)
	}
	return nil
}


func (s *SmartContract) AddHydrogentoBacklog(ctx contractapi.TransactionContextInterface) error {
	
	type hGObacklogTransientInput struct {
		Kilosproduced json.Number `json:"Kilosproduced"`
		EmissionsHydrogen json.Number `json:"EmissionsHydrogen"`
		UsedMWh json.Number `json:"UsedMWh"`
		HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
		ElapsedSeconds json.Number `json:"ElapsedSeconds"`
	}

	type hGObacklogTransientData struct {
		Kilosproduced float64 `json:"Kilosproduced"`
		EmissionsHydrogen float64 `json:"EmissionsHydrogen"`
		UsedMWh float64 `json:"UsedMWh"`
		HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
		ElapsedSeconds float64 `json:"ElapsedSeconds"`
	}
	
	err := ctx.GetClientIdentity().AssertAttributeValue("hydrogentrustedDevice", "true")
	if err != nil {
		return fmt.Errorf("submitting Sensor not authorized to add to hGO backlog, not a trusted hydrogen Output Meter: %v", err)
	}

	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return fmt.Errorf("error getting transient: %v", err)
	}

	hGODataAsBytes, ok := transientMap["hGO"]
	if !ok {
		return fmt.Errorf("GO must be a key in transient map:%v", ok)
	}

	if len(hGODataAsBytes) == 0 {
		return fmt.Errorf("GO value must be non-empty")
	}

	var hGOInputJSONFORMAT hGObacklogTransientInput
	var hGOInput hGObacklogTransientData
	err = json.Unmarshal(hGODataAsBytes, &hGOInputJSONFORMAT)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input of: " + string(hGODataAsBytes) + ". The error is: " + err.Error())
	}

	hGOInput.Kilosproduced, err = hGOInputJSONFORMAT.Kilosproduced.Float64()
	if err != nil {
		return fmt.Errorf("failed to convert json.number into float:%v", err)
	}
	hGOInput.EmissionsHydrogen, err = hGOInputJSONFORMAT.EmissionsHydrogen.Float64()
	if err != nil {
		return fmt.Errorf("failed to convert json.number into float:%v", err)
	}
	hGOInput.UsedMWh, err = hGOInputJSONFORMAT.UsedMWh.Float64()
	if err != nil {
		return fmt.Errorf("failed to convert json.number into float:%v", err)
	}
	hGOInput.ElapsedSeconds, err = hGOInputJSONFORMAT.ElapsedSeconds.Float64()
	if err != nil {
		return fmt.Errorf("failed to convert json.number into float:%v", err)
	}
	hGOInput.HydrogenProductionMethod = hGOInputJSONFORMAT.HydrogenProductionMethod

	if hGOInput.Kilosproduced == 0 {
		return fmt.Errorf("go proposal must specify kilos produced")
	}
	if hGOInput.EmissionsHydrogen == 0 {
		return fmt.Errorf("go proposal must specify emissions amount")
	}
	if hGOInput.UsedMWh == 0 {
		return fmt.Errorf("go proposal must specify used MWh amount")
	}
	if len(hGOInput.HydrogenProductionMethod) == 0 {
		return fmt.Errorf("go proposal must specify Hydrogen Production Method")
	}
	if hGOInput.ElapsedSeconds == 0 {
		return fmt.Errorf("go proposal must specify elapsed seconds")
	}

	backlogkey := "hydrogenbacklog"
	
	//get ID of submitting Client Identity
	clientID, err := getClientOrgID(ctx)
	if err != nil {
		return fmt.Errorf("error while retrieving Client Org ID: %v", err)
	}
	
	maxOutput, err := getmaxOutputhGO(ctx)
	if err != nil {
		return fmt.Errorf("error getting max Output: %v", err.Error())
	}

	impliedOutputefficiency := (hGOInput.Kilosproduced/hGOInput.ElapsedSeconds)*3600
	maxOutputint, err := strconv.Atoi(maxOutput)
	if err != nil {
        return fmt.Errorf("max Efficiency could not be converted to an int %v", err.Error())
    }
	maxOutputfloat := float64(maxOutputint)
	
	if maxOutputfloat < impliedOutputefficiency {
		return fmt.Errorf("go rejected - Efficiency is suspiciously high")
	}

	emissionIntensity, err := getEmissionIntensityhGO(ctx)
	if err != nil {
        return fmt.Errorf("error getting Emission Intensity hydrogen GO %v", err.Error())
    }
	emissionIntensityint, err := strconv.Atoi(emissionIntensity)
	if err != nil {
        return fmt.Errorf("max Efficiency could not be converted to an int %v", err.Error())
    }
	emissionIntensityfloat := float64(emissionIntensityint)

	impliedemissionIntensity := (hGOInput.EmissionsHydrogen/hGOInput.ElapsedSeconds)*3600
	if emissionIntensityfloat > impliedemissionIntensity {
		return fmt.Errorf("go rejected - Emissions are suspiciously low")
	}

	kwhperkilo, err := getkwhperkilo(ctx)
	if err != nil {
        return fmt.Errorf("error getting kwhperkilo %v", err.Error())
    }
	kwhperkiloint, err := strconv.Atoi(kwhperkilo)
	if err != nil {
        return fmt.Errorf("kwhperkilo couldnt be converted to an int %v", err.Error())
    }
	kwhperkilofloat := float64(kwhperkiloint)

	impliedkwhperkilo := hGOInput.UsedMWh/hGOInput.Kilosproduced
	if kwhperkilofloat < impliedkwhperkilo {
		return fmt.Errorf("GO rejected - Used electricity amount is suspiciously low")
	}

	technologytypehGO, err := getTechnologyTypehGO(ctx)
	if err != nil {
        return fmt.Errorf("error getting hydrogen technology type %v", err.Error())
    }
	if technologytypehGO != hGOInput.HydrogenProductionMethod {
		return fmt.Errorf("different production method expected")
	}

	//get the backlog
	backlogJSON, err := ctx.GetStub().GetPrivateData("privateDetails-hGO", backlogkey)
	if err != nil {
		return fmt.Errorf("Failed to get data: " + err.Error())
	} 
	if backlogJSON == nil {
		hGObacklog := GreenHydrogenGObacklog{
			Backlogkey: backlogkey,
			GOType: "Hydrogen",
		}
	
		hGOpublicBytes, err := json.Marshal(hGObacklog)
		if err != nil {
			return fmt.Errorf("failed to create hGO json: %v", err.Error())
		}
	
		err = ctx.GetStub().PutState(backlogkey, hGOpublicBytes)
		if err != nil {
			return fmt.Errorf("failed to put asset in public data: %v", err.Error())
		}
	
		// Set the endorsement policy such that an owner org peer is required to endorse future updates.
		//endorsingOrgs := []string{clientID}
		//err = setGOEndorsementpolicy(ctx, hGO.Backlogkey, endorsingOrgs)
		//if err != nil {
			//return fmt.Errorf("failed setting state based endorsement for buyer and seller: %v", err)
		//}
	
		hGObacklogprivate := GreenHydrogenGObacklogprivatedetails{
			Backlogkey: backlogkey,
			OwnerID: clientID,
			Kilosproduced: hGOInput.Kilosproduced,
			EmissionsHydrogen: hGOInput.EmissionsHydrogen,
			HydrogenProductionMethod: hGOInput.HydrogenProductionMethod,
			UsedMWh: hGOInput.UsedMWh, // will have to be transcribed from electricity input GO
		}
	
		hGObacklogprivateBytes, err := json.Marshal(hGObacklogprivate)
		if err != nil {
			return fmt.Errorf("failed to create eGO json: %v", err)
		}
	
		// Persist private immutable asset properties to owner's private data collection
		err = ctx.GetStub().PutPrivateData("privateDetails-hGO", backlogkey, hGObacklogprivateBytes)
		if err != nil {
			return fmt.Errorf("unable to create asset private data: %v", err)
		}
	} else {
		
	var currentbacklog *GreenHydrogenGObacklogprivatedetails
	err = json.Unmarshal(backlogJSON, &currentbacklog)
	if err != nil {
		return fmt.Errorf("error unmarshaling the current backlog:%v", err)
	}
		
	hGObacklog := GreenHydrogenGObacklog{
		Backlogkey: backlogkey,
		GOType: "Hydrogen",
	}
	
	hGOpublicBytes, err := json.Marshal(hGObacklog)
	if err != nil {
		return fmt.Errorf("failed to create hGO json: %v", err.Error())
	}
	
	err = ctx.GetStub().PutState(backlogkey, hGOpublicBytes)
	if err != nil {
		return fmt.Errorf("failed to put asset in public data: %v", err.Error())		
	}
	
	// Set the endorsement policy such that an owner org peer is required to endorse future updates.
	// In practice, consider additional endorsers such as a trusted third party to further secure transfers.
	//endorsingOrgs := []string{clientID}
	//err = setGOEndorsementpolicy(ctx, hGO.Backlogkey, endorsingOrgs)
	//if err != nil {
	//return fmt.Errorf("failed setting state based endorsement for buyer and seller: %v", err)
	//}
	
	
	hGObacklogprivate := GreenHydrogenGObacklogprivatedetails{
		Backlogkey: currentbacklog.Backlogkey,
		OwnerID: currentbacklog.OwnerID,
		Kilosproduced: hGOInput.Kilosproduced + currentbacklog.Kilosproduced,
		EmissionsHydrogen: hGOInput.EmissionsHydrogen + currentbacklog.EmissionsHydrogen,
		HydrogenProductionMethod: hGOInput.HydrogenProductionMethod,
		UsedMWh: hGOInput.UsedMWh + currentbacklog.UsedMWh,
	}	
	
	hGObacklogprivateBytes, err := json.Marshal(hGObacklogprivate)
	if err != nil {
			return fmt.Errorf("failed to create eGO json: %v", err)
	}
	
	// Persist private immutable asset properties to owner's private data collection
	err = ctx.GetStub().PutPrivateData("privateDetails-hGO", currentbacklog.Backlogkey, hGObacklogprivateBytes)
	if err != nil {
			return fmt.Errorf("unable to create asset private data: %v", err)
	}
		
	}


	return nil
}

//returns a list of electricity GOs that are ready for transfer such that the combined AmountMWh is larger than the needed amount. 
func (s *SmartContract) QueryPrivateeGOsbyAmountMWh(ctx contractapi.TransactionContextInterface) ([]string, error) {
	
	type QueryPrivateeGOtransientinputstruct struct {
		NeededAmount json.Number `json:"NeededAmount"`
		Collection string `json:"Collection"`
	}
	
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return nil, fmt.Errorf("error getting transient: %v", err)
	}

	QueryPrivateeGOInputAsBytes, ok := transientMap["QueryInput"]
	if !ok {
		return nil, fmt.Errorf("transfer Input must be a key in transient map:%v", ok)
	}

	if len(QueryPrivateeGOInputAsBytes) == 0 {
		return nil, fmt.Errorf("transfer Input must be non-empty")
	}
	
	var QueryPrivateeGOtransient QueryPrivateeGOtransientinputstruct
	err = json.Unmarshal(QueryPrivateeGOInputAsBytes, &QueryPrivateeGOtransient)
	if err != nil {
		return nil, fmt.Errorf("failed to decode JSON input of: " + string(QueryPrivateeGOInputAsBytes) + ". The error is: " + err.Error())
	}


	NeededAmount, err := QueryPrivateeGOtransient.NeededAmount.Float64()
	if err != nil {
		return nil, fmt.Errorf("error turning needed amount into a float")
	}
	
	startKey := "eGO1"
	endKey := "eGO999"

	resultsIterator,err := ctx.GetStub().GetPrivateDataByRange(QueryPrivateeGOtransient.Collection, startKey, endKey)
	if err != nil {
		return nil, fmt.Errorf("error getting all available eGOs:%v", err)
	}
	defer resultsIterator.Close()

	results := []*ElectricityGOprivatedetails{}
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("error iterating over all available eGOs:%v", err)
		}

		var availableeGO *ElectricityGOprivatedetails
		err = json.Unmarshal(response.Value, &availableeGO)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal JSON: %v", err)
		}
		results = append(results, availableeGO)
	}

	var MWhcounter float64
	var EGOList []string
	MWhcounter = 0
	assetCounter := 0
	for MWhcounter < NeededAmount {
		currentAsset := results[assetCounter]
		EGOList = append(EGOList, currentAsset.AssetID)	
		MWhcounter = MWhcounter + currentAsset.AmountMWh
		assetCounter++
	}
	return EGOList, nil
}

//returns a list of hydrogen GOs that are ready for transfer such that the combined AmountMWh is larger than the needed amount. 
func (s *SmartContract) QueryPrivatehGOsbyAmountMWh(ctx contractapi.TransactionContextInterface) ([]string, error) {
	
	type QueryPrivatehGOtransientinputstruct struct {
		NeededAmount json.Number `json:"NeededAmount"`
		Collection string `json:"Collection"`
	}
	
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return nil, fmt.Errorf("error getting transient: %v", err)
	}

	QueryPrivatehGOInputAsBytes, ok := transientMap["QueryInput"]
	if !ok {
		return nil, fmt.Errorf("query Input must be a key in transient map:%v", ok)
	}

	if len(QueryPrivatehGOInputAsBytes) == 0 {
		return nil, fmt.Errorf("query Input must be non-empty")
	}
	
	var QueryPrivatehGOtransient QueryPrivatehGOtransientinputstruct
	err = json.Unmarshal(QueryPrivatehGOInputAsBytes, &QueryPrivatehGOtransient)
	if err != nil {
		return nil, fmt.Errorf("failed to decode JSON input of: " + string(QueryPrivatehGOInputAsBytes) + ". The error is: " + err.Error())
	}


	NeededAmount, err := QueryPrivatehGOtransient.NeededAmount.Float64()
	if err != nil {
		return nil, fmt.Errorf("error turning needed amount into a float")
	}
	
	startKey := "hGO1"
	endKey := "hGO999"

	resultsIterator,err := ctx.GetStub().GetPrivateDataByRange(QueryPrivatehGOtransient.Collection, startKey, endKey)
	if err != nil {
		return nil, fmt.Errorf("error getting all available hGOs:%v", err)
	}
	defer resultsIterator.Close()

	results := []*GreenHydrogenGOprivatedetails{}
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("error iterating over all available eGOs:%v", err)
		}

		var availablehGO *GreenHydrogenGOprivatedetails
		err = json.Unmarshal(response.Value, &availablehGO)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal JSON: %v", err)
		}
		results = append(results, availablehGO)
	}

	var Kilocounter float64
	var HGOList []string
	Kilocounter = 0
	assetCounter := 0
	for Kilocounter < NeededAmount {
		currentAsset := results[assetCounter]
		HGOList = append(HGOList, currentAsset.AssetID)	
		Kilocounter = Kilocounter + currentAsset.Kilosproduced
		assetCounter++
	}
	return HGOList, nil
}

func (s *SmartContract) QueryHydrogenBacklog(ctx contractapi.TransactionContextInterface) (*GreenHydrogenGObacklogprivatedetails, error) {
	
	log.Printf("Reading hydrogen backlog")
	backlogkey := "hydrogenbacklog"
	//ABAC: 
	err := ctx.GetClientIdentity().AssertAttributeValue("hydrogentrustedUser", "true")
	if err != nil {
		return  nil, fmt.Errorf("submitting User not authorized to query the hydrogen backlog: %v", err)
	}

	backlogprivateJSON, err := ctx.GetStub().GetPrivateData("privateDetails-hGO", backlogkey)
	if err != nil {
		return nil, fmt.Errorf("failed to read asset details: %v", err)
	}
	if backlogprivateJSON == nil {
		return nil, fmt.Errorf("backlog not found in hydrogen producer's private collection")
	}
	var backlogprivate GreenHydrogenGObacklogprivatedetails
	err = json.Unmarshal(backlogprivateJSON, &backlogprivate)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal JSON: %v", err)
	}
	return &backlogprivate, nil
}

func (s *SmartContract) TransfereGO(ctx contractapi.TransactionContextInterface) error {
	type TransfereGOtransinputstruct struct {
		EGO string `json:"EGO"`
		Recipient string `json:"Recipient"`
	}
	//ABAC:
	err := ctx.GetClientIdentity().AssertAttributeValue("electricitytrustedUser", "true")
	if err != nil {
		return fmt.Errorf("submitting User not authorized to transfer electricity GOs: %v", err)
	}
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return fmt.Errorf("error getting transient: %v", err)
	}

	TransferInputDataAsBytes, ok := transientMap["TransferInput"]
	if !ok {
		return fmt.Errorf("transfer Input must be a key in transient map:%v", ok)
	}
	if len(TransferInputDataAsBytes) == 0 {
		return fmt.Errorf("transfer Input must be non-empty")
	}
	
	var TransfereGOtransientinput TransfereGOtransinputstruct
	err = json.Unmarshal(TransferInputDataAsBytes, &TransfereGOtransientinput)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input of: " + string(TransferInputDataAsBytes) + ". The error is: " + err.Error())
	}

	var privateCollectionID string
	if TransfereGOtransientinput.Recipient == "hproducerMSP" {
		privateCollectionID = "privateDetails-hGO"
	} else if TransfereGOtransientinput.Recipient == "buyerMSP" {
		privateCollectionID = "privateDetails-buyer"
	} else {
		return fmt.Errorf("recipient ID malformed - please try again")
	}

	var currentAsset ElectricityGOprivatedetails
	currentAssetJSON, err := ctx.GetStub().GetPrivateData("privateDetails-eGO", TransfereGOtransientinput.EGO)
		if err != nil {
			return fmt.Errorf("error getting private Details for eGO %v:%v", TransfereGOtransientinput.EGO, err)
		}
		err = json.Unmarshal(currentAssetJSON, &currentAsset)
		if err != nil {
			return fmt.Errorf("error unmarshaling the current asset for transfer:%v", err)
		}
	
	currentAsset.OwnerID = TransfereGOtransientinput.Recipient
	
	err = ctx.GetStub().DelPrivateData("privateDetails-eGO", TransfereGOtransientinput.EGO)
	if err != nil {
		return fmt.Errorf("error deleting electricity GO from electricity producer private collection:%v", err)
	}

	updatedAssetasBytes, err := json.Marshal(currentAsset)
	if err != nil {
		return fmt.Errorf("error marshaling the updated eGO:%v", err)
	}
	err = ctx.GetStub().PutPrivateData(privateCollectionID, TransfereGOtransientinput.EGO, updatedAssetasBytes)
	if err != nil {
		return fmt.Errorf("error putting electricity GO into recipient private collection:%v", err)
	}
	

	return nil
}

func (s *SmartContract) TransfereGObyAmount(ctx contractapi.TransactionContextInterface) ([]string, error) {

	type TransfereGOtransientinputstruct struct {
		EGOList string `json:"EGOList"`
		Recipient string `json:"Recipient"`
		Neededamount json.Number `json:"Neededamount"`
	}

	//ABAC:
	err := ctx.GetClientIdentity().AssertAttributeValue("electricitytrustedUser", "true")
	if err != nil {
		return nil, fmt.Errorf("submitting User not authorized to transfer electricity GOs: %v", err)
	}
	
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return nil, fmt.Errorf("error getting transient: %v", err)
	}

	TransferInputDataAsBytes, ok := transientMap["TransferInput"]
	if !ok {
		return nil, fmt.Errorf("transfer Input must be a key in transient map:%v", ok)
	}

	if len(TransferInputDataAsBytes) == 0 {
		return nil, fmt.Errorf("transfer Input must be non-empty")
	}
	
	var TransfereGOtransientinput TransfereGOtransientinputstruct
	err = json.Unmarshal(TransferInputDataAsBytes, &TransfereGOtransientinput)
	if err != nil {
		return nil, fmt.Errorf("failed to decode JSON input of: " + string(TransferInputDataAsBytes) + ". The error is: " + err.Error())
	}

	NeededAmount, err := TransfereGOtransientinput.Neededamount.Float64()
	if err != nil {
		return nil, fmt.Errorf("error turning needed amount into a float")
	}

	var privateCollectionID string
	if TransfereGOtransientinput.Recipient == "hproducerMSP" {
		privateCollectionID = "privateDetails-hGO"
	} else if TransfereGOtransientinput.Recipient == "buyerMSP" {
		privateCollectionID = "privateDetails-buyer"
	} else {
		return nil, fmt.Errorf("recipient ID malformed - please try again")
	}
	EGOList := strings.Split(TransfereGOtransientinput.EGOList, "+")
	
	assetCounter := 0
	var currentAsset ElectricityGOprivatedetails
	var updatedAsset ElectricityGOprivatedetails
	var transferredMWh float64
	var test []string
	for transferredMWh = 0; transferredMWh < NeededAmount; transferredMWh = transferredMWh + currentAsset.AmountMWh {
		currentID := EGOList[assetCounter]
		currentAssetJSON, err := ctx.GetStub().GetPrivateData("privateDetails-eGO", currentID)
		if err != nil {
			return nil, fmt.Errorf("error getting private Details for eGO %v:%v", currentID, err)
		}
		err = json.Unmarshal(currentAssetJSON, &currentAsset)
		if err != nil {
			return nil, fmt.Errorf("error unmarshaling the current asset for transfer:%v", err)
		}
		
		updatedAsset.AssetID = currentAsset.AssetID 
		updatedAsset.OwnerID = TransfereGOtransientinput.Recipient
		updatedAsset.AmountMWh = currentAsset.AmountMWh 
		updatedAsset.Emissions = currentAsset.Emissions 
		updatedAsset.ElectricityProductionMethod = currentAsset.ElectricityProductionMethod
		
		assetCounter++
		
		if len(updatedAsset.AssetID) == 0 {
			return nil, fmt.Errorf("failed to change eGO owner")
		}
		updatedAssetasBytes, err := json.Marshal(updatedAsset)
		if err != nil {
			return nil, fmt.Errorf("error marshaling the updated eGO:%v", err)
		}
		err = ctx.GetStub().PutPrivateData(privateCollectionID, updatedAsset.AssetID, updatedAssetasBytes)
		if err != nil {
			return nil, fmt.Errorf("error putting electricity GO into recipient private collection:%v", err)
		}
		err = ctx.GetStub().DelPrivateData("privateDetails-eGO", currentAsset.AssetID)
		if err != nil {
			return nil, fmt.Errorf("error deleting electricity GO from electricity producer private collection:%v", err)
		}
		element := "During iteration" + strconv.Itoa(assetCounter) + strconv.Itoa(int(updatedAsset.AmountMWh)) + "MWhs were transferred"
		test = append(test, element)
	}
		
	excesstransferamount := transferredMWh - NeededAmount
	ratio := excesstransferamount/updatedAsset.AmountMWh
	updatedAsset.AmountMWh = updatedAsset.AmountMWh - excesstransferamount
	partialtransferemissions := (1 - ratio) * updatedAsset.Emissions
	partialasset := ElectricityGOprivatedetails{
		AssetID: updatedAsset.AssetID, 
		OwnerID: TransfereGOtransientinput.Recipient, 
		AmountMWh: updatedAsset.AmountMWh, 
		Emissions: partialtransferemissions, 
		ElectricityProductionMethod: updatedAsset.ElectricityProductionMethod,
	}	
	if len(partialasset.AssetID) == 0 {
		return nil, fmt.Errorf("failed to change eGO owner")
	}
	partialassetasBytes, err := json.Marshal(partialasset)
	if err != nil {
		return nil, fmt.Errorf("error marshaling the updated eGO:%v", err)
	}
	error := ctx.GetStub().PutPrivateData(privateCollectionID, partialasset.AssetID, partialassetasBytes)
	if error != nil {
		return nil, fmt.Errorf("error putting partial electricity GO into private collection of recipient:%v", error)
	}
	error1 := ctx.GetStub().DelPrivateData("privateDetails-eGO", partialasset.AssetID)
	if error1 != nil {
		return nil, fmt.Errorf("error deleting partial electricity GO from electricity producer private collection:%v", error1)
	}
	
	remainderemissions := updatedAsset.Emissions * ratio
	currentCounteGO := EGOcounter()
	eGOID := "eGO"+strconv.Itoa(int(currentCounteGO))
	partialasseteproducer := &ElectricityGOprivatedetails{AssetID: eGOID, OwnerID: "eproducerMSP", AmountMWh: excesstransferamount, Emissions: remainderemissions, ElectricityProductionMethod: currentAsset.ElectricityProductionMethod}
	if len(partialasseteproducer.AssetID) == 0 {
		return nil, fmt.Errorf("failed to create remainder GO for electricity producer")
	}
	partialasseteproducerasBytes, err := json.Marshal(partialasseteproducer)
	if err != nil {
		return nil, fmt.Errorf("error marshaling the updated eGO:%v", err)
	}
	error2 := ctx.GetStub().PutPrivateData("privateDetails-eGO", partialasseteproducer.AssetID, partialasseteproducerasBytes)
	if error2 != nil {
		return nil, fmt.Errorf("error putting partial electricity GO into electricity producer private collection:%v", error2)
	}
			
	return test, nil	

	}

//This next function creates hydrogen GOs by reading electricity GOs from own collection, 
//cancelling the correct amount, 
//reading the remaining amount of MWhs and emissions back into the collection
//issuing a cancellation statement for the cancelled MWh
func (s *SmartContract) IssuehGO(ctx contractapi.TransactionContextInterface) error {
	
	type IssuehGOtransientinputstruct struct {
		EGOList string `json:"EGOList"`
	}

	//ABAC:
	err := ctx.GetClientIdentity().AssertAttributeValue("hydrogentrustedUser", "true")
	if err != nil {
		return fmt.Errorf("submitting User not authorized to issue hydrogen GOs: %v", err)
	}
	hGOClientID, error := getClientOrgID(ctx)
	if error != nil {
		return fmt.Errorf("error while getting client ID")
	}

	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return fmt.Errorf("error getting transient: %v", err)
	}

	IssueInputDataAsBytes, ok := transientMap["IssueInput"]
	if !ok {
		return fmt.Errorf("hydrogen GO Issuance Input must be a key in transient map:%v", ok)
	}

	if len(IssueInputDataAsBytes) == 0 {
		return fmt.Errorf("hydrogen GO Issuance Input must be non-empty")
	}

	var IssuehGOtransientinput IssuehGOtransientinputstruct
	err = json.Unmarshal(IssueInputDataAsBytes, &IssuehGOtransientinput)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input of: " + string(IssueInputDataAsBytes) + ". The error is: " + err.Error())
	}

	//read backlog:
	backlogtobeissuedJSON, err := ctx.GetStub().GetPrivateData("privateDetails-hGO", "hydrogenbacklog")
	if err != nil {
		return fmt.Errorf("error getting hydrogen backlog private details:%v", err)
	}
	if backlogtobeissuedJSON == nil {
		return fmt.Errorf("no backlog could be found:%v",err)
	}

	var backlogtobeissued *GreenHydrogenGObacklogprivatedetails
		err = json.Unmarshal(backlogtobeissuedJSON, &backlogtobeissued)
		if err != nil {
			return fmt.Errorf("error unmarshaling the current backlog to be issued:%v", err)
		}

	EGOList := strings.Split(IssuehGOtransientinput.EGOList, "+")
	
	//transcribing of 
	var hydrogenGO GreenHydrogenGO
	var hydrogenGOprivate GreenHydrogenGOprivatedetails
	var tobedeleted []string
	var inputGO ElectricityGOprivatedetails
	GOitemcounter := 0

	for hydrogenGOprivate.UsedMWh < backlogtobeissued.UsedMWh {
		currentID := EGOList[GOitemcounter]
		inputGOJSON, err := ctx.GetStub().GetPrivateData("privateDetails-hGO", currentID)
		if err != nil {
			return fmt.Errorf("error getting private Details for eGO %v:%v", currentID, err)
		}
		err = json.Unmarshal(inputGOJSON, &inputGO)
		if err != nil {
			return fmt.Errorf("error unmarshaling the current asset for transfer:%v", err)
		}
		hydrogenGOprivate.UsedMWh = hydrogenGOprivate.UsedMWh + inputGO.AmountMWh
		hydrogenGOprivate.InputEmissions = hydrogenGOprivate.InputEmissions + inputGO.Emissions
		hydrogenGOprivate.ElectricityProductionMethod = hydrogenGOprivate.ElectricityProductionMethod + "," + inputGO.ElectricityProductionMethod
		//make keylist of eGOs that are to be deleted
		tobedeleted = append(tobedeleted, inputGO.AssetID)
		GOitemcounter++
	}
	excess := hydrogenGOprivate.UsedMWh - backlogtobeissued.UsedMWh
	ratio := excess / hydrogenGOprivate.UsedMWh
	hydrogenGOprivate.UsedMWh = hydrogenGOprivate.UsedMWh - excess
	emissionsexcess := hydrogenGOprivate.InputEmissions - (ratio * hydrogenGOprivate.InputEmissions)
	 
	currentCounthGO := hGOcounter()
	hGOID := "hGO"+strconv.Itoa(int(currentCounthGO))

	hydrogenGOprivate.OwnerID = hGOClientID
	hydrogenGOprivate.AssetID = hGOID
	hydrogenGOprivate.Kilosproduced = backlogtobeissued.Kilosproduced
	hydrogenGOprivate.HydrogenProductionMethod = backlogtobeissued.HydrogenProductionMethod
	hydrogenGOprivate.EmissionsHydrogen = backlogtobeissued.EmissionsHydrogen

	hydrogenGO.AssetID = hGOID
	hydrogenGO.GOType = "hydrogen"
	now2, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("error getting timestamp:%v", err)
	}
	now2string := now2.String()
	hydrogenGO.CreationDateTime = now2string

	//delete eGOs
	//no cancellation statements are issued because the GO attributes are transcribed onto the living hydrogen GO
	
	deletioncounter := 0
	for deletioncounter < len(tobedeleted) {
		err = ctx.GetStub().DelPrivateData("privateDetails-hGO", tobedeleted[deletioncounter])
		if err != nil {
			return fmt.Errorf("error deleting transcribed electricity GO with ID %v from hydrogen producer private collection:%v", tobedeleted[deletioncounter], err)
		}
		err = ctx.GetStub().DelState(tobedeleted[deletioncounter])
		if err != nil {
			return fmt.Errorf("error deleting transcribed electricity GO with ID %v from hydrogen producer private collection:%v", tobedeleted[deletioncounter], err)
		}
		deletioncounter++
	}

	currentCounteGO1 := EGOcounter()
	eGOID1 := "eGO"+strconv.Itoa(int(currentCounteGO1))

	// issue eGO with excess emissions and MWhs
	excesseGO := ElectricityGO{
		AssetID: eGOID1,
		CreationDateTime: now2string,
		GOType: "electricity",
	}

	excesseGOpublicBytes, err := json.Marshal(excesseGO)
	if err != nil {
		return fmt.Errorf("failed to create excess eGO json:%v", err.Error())
	}

	err = ctx.GetStub().PutState(eGOID1, excesseGOpublicBytes)
	if err != nil {
		return fmt.Errorf("failed to put asset in public data:%v", err.Error())
	}
	
	excesseGOprivate := ElectricityGOprivatedetails{
		AssetID: eGOID1,
		OwnerID: hGOClientID,
		AmountMWh: excess,
		Emissions: emissionsexcess,
		ElectricityProductionMethod: "excessGO",
	}

	excesseGOprivateBytes, err := json.Marshal(excesseGOprivate)
	if err != nil {
		return fmt.Errorf("failed to create eGO json")
	}

	// Persist private immutable asset properties to hydrogen producer private data collection
	err = ctx.GetStub().PutPrivateData("privateDetails-hGO", eGOID1, excesseGOprivateBytes)
	if err != nil {
		return fmt.Errorf("unable to create asset private data")
	}

	//create hydrogen GO - public data
	hGOpublicBytes, err := json.Marshal(hydrogenGO)
	if err != nil {
		return fmt.Errorf("failed to create hGO json:%v", err.Error())
	}

	err = ctx.GetStub().PutState(hGOID, hGOpublicBytes)
	if err != nil {
		return fmt.Errorf("failed to put asset in public data:%v", err.Error())
	}

	//create hydrogen GO - private data
	hGOprivateBytes, err := json.Marshal(hydrogenGOprivate)
	if err != nil {
		return fmt.Errorf("failed to create eGO json")
	}

	err = ctx.GetStub().PutPrivateData("privateDetails-eGO", hGOID, hGOprivateBytes)
	if err != nil {
		return fmt.Errorf("unable to create hydrogen GO private data")
	}

	return nil
}

func (s *SmartContract) ClaimRenewableattributesElectricity(ctx contractapi.TransactionContextInterface) error {
	type ClaimRenewablesTransientInput struct {
		Collection string `json:"collection"`
		EGOID string `json:"eGOID"`
	}

	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return fmt.Errorf("error getting transient: %v", err)
	}
	claimrenewablesfunctioninputasbytes, ok := transientMap["ClaimRenewables"]
	if !ok {
		return fmt.Errorf("'ClaimRenewables' must be the key in the transient map:%v", ok)
	}

	if len(claimrenewablesfunctioninputasbytes) == 0 {
		return fmt.Errorf("claim Renewables function invoke must be non-empty")
	}
	var ClaimRenewablesInput ClaimRenewablesTransientInput
	err = json.Unmarshal(claimrenewablesfunctioninputasbytes, &ClaimRenewablesInput)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input with error: %v", err)
	}
	if ClaimRenewablesInput.Collection == "" {
		return fmt.Errorf("claim renewables must specify a collection")
	}
	if ClaimRenewablesInput.EGOID == "" {
		return fmt.Errorf("claim renewables must specify an electricity GO ID")
	}

	log.Printf("Reading private details of eGO with ID %v from collection %v", ClaimRenewablesInput.EGOID, ClaimRenewablesInput.Collection)
	eGOprivateJSON, err := ctx.GetStub().GetPrivateData(ClaimRenewablesInput.Collection, ClaimRenewablesInput.EGOID)
	if err != nil {
		return fmt.Errorf("failed to read asset details: %v", err)
	}
	if eGOprivateJSON == nil {
		log.Printf("Private details for eGO %v do not exist in collection %v", ClaimRenewablesInput.EGOID, ClaimRenewablesInput.Collection)
		return fmt.Errorf("no electricity GO with that ID exists")
	}
	var eGOprivate *ElectricityGOprivatedetails
	err = json.Unmarshal(eGOprivateJSON, &eGOprivate)
	if err != nil {
		return fmt.Errorf("failed to unmarshal JSON: %v", err)
	}
	currentCancelKeyCount := ECancelcounter()
	eCancellationkey := "eCancel"+strconv.Itoa(int(currentCancelKeyCount))
	now3, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("error creating transaction timestamp:%v", err)
	}
	creationtime3 := now3.String()

	eCancellationStatement := CancellationstatementElectricity{
		ECancellationkey: eCancellationkey,
		CancellationTime: creationtime3,
		OwnerID: eGOprivate.OwnerID,
		AmountMWh: eGOprivate.AmountMWh,
		Emissions: eGOprivate.Emissions,
		ElectricityProductionMethod: eGOprivate.ElectricityProductionMethod,
	}
	//deleting the electricity GO
	err = ctx.GetStub().DelState(ClaimRenewablesInput.EGOID)
	if err != nil {
		return fmt.Errorf("error deleting electricity GO from public data:%v", err)
	}
	err = ctx.GetStub().DelPrivateData(ClaimRenewablesInput.Collection, ClaimRenewablesInput.EGOID)
	if err != nil {
		return fmt.Errorf("error deleting electricity GO from private collection:%v", err)
	}

	//issuing the electricity cancellation statement
	eCancellationStatementasBytes, error4 := json.Marshal(eCancellationStatement)
	if error4 != nil {
		return fmt.Errorf("failed to marshal cancellation Statement")
	}

	err = ctx.GetStub().PutPrivateData(ClaimRenewablesInput.Collection, eCancellationStatement.ECancellationkey, eCancellationStatementasBytes) 
	if err != nil {
		return fmt.Errorf("failed to put cancellation statement into collection: %v", err)
	}
	return nil
}

func (s *SmartContract) ClaimRenewableattributesHydrogen(ctx contractapi.TransactionContextInterface) error {
	//claiming renewable attributes of Hydrogen by individual GOs. also should implement a claim by quantity function for both energy carriers. 
	type ClaimHydrogenTransientInput struct {
		Collection string `json:"collection"`
		HGOID string `json:"hGOID"`
	}

	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return fmt.Errorf("error getting transient: %v", err)
	}
	claimhydrogenfunctioninputasbytes, ok := transientMap["ClaimHydrogen"]
	if !ok {
		return fmt.Errorf("'ClaimHydrogen' must be the key in the transient map:%v", ok)
	}

	if len(claimhydrogenfunctioninputasbytes) == 0 {
		return fmt.Errorf("claim Renewables function invoke must be non-empty")
	}
	var ClaimHydrogenInput ClaimHydrogenTransientInput
	err = json.Unmarshal(claimhydrogenfunctioninputasbytes, &ClaimHydrogenInput)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input with error: %v", err)
	}
	if ClaimHydrogenInput.Collection == "" {
		return fmt.Errorf("claim Hydrogen invokation must specify a collection")
	}
	if ClaimHydrogenInput.HGOID == "" {
		return fmt.Errorf("claim Hydrogen invokation must specify a hGOID")
	}

	log.Printf("Reading private details of eGO with ID %v from collection %v", ClaimHydrogenInput.HGOID, ClaimHydrogenInput.Collection)
	hGOprivateJSON, err := ctx.GetStub().GetPrivateData(ClaimHydrogenInput.Collection, ClaimHydrogenInput.HGOID)
	if err != nil {
		return fmt.Errorf("failed to read asset details: %v", err)
	}
	if hGOprivateJSON == nil {
		log.Printf("Private details for eGO %v do not exist in collection %v", ClaimHydrogenInput.HGOID, ClaimHydrogenInput.Collection)
		return fmt.Errorf("no electricity GO with that ID exists")
	}
	var hGOprivate *GreenHydrogenGOprivatedetails
	err = json.Unmarshal(hGOprivateJSON, &hGOprivate)
	if err != nil {
		return fmt.Errorf("failed to unmarshal JSON: %v", err)
	}
	currentCancelKeyCount := HCancelcounter()
	hCancellationkey := "hCancel"+strconv.Itoa(int(currentCancelKeyCount))
	now4 := time.Now()
	creationtime4 := now4.String()

	hCancellationStatement := CancellationstatementHydrogen{
		HCancellationkey: hCancellationkey,
		CancellationTime: creationtime4,
		OwnerID: hGOprivate.OwnerID,
		Kilosproduced: hGOprivate.Kilosproduced,
		EmissionsHydrogen: hGOprivate.EmissionsHydrogen,
		HydrogenProductionMethod: hGOprivate.HydrogenProductionMethod,
		InputEmissions: hGOprivate.InputEmissions,
		ElectricityProductionMethod: hGOprivate.ElectricityProductionMethod,
		UsedMWh: hGOprivate.UsedMWh,
	}

	//deleting the hydrogen GO
	err = ctx.GetStub().DelState(ClaimHydrogenInput.HGOID)
	if err != nil {
		return fmt.Errorf("error deleting hydrogen GO from public data:%v", err)
	}
	err = ctx.GetStub().DelPrivateData(ClaimHydrogenInput.Collection, ClaimHydrogenInput.HGOID)
	if err != nil {
		return fmt.Errorf("error deleting hydrogen GO from private collection:%v", err)
	}

	//issuing the electricity cancellation statement
	hCancellationStatementasBytes, error4 := json.Marshal(hCancellationStatement)
	if error4 != nil {
		return fmt.Errorf("failed to marshal cancellation Statement")
	}

	err = ctx.GetStub().PutPrivateData(ClaimHydrogenInput.Collection, hCancellationStatement.HCancellationkey, hCancellationStatementasBytes) 
	if err != nil {
		return fmt.Errorf("failed to put cancellation statement into collection: %v", err)
	}
	return nil
}

func (s *SmartContract) GetcurrenteGOsList(ctx contractapi.TransactionContextInterface, startKey, endKey string) ([]*ElectricityGO, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()
	return ConstructeGOFromIterator(resultsIterator)
}

func (s *SmartContract) GetcurrenthGOsList(ctx contractapi.TransactionContextInterface, startKey, endKey string) ([]*GreenHydrogenGO, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()
	return ConstructhGOFromIterator(resultsIterator)
}

func (s *SmartContract) ReadPubliceGO(ctx contractapi.TransactionContextInterface, eGOID string) (*ElectricityGO, error) {
	eGOJSON, err := ctx.GetStub().GetState(eGOID)
	if err != nil {
		return nil, fmt.Errorf("failed to read public eGO information:%v", err)
	}
	if eGOJSON == nil {
		log.Printf("%v does not exist", eGOID)
		return nil, nil
	}
	var eGO *ElectricityGO
	err = json.Unmarshal(eGOJSON, &eGO)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal eGO:%v", err)
	}
	return eGO, nil
}

func (s *SmartContract) ReadPublichGO(ctx contractapi.TransactionContextInterface, hGOID string) (*GreenHydrogenGO, error) {
	hGOJSON, err := ctx.GetStub().GetState(hGOID)
	if err != nil {
		return nil, fmt.Errorf("failed to read public hGO information:%v", err)
	}
	if hGOJSON == nil {
		log.Printf("%v does not exist", hGOID)
		return nil, nil
	}
	var hGO *GreenHydrogenGO
	err = json.Unmarshal(hGOJSON, &hGO)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal hGO:%v", err)
	}
	return hGO, nil
}

func (s *SmartContract) ReadPrivatefromCollectioneGO(ctx contractapi.TransactionContextInterface, collection string, eGOID string) (*ElectricityGOprivatedetails, error) {
	log.Printf("Reading private details of eGO with ID %v from collection %v", eGOID, collection)
	eGOprivateJSON, err := ctx.GetStub().GetPrivateData(collection, eGOID)
	if err != nil {
		return nil, fmt.Errorf("failed to read asset details: %v", err)
	}
	if eGOprivateJSON == nil {
		log.Printf("Private details for eGO %v do not exist in collection %v", eGOID, collection)
		return nil, nil
	}
	var eGOprivate *ElectricityGOprivatedetails
	err = json.Unmarshal(eGOprivateJSON, &eGOprivate)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal JSON: %v", err)
	}
	return eGOprivate, nil
}

func (s *SmartContract) ReadPrivatefromCollectionhGO(ctx contractapi.TransactionContextInterface, collection string, hGOID string) (*GreenHydrogenGOprivatedetails, error) {
	log.Printf("Reading private details of hGO with ID %v from collection %v", hGOID, collection)
	hGOprivateJSON, err := ctx.GetStub().GetPrivateData(collection, hGOID)
	if err != nil {
		return nil, fmt.Errorf("failed to read asset details: %v", err)
	}
	if hGOprivateJSON == nil {
		log.Printf("Private details for eGO %v do not exist in collection %v", hGOID, collection)
		return nil, nil
	}
	var hGOprivate *GreenHydrogenGOprivatedetails
	err = json.Unmarshal(hGOprivateJSON, &hGOprivate)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal JSON: %v", err)
	}
	return hGOprivate, nil
}

func getClientOrgID(ctx contractapi.TransactionContextInterface) (string, error) {
	clientOrgID, found, err := ctx.GetClientIdentity().GetAttributeValue("organization")
	if err != nil {
		return "", fmt.Errorf("failed getting client's orgID: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute 'organization'")
	}

	return clientOrgID, nil
}

func GetPeerOrgID(ctx contractapi.TransactionContextInterface) (string, error) {
	peerOrgID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return "", fmt.Errorf("failed getting peer's orgID: %v", err)
	}

	return peerOrgID, nil
}

func getTechnologyTypeeGO(ctx contractapi.TransactionContextInterface) (string, error) {
	technologyType, found,  err := ctx.GetClientIdentity().GetAttributeValue("technologyType")
	if err != nil {
		return "", fmt.Errorf("failed getting Technology Type: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute technology type")
	}
	
	return technologyType, nil
}

func getEmissionIntensityeGO(ctx contractapi.TransactionContextInterface) (string, error) {
	emissionIntensity, found, err := ctx.GetClientIdentity().GetAttributeValue("emissionIntensity")
	if err != nil {
		return "", fmt.Errorf("failed getting emissionIntensity: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute maxEfficiency")
	}
	return emissionIntensity, nil
}

func getmaxEfficiencyeGO(ctx contractapi.TransactionContextInterface) (string, error) {
	maxEfficiency, found, err := ctx.GetClientIdentity().GetAttributeValue("maxEfficiency")
	if err != nil {
		return "", fmt.Errorf("failed getting maximum Efficiency: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute maxEfficiency")
	}
	return maxEfficiency, nil
}

func getmaxOutputhGO(ctx contractapi.TransactionContextInterface) (string, error) {
	maxOutput, found, err := ctx.GetClientIdentity().GetAttributeValue("maxOutput")
	if err != nil {
		return "", fmt.Errorf("failed getting maximum hourly Output:%v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute maxOutput")
	}
	return maxOutput, nil
}

func getEmissionIntensityhGO(ctx contractapi.TransactionContextInterface) (string, error) {
	emissionIntensity, found, err := ctx.GetClientIdentity().GetAttributeValue("emissionIntensity")
	if err != nil {
		return "", fmt.Errorf("failed getting emissionIntensity:%v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute emissionIntensity")
	}
	return emissionIntensity, nil
}

func getTechnologyTypehGO(ctx contractapi.TransactionContextInterface) (string, error) {
	technologyType, found,  err := ctx.GetClientIdentity().GetAttributeValue("technologyType")
	if err != nil {
		return "", fmt.Errorf("failed getting Technology Type: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute technology type")
	}
	
	return technologyType, nil
}

func getkwhperkilo(ctx contractapi.TransactionContextInterface) (string, error) {
	kwhperkilo, found, err := ctx.GetClientIdentity().GetAttributeValue("kwhperkilo")
	if err != nil {
		return "", fmt.Errorf("failed getting kwhperkilo: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute kwhperkilo")
	}
	return kwhperkilo, nil
}

func GetConversionEfficiency(ctx contractapi.TransactionContextInterface) (string, error) {
	conversionEfficiency, found, err := ctx.GetClientIdentity().GetAttributeValue("conversionEfficiency")
	if err != nil {
		return "", fmt.Errorf("failed getting conversionEfficiency: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute conversionEfficiency")
	}
	return conversionEfficiency, nil
}

func SetGOEndorsementpolicy(ctx contractapi.TransactionContextInterface, assetID string, orgsToEndorse []string) error {
	endorsementPolicy, err := statebased.NewStateEP(nil)
	if err != nil {
		return err
	}
	err = endorsementPolicy.AddOrgs(statebased.RoleTypePeer, orgsToEndorse...)
	if err != nil {
		return fmt.Errorf("failed to add org to endorsement policy: %v", err)
	}
	policy, err := endorsementPolicy.Policy()
	if err != nil {
		return fmt.Errorf("failed to create endorsement policy bytes from org: %v", err)
	}
	err = ctx.GetStub().SetStateValidationParameter(assetID, policy)
	if err != nil {
		return fmt.Errorf("failed to set validation parameter on asset: %v", err)
	}

	return nil
}

// This function allows the buyer of an electricity GO to validate the GO properties 
// by receiving the private data from the seller and checking their hash against on-chain hash recovered via the assetID
func (s *SmartContract) VerifyeGO(ctx contractapi.TransactionContextInterface, eGOID string) (bool, error) {
	transMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return false, fmt.Errorf("error getting transient: %v", err)
	}

	// Asset properties must be retrieved from the transient field as they are private
	immutablePropertiesJSON, ok := transMap["GO"]
	if !ok {
		return false, fmt.Errorf("asset_properties key not found in the transient map")
	}

	immutablePropertiesOnChainHash, err := ctx.GetStub().GetPrivateDataHash("privateDetails-eGO", eGOID)
	if err != nil {
		return false, fmt.Errorf("failed to read asset private properties hash from seller's collection: %v", err)
	}
	if immutablePropertiesOnChainHash == nil {
		return false, fmt.Errorf("asset private properties hash does not exist: %s", eGOID)
	}

	hash := sha256.New()
	hash.Write(immutablePropertiesJSON)
	calculatedPropertiesHash := hash.Sum(nil)

	// verify that the hash of the passed immutable properties matches the on-chain hash
	if !bytes.Equal(immutablePropertiesOnChainHash, calculatedPropertiesHash) {
		return false, fmt.Errorf("hash %x for passed immutable properties %s does not match on-chain hash %x",
			calculatedPropertiesHash,
			immutablePropertiesJSON,
			immutablePropertiesOnChainHash,
		)
	}

	// verify that the hash of the passed immutable properties and on chain hash matches the assetID
	if !(hex.EncodeToString(immutablePropertiesOnChainHash) == eGOID) {
		return false, fmt.Errorf("hash %x for passed immutable properties %s does match on-chain hash %x but do not match assetID %s: asset was altered from its initial form",
			calculatedPropertiesHash,
			immutablePropertiesJSON,
			immutablePropertiesOnChainHash,
			eGOID)
	}
	return true, nil
}

func ConstructeGOFromIterator(resultsIterator shim.StateQueryIteratorInterface) ([]*ElectricityGO, error) {
	var eGOs []*ElectricityGO
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var eGO ElectricityGO
		err = json.Unmarshal(queryResult.Value, &eGO)
		if err != nil {
			return nil, err
		}
		eGOs = append(eGOs, &eGO)
	}

	return eGOs, nil
}

func ConstructhGOFromIterator(resultsIterator shim.StateQueryIteratorInterface) ([]*GreenHydrogenGO, error) {
	var hGOs []*GreenHydrogenGO
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var hGO GreenHydrogenGO
		err = json.Unmarshal(queryResult.Value, &hGO)
		if err != nil {
			return nil, err
		}
		hGOs = append(hGOs, &hGO)
	}

	return hGOs, nil
}

func (c *Count) Incr() {
    c.mx.Lock()
    c.count++
    c.mx.Unlock()
}

func (c *Count) Count() int {
    c.mx.Lock()
    count := c.count
    c.mx.Unlock()
    return count
}

func EGOcounter() int {
	EGOcount.Incr()
	Returnval := EGOcount.count / 2
	return Returnval
}

func hGOcounter() int {
	HGOcount.Incr()
	return HGOcount.count
}

func ECancelcounter() int {
	ECancellations.Incr()
	return ECancellations.count
}

func HCancelcounter() int {
	HCancellations.Incr()
	return HCancellations.count
}
