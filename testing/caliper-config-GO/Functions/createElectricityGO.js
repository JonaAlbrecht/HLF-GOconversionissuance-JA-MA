'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

const AmountMWhOptions = [45, 46, 47, 48, 49];

/**
 * Workload module for the benchmark round.
 */
class CreateeGOWorkload extends WorkloadModuleBase {
    /**
     * Initializes the workload module instance.
     */
    constructor() {
        super();
        this.txIndex = 0;
    }

    /**
     * Assemble TXs for the round.
     * @return {Promise<TxStatus[]>}
     */
    async submitTransaction() {
        this.txIndex++;
        let AmountMWhInput = AmountMWhOptions[Math.floor(Math.random() * AmountMWhOptions.length)];
        let EmissionsInput = AmountMWhInput*50
        let ElapsedSecondsInput = 60
        let ElectricityProductionMethodInput = "solar"

        this.asset = {
            AmountMWh: AmountMWhInput,
            Emissions: EmissionsInput,
            ElapsedSeconds: ElapsedSecondsInput,
            ElectricityProductionMethod: ElectricityProductionMethodInput
        }

        let args = {
            contractId: 'conversion',
            contractVersion: '1',
            contractFunction: 'CreateElectricityGO',
            contractArguments: [],
            timeout: 30,
            transientMap: {eGO: JSON.stringify(this.asset)} 
        };

        await this.sutAdapter.sendRequests(args);
    }
}

/**
 * Create a new instance of the workload module.
 * @return {WorkloadModuleInterface}
 */
function createWorkloadModule() {
    return new CreateeGOWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;