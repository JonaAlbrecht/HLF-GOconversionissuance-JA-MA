package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"strconv"
	"sync"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/pkg/statebased"
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

type greenHydrogenGO struct {
	AssetID string `json:"AssetID"`
	CreationDateTime string `json:"CreationDateTime"`
	GOType string `json:"GOType"`
}

type greenHydrogenGOprivatedetails struct {
	AssetID string `json:"AssetID"`
	OwnerID string `json:"OwnerID"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	InputEmissions float64 `json:"InputEmissions"`
	ElectricityProductionMethod string `json:"ElectricityProductionMethod"`
	UsedMWh float64 `json:"UsedMWh"`
}

type greenHydrogenGObacklog struct {
	Backlogkey string `json:"Backlogkey"`
	GOType string `json:"GOType"`
}

type greenHydrogenGObacklogprivatedetails struct {
	Backlogkey string `json:"Backlogkey"`
	OwnerID string `json:"OwnerID"`
	Kilosproduced float64 `json:"Kilosproduced"`
	EmissionsHydrogen float64 `json:"Emissions"`
	HydrogenProductionMethod string `json:"HydrogenProductionMethod"`
	UsedMWh float64 `json:"UsedMWh"`
}

type Count struct {
	mx *sync.Mutex
	count float64
}

func NewCount() *Count {
	return &Count{mx: new(sync.Mutex), count: 0}
}

var eGOcount = NewCount()
var hGOcount = NewCount()

func (s *SmartContract) createElectricityGO(ctx contractapi.TransactionContextInterface) error {
	
	type eGOTransientInput struct {
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

	eGODataAsBytes, ok := transientMap["GO"]
	if !ok {
		return fmt.Errorf("GO must be a key in transient map:%v", ok)
	}

	if len(eGODataAsBytes) == 0 {
		return fmt.Errorf("GO value must be non-empty")
	}

	// eGO asset ID is of the format "eGO1", "eGO2" and so on...
	currentCounteGO := eGOcounter()
	eGOID := "eGO"+strconv.Itoa(int(currentCounteGO))
	
	var eGOInput eGOTransientInput
	err = json.Unmarshal(eGODataAsBytes, &eGOInput)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input of: " + string(eGODataAsBytes) + ". The error is: " + err.Error())
	}
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
	testifexist, err := ctx.GetStub().GetPrivateData("eGOcollection", eGOID)
	if err != nil {
		return fmt.Errorf("Failed to get data: " + err.Error())
	} else if testifexist != nil {
		return fmt.Errorf("This GO Asset ID already exists: " + eGOID)
	}
	
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

	now1 := time.Now()
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

	err = ctx.GetStub().PutState(eGOID, eGOpublicBytes)
	if err != nil {
		return fmt.Errorf("failed to put asset in public data:%v", err.Error())
	}

	// Set the endorsement policy such that an owner org peer is required to endorse future updates.
	// In practice, consider additional endorsers such as a trusted third party to further secure transfers.
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

	// Persist private immutable asset properties to owner's private data collection
	err = ctx.GetStub().PutPrivateData("privateDetails-eGO", eGOID, eGOprivateBytes)
	if err != nil {
		return fmt.Errorf("unable to create asset private data")
	}
	return nil
}


func (s *SmartContract) addHydrogentoBacklog (ctx contractapi.TransactionContextInterface) error {
	
	type hGObacklogTransientInput struct {
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

	hGODataAsBytes, ok := transientMap["GO"]
	if !ok {
		return fmt.Errorf("GO must be a key in transient map:%v", ok)
	}

	if len(hGODataAsBytes) == 0 {
		return fmt.Errorf("GO value must be non-empty")
	}

	var hGOInput hGObacklogTransientInput
	err = json.Unmarshal(hGODataAsBytes, &hGOInput)
	if err != nil {
		return fmt.Errorf("failed to decode JSON input of: " + string(hGODataAsBytes) + ". The error is: " + err.Error())
	}

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
		hGObacklog := greenHydrogenGObacklog{
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
	
		hGObacklogprivate := greenHydrogenGObacklogprivatedetails{
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
		
		var currentbacklog *greenHydrogenGObacklogprivatedetails
		err = json.Unmarshal(backlogJSON, &currentbacklog)
		if err != nil {
			return fmt.Errorf("error unmarshaling the current backlog:%v", err)
		}
		
		hGObacklog := greenHydrogenGObacklog{
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
	
	
		hGObacklogprivate := greenHydrogenGObacklogprivatedetails{
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

	eventpayloadAsBytes := []byte(backlogkey)
	
		error := ctx.GetStub().SetEvent("hGObacklogupdate",eventpayloadAsBytes)
		if (error != nil) {
		 return fmt.Errorf("failed to emit hGOproposal event:%v", error)
		}	
	return nil
}

func (s *SmartContract) transfereGOtohproducer (ctx contractapi.TransactionContextInterface, neededAmount float64) error {

	//ABAC:
	err := ctx.GetClientIdentity().AssertAttributeValue("electricitytrustedUser", "true")
	if err != nil {
		return fmt.Errorf("submitting User not authorized to transfer electricity GOs to hydrogen producer: %v", err)
	}
	
	startKey := "eGO1"
	endKey := "eGO999"

	resultsIterator,err := ctx.GetStub().GetPrivateDataByRange("privateDetails-eGO", startKey, endKey)
	if err != nil {
		return fmt.Errorf("error getting all available eGOs:%v", err)
	}
	defer resultsIterator.Close()

	results := []*ElectricityGOprivatedetails{}
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return fmt.Errorf("error iterating over all available eGOs:%v", err)
		}

		var availableeGO *ElectricityGOprivatedetails
		err = json.Unmarshal(response.Value, &availableeGO)
		if err != nil {
			return fmt.Errorf("failed to unmarshal JSON: %v", err)
		}
		results = append(results, availableeGO)
	}

	var transferredMWh float64
	transferredMWh = 0
	assetCounter :=0
	for transferredMWh < neededAmount {
		currentAsset := results[assetCounter]
		updatedAsset := &ElectricityGOprivatedetails{AssetID: currentAsset.AssetID, OwnerID: "hproducerMSP", AmountMWh: currentAsset.AmountMWh, Emissions: currentAsset.Emissions, ElectricityProductionMethod: currentAsset.ElectricityProductionMethod}	
		if len(updatedAsset.AssetID) == 0 {
			return fmt.Errorf("failed to change eGO owner")
		}
		updatedAssetasBytes, err := json.Marshal(updatedAsset)
		if err != nil {
			return fmt.Errorf("error marshaling the updated eGO:%v", err)
		}
		error := ctx.GetStub().PutPrivateData("privateDetails-hGO", updatedAsset.AssetID, updatedAssetasBytes)
		if error != nil {
			return fmt.Errorf("error putting electricity GO into hydrogen producer private collection:%v", error)
		}
		error1 := ctx.GetStub().DelPrivateData("privateDetails-eGO", currentAsset.AssetID)
		if error1 != nil {
			return fmt.Errorf("error deleting electricity GO from electricity producer private collection:%v", error1)
		}
		transferredMWh = transferredMWh + updatedAsset.AmountMWh
		assetCounter++
	}
	return nil
}

//next function is create hydrogen GOs by reading electricity GOs from own collection, cancelling the correct amount, 
//reading the remaining amount of MWhs and emissions back into the collection
//issuing a cancellation statement for the cancelled MWh
func (s *SmartContract) issuehGO (ctx contractapi.TransactionContextInterface) error {
	//ABAC:
	err := ctx.GetClientIdentity().AssertAttributeValue("hydrogentrustedUser", "true")
	if err != nil {
		return fmt.Errorf("submitting User not authorized to issue hydrogen GOs: %v", err)
	}
	hGOClientID, error := getClientOrgID(ctx)
	if error != nil {
		return fmt.Errorf("error while getting client ID")
	}

	//read backlog:
	backlogtobeissuedJSON, err := ctx.GetStub().GetPrivateData("privateDetails-hGO", "hydrogenbacklog")
	if err != nil {
		return fmt.Errorf("error getting hydrogen backlog private details:%v", err)
	}
	if backlogtobeissuedJSON == nil {
		return fmt.Errorf("no backlog could be found:%v",err)
	}

	var backlogtobeissued *greenHydrogenGObacklogprivatedetails
		err = json.Unmarshal(backlogtobeissuedJSON, &backlogtobeissued)
		if err != nil {
			return fmt.Errorf("error unmarshaling the current backlog to be issued:%v", err)
		}

	//read available eGOs 
	startKeyhproducer := "eGO1"
	endKeyhproducer := "eGO999"

	resultsIteratorhproducer,err := ctx.GetStub().GetPrivateDataByRange("privateDetails-hGO", startKeyhproducer, endKeyhproducer)
	if err != nil {
		return fmt.Errorf("error reading in eGOs available to hydrogen producer:%v", err)
	}
	defer resultsIteratorhproducer.Close()

	resultshproducer := []*ElectricityGOprivatedetails{}
	for resultsIteratorhproducer.HasNext() {
		responsehproducer, err := resultsIteratorhproducer.Next()
		if err != nil {
			return fmt.Errorf("error iterating over all available eGOs:%v", err)
		}

		var availableeGOhproducer *ElectricityGOprivatedetails
		err = json.Unmarshal(responsehproducer.Value, &availableeGOhproducer)
		if err != nil {
			return fmt.Errorf("failed to unmarshal JSON: %v", err)
		}
		resultshproducer = append(resultshproducer, availableeGOhproducer)
	}
	//transcribing of 
	var hydrogenGO greenHydrogenGO
	var hydrogenGOprivate greenHydrogenGOprivatedetails
	var tobedeleted []string
	
	GOitemcounter := 0

	for hydrogenGOprivate.UsedMWh < backlogtobeissued.UsedMWh {
		hydrogenGOprivate.UsedMWh = hydrogenGOprivate.UsedMWh + resultshproducer[GOitemcounter].AmountMWh
		hydrogenGOprivate.InputEmissions = hydrogenGOprivate.InputEmissions + resultshproducer[GOitemcounter].Emissions
		hydrogenGOprivate.ElectricityProductionMethod = hydrogenGOprivate.ElectricityProductionMethod + "," + resultshproducer[GOitemcounter].ElectricityProductionMethod
		//make keylist of eGOs that are to be deleted
		tobedeleted = append(tobedeleted, resultshproducer[GOitemcounter].AssetID)
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
	now2 := time.Now()
	now2string := now2.String()
	hydrogenGO.CreationDateTime = now2string

	//delete eGOs that are to be deleted
	deletioncounter := 0
	for deletioncounter < len(tobedeleted) {
		err := ctx.GetStub().DelPrivateData("privateDetails-hGO", tobedeleted[deletioncounter])
		if err != nil {
			return fmt.Errorf("error deleteting transcribed electricity GOs from hydrogen producer private collection:%v", err)
		}
		deletioncounter++
	}

	currentCounteGO1 := eGOcounter()
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


func getClientOrgID(ctx contractapi.TransactionContextInterface) (string, error) {
	clientOrgID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return "", fmt.Errorf("failed getting client's orgID: %v", err)
	}

	return clientOrgID, nil
}

func getPeerOrgID(ctx contractapi.TransactionContextInterface) (string, error) {
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

func getConversionEfficiency(ctx contractapi.TransactionContextInterface) (string, error) {
	conversionEfficiency, found, err := ctx.GetClientIdentity().GetAttributeValue("conversionEfficiency")
	if err != nil {
		return "", fmt.Errorf("failed getting conversionEfficiency: %v", err)
	}
	if !found {
		return "", fmt.Errorf("certificate doesnt have attribute conversionEfficiency")
	}
	return conversionEfficiency, nil
}

func setGOEndorsementpolicy(ctx contractapi.TransactionContextInterface, assetID string, orgsToEndorse []string) error {
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


func main() {
	chaincode, err := contractapi.NewChaincode(new(SmartContract))
	if err != nil {
		log.Panicf("Error create transfer asset chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting asset chaincode: %v", err)
	}
}

func (c *Count) Incr() {
    c.mx.Lock()
    c.count++
    c.mx.Unlock()
}

func (c *Count) Count() float64 {
    c.mx.Lock()
    count := c.count
    c.mx.Unlock()
    return count
}

func eGOcounter() float64 {
	eGOcount.Incr()
	return eGOcount.count
}

func hGOcounter() float64 {
	hGOcount.Incr()
	return hGOcount.count
}