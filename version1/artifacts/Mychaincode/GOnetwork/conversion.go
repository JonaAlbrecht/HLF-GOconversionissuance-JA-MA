package GOnetwork

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"sort"
	"strconv"
	"strings"
	"sync"

	"github.com/hyperledger/fabric-chaincode-go/pkg/statebased"
	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

type ElectricityGO struct {
	AssetID string `json:"AssetID"`
	CreationDateTime int64 `json:"CreationDateTime"`
	GOType string `json:"GOType"`
}

type ElectricityGOprivatedetails struct {
	AssetID string `json:"AssetID"`
	OwnerID string `json:"OwnerID"`
	CreationDateTime int64 `json:"CreationDateTime"`
	AmountMWh float64 `json:"AmountMWh"`
	Emissions float64 `json:"Emissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	ConsumptionDeclarations []string `json:"ConsumptionDeclarations"`
}

type GreenHydrogenGO struct {
	AssetID string `json:"AssetID"`
	CreationDateTime int64 `json:"CreationDateTime"`
	GOType string `json:"GOType"`
}

type GreenHydrogenGOprivatedetails struct {
	AssetID string `json:"AssetID"`
	OwnerID string `json:"OwnerID"`
	CreationDateTime int64 `json:"CreationDateTime"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	InputEmissions float64 `json:"InputEmissions"`
	UsedMWh float64 `json:"UsedMWh"`
	ElectricityProductionMethod []string `json:"ElectricityProductionMethod"`
	ConsumptionDeclarations []string `json:"ConsumptionDeclarations"`
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
	CancellationTime int64 `json:"CancellationTime"`
	OwnerID string `json:"OwnerID"`
	AmountMWh float64 `json:"AmountMWh"`
	Emissions float64 `json:"Emissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	ConsumptionDeclarations []string `json:"ConsumptionDeclarations"`
}

// (see EN16325 4.9.2) A cancellation statement is an electronic, non-transferrable receipt which provides evidence of the cancellation of one or more GOs
//for the purpose of Disclosure of the Attributes of those GOs for the beneficiary or beneficiaries of the cancellation
type CancellationstatementHydrogen struct {
	HCancellationkey string `json:"hCancellationkey"`
	CancellationTime int64 `json:"CancellationTime"`
	OwnerID string `json:"OwnerID"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	InputEmissions float64 `json:"InputEmissions"`
	ElectricityProductionMethod []string `json:"ElectricityProductionMethod"`
	UsedMWh float64 `json:"UsedMWh"`
	ConsumptionDeclarations []string `json:"ConsumptionDeclarations"`
}

//(See EN16325 4.5.5.1.2 c), a Consumption Declaration shall contain the amount of Input, per
//Energy Carrier, during that period and the identity and relevant Attributes of the GOs Cancelled
//to Disclose the Attributes of that energy
type ConsumptionDeclarationElectricity struct {
	Consumptionkey string `json:"Consumptionkey"`
	CancelledGOID string `json:"CancelledGOID"`
	ConsumptionDateTime int64 `json:"ConsumptionDateTime"`
	AmountMWh float64 `json:"AmountMWh"`
	Emissions float64 `json:"Emissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	ConsumptionDeclarations []string `json:"ConsumptionDeclarations"`
}

type ConsumptionDeclarationHydrogen struct {
	Consumptionkey string `json:"Consumptionkey"`
	CancelledGOID string `json:"CancelledGOID"`
	ConsumptionDateTime string `json:"ConsumptionDateTime"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	ConsumptionDeclarations []string `json:"ConsumptionDeclarations"`
}

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
var EConsumptions = NewCount()
var HConsumptions = NewCount()

// GO expiry for electricity GOs was set to one hour for scalability testing purposes, although the preferred expiry period for time-granular GOs in the literature is 15 minutes
// However, time granularity can be easily adapted by changing this variable to 900 (15 Minutes) before deploying and committing the chaincode 
// Hydrogen GOs do not have an expiry time
var ExpiryPeriod int64 = 3600
// Minimum time that needs to be left until expiry for a GO to be still eligible for transfer, set to 5 Minutes. 
// Otherwise a recipient might have no time for cancelling GOs. 
var SafetyMargin int64 = 300

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
	eGOID := "eGO"+strconv.Itoa(currentCounteGO)
	
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
	testifexist, err := ctx.GetStub().GetPrivateData("privateDetails-eproducerMSP", eGOID)
	if err != nil {
		return fmt.Errorf("Failed to get data: " + err.Error())
	} else if testifexist != nil {
		return fmt.Errorf("This GO Asset ID already exists: " + eGOID)
	}
	
	// need to change this such that eproducerMSP is an attribute in the certificate. 
	//get ID of submitting Client Identity
	clientID, err := getOrgAttr(ctx)
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

	now, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("error getting timestamp:%v", err)
	}
	creationtime := now.GetSeconds()

	eGO := ElectricityGO{
		AssetID: eGOID,
		CreationDateTime: creationtime,
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
		CreationDateTime: creationtime,
		AmountMWh: eGOInput.AmountMWh,
		Emissions: eGOInput.Emissions,
		ElectricityProductionMethod: eGOInput.ElectricityProductionMethod,
		ConsumptionDeclarations: []string{"none"},
	}

	eGOprivateBytes, err := json.Marshal(eGOprivate)
	if err != nil {
		return fmt.Errorf("failed to create eGO json")
	}
	collection := "privateDetails-" + clientID
	// Write private immutable asset properties into owner's private data collection
	err = ctx.GetStub().PutPrivateData(collection, eGOID, eGOprivateBytes)
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
	organization, err := getOrgAttr(ctx)
	if err != nil {
		return fmt.Errorf("error while retrieving Organization Attribute from X509 certificate: %v", err)
	}
	collection := "privateDetails-" + organization
	
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
	backlogJSON, err := ctx.GetStub().GetPrivateData(collection, backlogkey)
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
			OwnerID: organization,
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
		err = ctx.GetStub().PutPrivateData(collection, backlogkey, hGObacklogprivateBytes)
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
		err = ctx.GetStub().PutPrivateData(collection, currentbacklog.Backlogkey, hGObacklogprivateBytes)
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
	//this sorts the eGOs by earliest expiry such that the owner transfers their most urgent GOs first
	sort.Slice(results, func(i, j int) bool { return results[i].CreationDateTime < results[j].CreationDateTime })
	timestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return nil, fmt.Errorf("failed to create transaction timestamp: %v", err)
	}
	timecheck := timestamp.GetSeconds() - ExpiryPeriod + SafetyMargin
	for i := 0; i < len(results); i++ {
		if timecheck > results[i].CreationDateTime {
			results = remove(results, i)
		}
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
func (s *SmartContract) QueryPrivatehGOsbyAmount(ctx contractapi.TransactionContextInterface) ([]string, error) {
	
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
	clientID, err := getClientOrgID(ctx)
	if err != nil {
		return nil, fmt.Errorf("client ID could not be read from transaction context: %v", err)
	}
	collectionID := "privateDetails-" + clientID
	backlogprivateJSON, err := ctx.GetStub().GetPrivateData(collectionID, backlogkey)
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
	err := ctx.GetClientIdentity().AssertAttributeValue("TrustedUser", "true")
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
	receiverCollectionID := "privateDetails-" + TransfereGOtransientinput.Recipient
	ClientID, err := getClientOrgID(ctx)
	if err != nil {
		return fmt.Errorf("error while getting client ID:%v", err)
	}

	var senderCollectionID string
	if ClientID == "eproducerMSP" {
		senderCollectionID = "privateDetails-eGO"
	} else if ClientID == "hproducerMSP" {
		senderCollectionID = "privateDetails-eGO"
	} else if ClientID == "buyerMSP" {
		senderCollectionID = "privateDetails-buyer"
	} else {
		return fmt.Errorf("sender ID malformed - please try again")
	}
	var currentAsset ElectricityGOprivatedetails
	currentAssetJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, TransfereGOtransientinput.EGO)
	if err != nil {
		return fmt.Errorf("error getting private Details for eGO %v:%v", TransfereGOtransientinput.EGO, err)
	}
	err = json.Unmarshal(currentAssetJSON, &currentAsset)
	if err != nil {
		return fmt.Errorf("error unmarshaling the current asset for transfer:%v", err)
	}
	// expiry check
	timestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to read timestamp: %v", err)
	}
	timecheck := timestamp.GetSeconds() - ExpiryPeriod + SafetyMargin
	if timecheck > currentAsset.CreationDateTime {
		return fmt.Errorf("the electricity GO with ID %v is no longer eligible for transfer and might be expired", currentAsset.AssetID)
	}
	currentAsset.OwnerID = TransfereGOtransientinput.Recipient
	for i := 0; i < len(currentAsset.ConsumptionDeclarations); i++ {
		bool1 := strings.HasPrefix(currentAsset.ConsumptionDeclarations[i], "eCon")
		if (bool1) {
			ConsumptionDeclarationJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, currentAsset.ConsumptionDeclarations[i])
			if err != nil {
				return fmt.Errorf("error transferring consumption declarations:%v", err)
			}
			err = ctx.GetStub().PutPrivateData(receiverCollectionID, currentAsset.ConsumptionDeclarations[i], ConsumptionDeclarationJSON)
			if err != nil {
				return fmt.Errorf("error transferring consumption declarations:%v", err)
			}
			err = ctx.GetStub().DelPrivateData(senderCollectionID, currentAsset.ConsumptionDeclarations[i])
			if err != nil {
				return fmt.Errorf("error transferring consumption declarations:%v", err)
			}
		}
	}
	
	err = ctx.GetStub().DelPrivateData(senderCollectionID, TransfereGOtransientinput.EGO)
	if err != nil {
		return fmt.Errorf("error deleting electricity GO from electricity producer private collection:%v", err)
	}

	updatedAssetasBytes, err := json.Marshal(currentAsset)
	if err != nil {
		return fmt.Errorf("error marshaling the updated eGO:%v", err)
	}
	err = ctx.GetStub().PutPrivateData(receiverCollectionID, TransfereGOtransientinput.EGO, updatedAssetasBytes)
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
	err := ctx.GetClientIdentity().AssertAttributeValue("TrustedUser", "true")
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
	receiverCollectionID := "privateDetails-" + TransfereGOtransientinput.Recipient
	ClientID, err := getClientOrgID(ctx)
	if err != nil {
		return nil, fmt.Errorf("error while getting client ID:%v", err)
	}
	senderCollectionID := "privateDetails-" + ClientID
	EGOList := strings.Split(TransfereGOtransientinput.EGOList, "+")
	timestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return nil, fmt.Errorf("failed to read timestamp: %v", err)
	}
	timecheck := timestamp.GetSeconds() - ExpiryPeriod + SafetyMargin
	assetCounter := 0
	var currentAsset ElectricityGOprivatedetails
	var transferredMWh float64
	var test []string
	transferredMWh = 0
	for transferredMWh < NeededAmount {
		currentID := EGOList[assetCounter]
		currentAssetJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, currentID)
		if err != nil {
			return nil, fmt.Errorf("error getting private Details for eGO %v:%v", currentID, err)
		}
		err = json.Unmarshal(currentAssetJSON, &currentAsset)
		if err != nil {
			return nil, fmt.Errorf("error unmarshaling the current asset for transfer:%v", err)
		}
		transferredMWh = transferredMWh + currentAsset.AmountMWh
		if transferredMWh < NeededAmount {
			//for brevity, could also be solved by only changing the OwnerID value for currentAsset, as is done in TransferhGObyAmount function
			updatedAsset := ElectricityGOprivatedetails{
				AssetID: currentAsset.AssetID,
				OwnerID: TransfereGOtransientinput.Recipient,
				CreationDateTime: currentAsset.CreationDateTime,
				AmountMWh: currentAsset.AmountMWh,
				Emissions: currentAsset.Emissions,
				ConsumptionDeclarations: currentAsset.ConsumptionDeclarations,
			}
			for i := 0; i < len(updatedAsset.ConsumptionDeclarations); i++ {
				bool1 := strings.HasPrefix(updatedAsset.ConsumptionDeclarations[i], "eCon")
				bool2 := strings.HasPrefix(updatedAsset.ConsumptionDeclarations[i], "hCon")
				// || represents a logical OR 
				if bool1 || bool2 {
					ConsumptionDeclarationJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, currentAsset.ConsumptionDeclarations[i])
					if err != nil {
						return nil, fmt.Errorf("error transferring consumption declarations:%v", err)
					}
					err = ctx.GetStub().PutPrivateData(receiverCollectionID, currentAsset.ConsumptionDeclarations[i], ConsumptionDeclarationJSON)
					if err != nil {
						return nil, fmt.Errorf("error transferring consumption declarations:%v", err)
					}
					err = ctx.GetStub().DelPrivateData(senderCollectionID, currentAsset.ConsumptionDeclarations[i])
					if err != nil {
						return nil, fmt.Errorf("error transferring consumption declarations:%v", err)
					}
				} 
			}
			if timecheck > currentAsset.CreationDateTime {
				return nil, fmt.Errorf("the asset %v is no longer eligible for transfer and might be expired", currentAsset.AssetID)
			}
			updatedAssetasBytes, err := json.Marshal(updatedAsset)
			if err != nil {
				return nil, fmt.Errorf("error marshaling the updated eGO:%v", err)
			}
			err = ctx.GetStub().PutPrivateData(receiverCollectionID, updatedAsset.AssetID, updatedAssetasBytes)
			if err != nil {
				return nil, fmt.Errorf("error putting electricity GO into recipient private collection:%v", err)
			} 
			err = ctx.GetStub().DelPrivateData(senderCollectionID, updatedAsset.AssetID)
			if err != nil {
				return nil, fmt.Errorf("error deleting electricity GO from sender private collection:%v", err)
			}
			element := "During iteration" + strconv.Itoa(assetCounter) + strconv.Itoa(int(updatedAsset.AmountMWh)) + "MWhs were transferred"
			test = append(test, element)
		} else {
			excessamount := transferredMWh - NeededAmount
			ratio := excessamount/currentAsset.AmountMWh
			partialtransferamount := currentAsset.AmountMWh - excessamount
			partialtransferemissions := (1 - ratio) * currentAsset.Emissions
			excessemissions := ratio * currentAsset.Emissions
			ConsumptionDeclarations := append(currentAsset.ConsumptionDeclarations, "split")
			partialasset := ElectricityGOprivatedetails{
				AssetID: currentAsset.AssetID, 
				OwnerID: TransfereGOtransientinput.Recipient, 
				CreationDateTime: currentAsset.CreationDateTime,
				AmountMWh: partialtransferamount, 
				Emissions: partialtransferemissions, 
				ElectricityProductionMethod: currentAsset.ElectricityProductionMethod,
				ConsumptionDeclarations: ConsumptionDeclarations,
			}	
			for i := 0; i < len(partialasset.ConsumptionDeclarations); i++ {
				bool1 := strings.HasPrefix(partialasset.ConsumptionDeclarations[i], "eCon")
				bool2 := strings.HasPrefix(partialasset.ConsumptionDeclarations[i], "hCon")
				if bool1 || bool2 {
					ConsumptionDeclarationJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, partialasset.ConsumptionDeclarations[i])
					if err != nil {
						return nil, fmt.Errorf("error transferring consumption declarations:%v", err)
					}
					err = ctx.GetStub().PutPrivateData(receiverCollectionID, partialasset.ConsumptionDeclarations[i], ConsumptionDeclarationJSON)
					if err != nil {
						return nil, fmt.Errorf("error transferring consumption declarations:%v", err)
					}
				}	
			}
			if timecheck > currentAsset.CreationDateTime {
				return nil, fmt.Errorf("the asset %v is no longer eligible for transfer and might be expired", currentAsset.AssetID)
			}

			partialassetasBytes, err := json.Marshal(partialasset)
			if err != nil {
				return nil, fmt.Errorf("error marshaling the updated eGO:%v", err)
			}
			errora := ctx.GetStub().PutPrivateData(receiverCollectionID, partialasset.AssetID, partialassetasBytes)
			if errora != nil {
				return nil, fmt.Errorf("error putting partial electricity GO into private collection of recipient:%v", errora)
			}
			error1 := ctx.GetStub().DelPrivateData(senderCollectionID, partialasset.AssetID)
			if error1 != nil {
				return nil, fmt.Errorf("error deleting partial electricity GO from sender private collection:%v", error1)
			}
			currentCounteGO := EGOcounter()
			eGOID := "eGO"+strconv.Itoa(currentCounteGO)
			partialassetsenderpublic := ElectricityGO{
				AssetID: eGOID, 
				CreationDateTime: currentAsset.CreationDateTime,
				GOType: "Electricity",
			}
			partialassetsender := ElectricityGOprivatedetails{
				AssetID: eGOID, 
				OwnerID: ClientID,
				CreationDateTime: currentAsset.CreationDateTime, 
				AmountMWh: excessamount, 
				Emissions: excessemissions, 
				ElectricityProductionMethod: currentAsset.ElectricityProductionMethod, 
				ConsumptionDeclarations: ConsumptionDeclarations,
			}
			partialassetsenderpublicBytes, err := json.Marshal(partialassetsenderpublic)
			if err != nil {
				return nil, fmt.Errorf("error marshaling the remainder public GO info: %v", err)
			}
			errorc := ctx.GetStub().PutState(partialassetsenderpublic.AssetID, partialassetsenderpublicBytes)
			if errorc != nil {
				return nil, fmt.Errorf("error publishing the public eGO information for remainder: %v", errorc)
			}
			partialasseteproducerasBytes, err := json.Marshal(partialassetsender)
			if err != nil {
				return nil, fmt.Errorf("error marshaling the remainder private GO info: %v", err)
			}
			error2 := ctx.GetStub().PutPrivateData("privateDetails-eGO", partialassetsender.AssetID, partialasseteproducerasBytes)
			if error2 != nil {
				return nil, fmt.Errorf("error putting partial electricity GO into sender private collection:%v", error2)
			}
		}
		assetCounter++
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

	now2, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("error getting timestamp:%v", err)
	}
	now2int := now2.GetSeconds()
	//no expiry period implemented for Hydrogen
	//timecheck := now2int - ExpiryPeriod

	for hydrogenGOprivate.UsedMWh < backlogtobeissued.UsedMWh {
		currentID := EGOList[GOitemcounter]
		GOitemcounter++
		inputGOJSON, err := ctx.GetStub().GetPrivateData("privateDetails-hGO", currentID)
		if err != nil {
			return fmt.Errorf("error getting private Details for eGO %v:%v", currentID, err)
		}
		err = json.Unmarshal(inputGOJSON, &inputGO)
		if err != nil {
			return fmt.Errorf("error unmarshaling the current asset for transfer:%v", err)
		}
		//if timecheck > inputGO.CreationDateTime {return fmt.Errorf("the asset %v is expired", inputGO.AssetID)}
		hydrogenGOprivate.UsedMWh = hydrogenGOprivate.UsedMWh + inputGO.AmountMWh
		hydrogenGOprivate.InputEmissions = hydrogenGOprivate.InputEmissions + inputGO.Emissions
		hydrogenGOprivate.ElectricityProductionMethod = append(hydrogenGOprivate.ElectricityProductionMethod, inputGO.ElectricityProductionMethod)
		hydrogenGOprivate.ConsumptionDeclarations = append(hydrogenGOprivate.ConsumptionDeclarations, inputGO.ConsumptionDeclarations...)
		hydrogenGOprivate.ConsumptionDeclarations = append(hydrogenGOprivate.ConsumptionDeclarations, inputGO.AssetID)
		//make keylist of eGOs that are to be deleted
		tobedeleted = append(tobedeleted, inputGO.AssetID)
		currenteConsumpkey := EConsumptioncounter()
		Consumptionkey := "eCon"+strconv.Itoa(currenteConsumpkey)
		ConsumptionDeclaration := ConsumptionDeclarationElectricity{
			Consumptionkey: Consumptionkey, 
			CancelledGOID: inputGO.AssetID,
			ConsumptionDateTime: now2int,
			AmountMWh: inputGO.AmountMWh,
			Emissions: inputGO.Emissions,
			ElectricityProductionMethod: inputGO.ElectricityProductionMethod,
			ConsumptionDeclarations: inputGO.ConsumptionDeclarations,
		}
		ConsumptionDeclarationBytes, err := json.Marshal(ConsumptionDeclaration)
		if err != nil {
			return fmt.Errorf("error marshalling consumption declaration: %v", err)
		}
		error2 := ctx.GetStub().PutPrivateData("privateDetails-hGO", Consumptionkey, ConsumptionDeclarationBytes)
		if error2 != nil {
			return fmt.Errorf("error creating Consumption Declarations:%v", err)
		}
		
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
	hydrogenGO.GOType = "Hydrogen"
	
	hydrogenGO.CreationDateTime = now2int

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
		CreationDateTime: inputGO.CreationDateTime,
		GOType: "Electricity",
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
		CreationDateTime: inputGO.CreationDateTime,
		AmountMWh: excess,
		Emissions: emissionsexcess,
		ElectricityProductionMethod: "excessGO",
		ConsumptionDeclarations: []string{"none"},
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

func (s *SmartContract) TansferhGObyAmount(ctx contractapi.TransactionContextInterface) error {
	type TransferhGOtransientinputstruct struct {
		HGOList string `json:"HGOList"`
		Recipient string `json:"Recipient"`
		NeededKilos json.Number `json:"NeededKilos"`
	}
	//ABAC:
	err := ctx.GetClientIdentity().AssertAttributeValue("TrustedUser", "true")
	if err != nil {
		return fmt.Errorf("submitting User not authorized to transfer hydrogen GOs: %v", err)
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
	var TransferhGOtransientinput TransferhGOtransientinputstruct
	err = json.Unmarshal(TransferInputDataAsBytes, &TransferhGOtransientinput)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input of: " + string(TransferInputDataAsBytes) + ". The error is: " + err.Error())
	}
	NeededKilos, err := TransferhGOtransientinput.NeededKilos.Float64()
	if err != nil {
		return fmt.Errorf("error turning needed kilos into a float")
	}
	receiverCollectionID :=  "privateDetails-" + TransferhGOtransientinput.Recipient
	ClientID, err := getClientOrgID(ctx)
	if err != nil {
		return fmt.Errorf("error while getting client ID:%v", err)
	}
	senderCollectionID := "privateDetails-" + ClientID
	HGOList := strings.Split(TransferhGOtransientinput.HGOList, "+")
	var currentAsset GreenHydrogenGOprivatedetails
	assetCounter := 0
	var transferredKilos float64
	transferredKilos = 0
	for transferredKilos < NeededKilos {
		currentID := HGOList[assetCounter]
		currentAssetJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, currentID)
		if err != nil {
			return fmt.Errorf("error getting private data for hGO %v: %v", currentID, err)
		}
		err = json.Unmarshal(currentAssetJSON, &currentAsset)
		if err != nil {
			return fmt.Errorf("error unmarshaling the current Asset for transfer: %v", err)
		}
		transferredKilos = transferredKilos + currentAsset.Kilosproduced
		if transferredKilos < NeededKilos {
			currentAsset.OwnerID = TransferhGOtransientinput.Recipient
			for i := 0; i < len(currentAsset.ConsumptionDeclarations); i++ {
				bool1 := strings.HasPrefix(currentAsset.ConsumptionDeclarations[i], "eCon")
				bool2 := strings.HasPrefix(currentAsset.ConsumptionDeclarations[i], "hCon")
				if bool1 || bool2 {
					ConsumptionDeclarationJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, currentAsset.ConsumptionDeclarations[i])
					if err != nil {
						return fmt.Errorf("error transferring consumption declarations:%v", err)
					}
					err = ctx.GetStub().PutPrivateData(receiverCollectionID, currentAsset.ConsumptionDeclarations[i], ConsumptionDeclarationJSON)
					if err != nil {
						return fmt.Errorf("error transferring consumption declarations:%v", err)
					}
					err = ctx.GetStub().DelPrivateData(senderCollectionID, currentAsset.ConsumptionDeclarations[i])
					if err != nil {
						return fmt.Errorf("error transferring consumption declarations:%v", err)
					}
				}
			}
			currentAssetasBytes, err := json.Marshal(currentAsset)
			if err != nil {
				return fmt.Errorf("error marshaling hGO for transfer: %v", err)
			}
			err = ctx.GetStub().PutPrivateData(receiverCollectionID, currentAsset.AssetID, currentAssetasBytes)
			if err != nil {
				return fmt.Errorf("error putting hydrogen GO into recipient private collection:%v", err)
			} 
			err = ctx.GetStub().DelPrivateData(senderCollectionID, currentAsset.AssetID)
			if err != nil {
				return fmt.Errorf("error deleting hydrogen GO from sender private collection:%v", err)
			}
		} else {
			excessKilos := transferredKilos - NeededKilos
			ratio := excessKilos/currentAsset.Kilosproduced
			partialtransferKilos := currentAsset.Kilosproduced - excessKilos
			partialtransferemissionsHydrogen := (1 - ratio) * currentAsset.EmissionsHydrogen
			excessemissionsHydrogen := ratio * currentAsset.EmissionsHydrogen
			partialtransferUsedMWh := (1 - ratio) * currentAsset.UsedMWh
			excessUsedMWh := ratio * currentAsset.UsedMWh
			partialtransferinputemissions := (1 - ratio) * currentAsset.InputEmissions
			excessinputemissions := ratio * currentAsset.InputEmissions
			ConsumptionDeclarations := append(currentAsset.ConsumptionDeclarations, "split")
			partialasset := GreenHydrogenGOprivatedetails{
				AssetID: currentAsset.AssetID,
				OwnerID: TransferhGOtransientinput.Recipient,
				CreationDateTime: currentAsset.CreationDateTime,
				Kilosproduced: partialtransferKilos,
				EmissionsHydrogen: partialtransferemissionsHydrogen,
				HydrogenProductionMethod: currentAsset.HydrogenProductionMethod,
				UsedMWh: partialtransferUsedMWh,
				InputEmissions: partialtransferinputemissions,
				ElectricityProductionMethod: currentAsset.ElectricityProductionMethod,
				ConsumptionDeclarations: ConsumptionDeclarations,
			}
			// consumption declarations dont get deleted from sender Collection, meaning they get duplicated in this step
			for i := 0; i < len(partialasset.ConsumptionDeclarations); i++ {
				bool1 := strings.HasPrefix(partialasset.ConsumptionDeclarations[i], "eCon")
				bool2 := strings.HasPrefix(partialasset.ConsumptionDeclarations[i], "hCon")
				if bool1 || bool2 {
					ConsumptionDeclarationJSON, err := ctx.GetStub().GetPrivateData(senderCollectionID, partialasset.ConsumptionDeclarations[i])
					if err != nil {
						return fmt.Errorf("error transferring consumption declarations:%v", err)
					}
					err = ctx.GetStub().PutPrivateData(receiverCollectionID, partialasset.ConsumptionDeclarations[i], ConsumptionDeclarationJSON)
					if err != nil {
						return fmt.Errorf("error transferring consumption declarations:%v", err)
					}
				}	
			}
			partialassetasBytes, err := json.Marshal(partialasset)
			if err != nil {
				return fmt.Errorf("error marshalling partial HGO for transfer: %v", err)
			}
			errord := ctx.GetStub().PutPrivateData(receiverCollectionID, partialasset.AssetID, partialassetasBytes)
			if errord != nil {
				return fmt.Errorf("error putting private hGO data into receiver private collection: %v", errord)
			}
			error1 := ctx.GetStub().DelPrivateData(senderCollectionID, partialasset.AssetID)
			if error1 != nil {
				return fmt.Errorf("error deleting partial hydrogen GO from sender private collection:%v", error1)
			}
			currentCounthGO := hGOcounter()
			hGOID := "hGO"+strconv.Itoa(currentCounthGO)
			partialassetsenderpublic := GreenHydrogenGO{
				AssetID: hGOID, 
				CreationDateTime: currentAsset.CreationDateTime,
				GOType: "Hydrogen",
			}
			partialassetsender := GreenHydrogenGOprivatedetails{
				AssetID: hGOID, 
				OwnerID: ClientID,
				CreationDateTime: currentAsset.CreationDateTime,
				Kilosproduced: excessKilos,
				EmissionsHydrogen: excessemissionsHydrogen,
				HydrogenProductionMethod: currentAsset.HydrogenProductionMethod,
				InputEmissions: excessinputemissions, 
				UsedMWh: excessUsedMWh,
				ElectricityProductionMethod: currentAsset.ElectricityProductionMethod,
				ConsumptionDeclarations: ConsumptionDeclarations,
			}
			partialassetsenderpublicBytes, err := json.Marshal(partialassetsenderpublic)
			if err != nil {
				return fmt.Errorf("error marshaling the remainder public GO info: %v", err)
			}
			errorc := ctx.GetStub().PutState(partialassetsenderpublic.AssetID, partialassetsenderpublicBytes)
			if errorc != nil {
				return fmt.Errorf("error publishing the public hGO information for remainder: %v", errorc)
			}
			partialassetprivateasBytes, err := json.Marshal(partialassetsender)
			if err != nil {
				return fmt.Errorf("error marshaling the remainder private GO info: %v", err)
			}
			error2 := ctx.GetStub().PutPrivateData(senderCollectionID, partialassetsender.AssetID, partialassetprivateasBytes)
			if error2 != nil {
				return fmt.Errorf("error putting partial hydrogen GO into sender private collection:%v", error2)
			}
		}
		assetCounter++
	}
	return nil
}

func (s *SmartContract) ClaimRenewableattributesElectricity(ctx contractapi.TransactionContextInterface) error {
	type ClaimRenewablesTransientInput struct {
		Collection string `json:"collection"`
		EGOList string `json:"EGOList"`
		Cancelamount json.Number `json:"Cancelamount"`
	}

	ClientID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil { 
		return fmt.Errorf("error getting MSPID: %v", err)
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
	Claimamount, err := ClaimRenewablesInput.Cancelamount.Float64()
	if err != nil {
		return fmt.Errorf("error converting json.number into float: %v", err)
	}
	var claimedamount float64
	EGOList := strings.Split(ClaimRenewablesInput.EGOList, "+")
	var eGOprivate *ElectricityGOprivatedetails
	assetCounter := 0
	claimedamount = 0
	now3, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("error creating transaction timestamp:%v", err)
	}
	currenttime := now3.GetSeconds()
	timecheck := currenttime - ExpiryPeriod
	for claimedamount < Claimamount {
		eGOprivateJSON, err := ctx.GetStub().GetPrivateData(ClaimRenewablesInput.Collection, EGOList[assetCounter])
		if err != nil {
			return fmt.Errorf("failed to read asset details: %v", err)
		}
		if eGOprivateJSON == nil {
			return fmt.Errorf("no electricity GO with that ID exists")
		}
		err = json.Unmarshal(eGOprivateJSON, &eGOprivate)
		if err != nil {
			return fmt.Errorf("failed to unmarshal JSON: %v", err)
		}
		currentCancelKeyCount := ECancelcounter()
		eCancellationkey := "eCancel"+strconv.Itoa(currentCancelKeyCount)
		claimedamount = claimedamount + eGOprivate.AmountMWh
		if claimedamount < Claimamount {
			eCancellationStatement := CancellationstatementElectricity{
				ECancellationkey: eCancellationkey,
				CancellationTime: currenttime,
				OwnerID: eGOprivate.OwnerID,
				AmountMWh: eGOprivate.AmountMWh,
				Emissions: eGOprivate.Emissions,
				ElectricityProductionMethod: eGOprivate.ElectricityProductionMethod,
				ConsumptionDeclarations: eGOprivate.ConsumptionDeclarations,
			}
			//expiry check
			if timecheck > eGOprivate.CreationDateTime {
				return fmt.Errorf("the electricity GO with ID %v is expired", eGOprivate.AssetID)
			}
			//deleting the electricity GO
			err = ctx.GetStub().DelState(EGOList[assetCounter])
			if err != nil {
				return fmt.Errorf("error deleting electricity GO from public data:%v", err)
			}
			err = ctx.GetStub().DelPrivateData(ClaimRenewablesInput.Collection, EGOList[assetCounter])
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
		} else {
			excesscancellationamount := claimedamount - Claimamount
			ratio := excesscancellationamount/eGOprivate.AmountMWh
			excessemissions := ratio * eGOprivate.Emissions
			tobecancelledemissions := (1 - ratio) * eGOprivate.Emissions
			ConsumptionDeclarations := append(eGOprivate.ConsumptionDeclarations, "split")
			stilltobecancelled := eGOprivate.AmountMWh - excesscancellationamount
			eCancellationStatement := CancellationstatementElectricity{
				ECancellationkey: eCancellationkey,
				CancellationTime: currenttime,
				OwnerID: eGOprivate.OwnerID,
				AmountMWh: stilltobecancelled,
				Emissions: tobecancelledemissions,
				ElectricityProductionMethod: eGOprivate.ElectricityProductionMethod,
				ConsumptionDeclarations: ConsumptionDeclarations,
			}
			//expiry check
			if timecheck > eGOprivate.CreationDateTime {
				return fmt.Errorf("the electricity GO with ID %v is expired", eGOprivate.AssetID)
			}
			currentCounteGO := EGOcounter()
			eGOID := "eGO"+strconv.Itoa(currentCounteGO)
			GOforissuepublic := ElectricityGO{
				AssetID: eGOID,
				CreationDateTime: currenttime,
				GOType: "Electricity",
			}
			GOforIssue := ElectricityGOprivatedetails{
				AssetID: eGOID, 
				OwnerID: ClientID,
				AmountMWh: excesscancellationamount,
				Emissions: excessemissions,
				ElectricityProductionMethod: eGOprivate.ElectricityProductionMethod,
				ConsumptionDeclarations: ConsumptionDeclarations,
			}
			//deleting the electricity GO
			err = ctx.GetStub().DelState(EGOList[assetCounter])
			if err != nil {
				return fmt.Errorf("error deleting electricity GO from public data:%v", err)
			}
			err = ctx.GetStub().DelPrivateData(ClaimRenewablesInput.Collection, EGOList[assetCounter])
			if err != nil {
				return fmt.Errorf("error deleting electricity GO from private collection:%v", err)
			}
			//issuing the electricity cancellation statement
			eCancellationStatementasBytes, error4 := json.Marshal(eCancellationStatement)
			if error4 != nil {
				return fmt.Errorf("failed to marshal cancellation Statement")
			}
			err = ctx.GetStub().PutPrivateData(ClaimRenewablesInput.Collection, eCancellationStatement.ECancellationkey, eCancellationStatementasBytes) 
			if err != nil {return fmt.Errorf("failed to put cancellation statement into collection: %v", err)}
			//issuing the remainder GO
			GOforissuepublicbytes, err := json.Marshal(GOforissuepublic)
			if err != nil { return fmt.Errorf("error marshaling json object for remainder GO: %v", err)}
			err = ctx.GetStub().PutState(eGOID, GOforissuepublicbytes)	
			if err != nil { return fmt.Errorf("error putting remainder GO into Public Data: %v", err)}
			GOforIssuebytes, err := json.Marshal(GOforIssue)
			if err != nil { return fmt.Errorf("error marshaling json object for remainder GO private data: %v", err)}
			err = ctx.GetStub().PutPrivateData(ClaimRenewablesInput.Collection, eGOID, GOforIssuebytes)
			if err != nil { return fmt.Errorf("error putting private data for remainder GO: %v", err)}	
		}

		assetCounter++
	}
	return nil
}

func (s *SmartContract) ClaimRenewableattributesHydrogen(ctx contractapi.TransactionContextInterface) error {
	//claiming renewable attributes of Hydrogen by individual GOs. also should implement a claim by quantity function for both energy carriers. 
	type ClaimHydrogenTransientInput struct {
		Collection string `json:"collection"`
		HGOList string `json:"HGOList"`
		Cancelamount json.Number `json:"Cancelamount"`
	}

	ClientID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("error getting MSPID: %v", err)
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
	Claimamount, err := ClaimHydrogenInput.Cancelamount.Float64()
	if err != nil {
		return fmt.Errorf("error converting json.number into float: %v", err)
	}
	var claimedamount float64
	HGOList := strings.Split(ClaimHydrogenInput.HGOList, "+")
	var hGOprivate *GreenHydrogenGOprivatedetails
	assetCounter := 0
	claimedamount = 0
	now, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("error creating transaction timestamp: %v", err)
	}
	creationtime := now.GetSeconds()
	for claimedamount < Claimamount {
		hGOprivateJSON, err := ctx.GetStub().GetPrivateData(ClaimHydrogenInput.Collection, HGOList[assetCounter])
		if err != nil { 
			return fmt.Errorf("failed to read asset details: %v", err)
		}
		if hGOprivateJSON == nil {
			return fmt.Errorf("no hydrogen GO with that ID exists")
		}
		err = json.Unmarshal(hGOprivateJSON, &hGOprivate)
		if err != nil { 
			return fmt.Errorf("failed to unmarshal JSON: %v", err)
		}
		currentCancelKeyCount := HCancelcounter()
		hCancellationkey := "hCancel"+strconv.Itoa(int(currentCancelKeyCount))
		claimedamount = claimedamount + hGOprivate.Kilosproduced
		if claimedamount < Claimamount {
			hCancellationStatement := CancellationstatementHydrogen{
				HCancellationkey: hCancellationkey,
				CancellationTime: creationtime,
				OwnerID: ClientID,
				Kilosproduced: hGOprivate.Kilosproduced,
				EmissionsHydrogen: hGOprivate.EmissionsHydrogen,
				HydrogenProductionMethod: hGOprivate.HydrogenProductionMethod,
				InputEmissions: hGOprivate.InputEmissions,
				ElectricityProductionMethod: hGOprivate.ElectricityProductionMethod,
				UsedMWh: hGOprivate.UsedMWh,
			}
			//deleting the hydrogen GO
			err = ctx.GetStub().DelState(HGOList[assetCounter])
			if err != nil { 
				return fmt.Errorf("error deleting hydrogen GO from public data:%v", err)
			}
			err = ctx.GetStub().DelPrivateData(ClaimHydrogenInput.Collection, HGOList[assetCounter])
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
		} else {
			excesscancellationamount := claimedamount - Claimamount
			ratio := excesscancellationamount/hGOprivate.Kilosproduced
			excessemissions := ratio * hGOprivate.EmissionsHydrogen
			tobecancelledemissions := (1 - ratio) * hGOprivate.EmissionsHydrogen
			ConsumptionDeclarations := append(hGOprivate.ConsumptionDeclarations, "split")
			stilltobecancelled := hGOprivate.Kilosproduced - excesscancellationamount
			tobecancelledinputemissions := (1 - ratio) * hGOprivate.InputEmissions
			excessinputemissions := ratio * hGOprivate.InputEmissions
			tobecancelledMWh := (1 - ratio) * hGOprivate.UsedMWh
			excessMWh := ratio * hGOprivate.UsedMWh
			hCancellationStatement := CancellationstatementHydrogen{
				HCancellationkey: hCancellationkey,
				CancellationTime: creationtime,
				OwnerID: hGOprivate.OwnerID,
				Kilosproduced: stilltobecancelled,
				EmissionsHydrogen: tobecancelledemissions,
				HydrogenProductionMethod: hGOprivate.HydrogenProductionMethod,
				InputEmissions: tobecancelledinputemissions,
				ElectricityProductionMethod: hGOprivate.ElectricityProductionMethod,
				UsedMWh: tobecancelledMWh,
				ConsumptionDeclarations: ConsumptionDeclarations,
			}

			currentCounthGO := hGOcounter()
			hGOID := "hGO"+strconv.Itoa(currentCounthGO)
			GOforissuepublic := GreenHydrogenGO{
				AssetID: hGOID,
				CreationDateTime: creationtime,
				GOType: "Hydrogen",
			}
			GOforIssue := GreenHydrogenGOprivatedetails{
				AssetID: hGOID, 
				OwnerID: ClientID,
				Kilosproduced: excesscancellationamount,
				EmissionsHydrogen: excessemissions,
				HydrogenProductionMethod: hGOprivate.HydrogenProductionMethod,
				InputEmissions: excessinputemissions,
				UsedMWh: excessMWh, 
				ElectricityProductionMethod: hGOprivate.ElectricityProductionMethod,
				ConsumptionDeclarations: ConsumptionDeclarations,
			}
			//deleting the Hydrogen GO
			err = ctx.GetStub().DelState(HGOList[assetCounter])
			if err != nil {
				return fmt.Errorf("error deleting electricity GO from public data:%v", err)
			}
			err = ctx.GetStub().DelPrivateData(ClaimHydrogenInput.Collection, HGOList[assetCounter])
			if err != nil {
				return fmt.Errorf("error deleting electricity GO from private collection:%v", err)
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
			//issuing the remainder GO
			GOforissuepublicbytes, err := json.Marshal(GOforissuepublic)
			if err != nil { 
				return fmt.Errorf("error marshaling json object for remainder GO: %v", err)
			}
			err = ctx.GetStub().PutState(hGOID, GOforissuepublicbytes)	
			if err != nil { 
				return fmt.Errorf("error putting remainder GO into Public Data: %v", err)
			}
			GOforIssuebytes, err := json.Marshal(GOforIssue)
			if err != nil { 
				return fmt.Errorf("error marshaling json object for remainder GO private data: %v", err)
			}
			err = ctx.GetStub().PutPrivateData(ClaimHydrogenInput.Collection, hGOID, GOforIssuebytes)
			if err != nil { 
				return fmt.Errorf("error putting private data for remainder GO: %v", err)
			}
		}
		assetCounter++
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

// need to put the reading into transient?
func (s *SmartContract) ReadPrivatefromCollectioneGO(ctx contractapi.TransactionContextInterface, collection string, eGOID string) (*ElectricityGOprivatedetails, error) {
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

func getOrgAttr(ctx contractapi.TransactionContextInterface) (string, error) {
	organization, found, err := ctx.GetClientIdentity().GetAttributeValue("organization")
	if err != nil {
		return "", fmt.Errorf("failed getting organisation attribute value from X509: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute 'organization'")
	}
	return organization, nil
}

func getClientOrgID(ctx contractapi.TransactionContextInterface) (string, error) {
	clientOrgID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return "", fmt.Errorf("failed getting client's orgID: %v", err)
	}
	return clientOrgID, nil
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
// This function is not vulnerable to a dictionary attack because of added salt
func (s *SmartContract) VerifyCancellationStatement(ctx contractapi.TransactionContextInterface, eGOID string, Sellercollection string) (bool, error) {
	transMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return false, fmt.Errorf("error getting transient: %v", err)
	}
	// Asset properties must be retrieved from the transient field as they are private
	immutablePropertiesJSON, ok := transMap["CancelStatement"]
	if !ok {
		return false, fmt.Errorf("asset_properties key not found in the transient map")
	}
	immutablePropertiesOnChainHash, err := ctx.GetStub().GetPrivateDataHash(Sellercollection, eGOID)
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
	return EGOcount.count
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
func EConsumptioncounter() int {
	EConsumptions.Incr()
	return EConsumptions.count
}
func HConsumptioncounter() int {
	HConsumptions.Incr()
	return HConsumptions.count
}

func remove[T any](slice []T, s int) []T {
	return append(slice[:s], slice[s+1:]...)
}