'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

/**
 * Workload module for the benchmark round.
 */
class ReadPubliceGOWorkload extends WorkloadModuleBase {
    /**
     * Initializes the workload module instance.
     */
    constructor() {
        super();
        this.txIndex = 0;
        this.chaincodeID = '';
        this.assets = [];
        this.byteSize = 0;
        this.consensus = false;
    }
    /**
     * Initialize the workload module with the given parameters.
     * @param {number} workerIndex The 0-based index of the worker instantiating the workload module.
     * @param {number} totalWorkers The total number of workers participating in the round.
     * @param {number} roundIndex The 0-based index of the currently executing round.
     * @param {Object} roundArguments The user-provided arguments for the round from the benchmark configuration file.
     * @param {BlockchainInterface} sutAdapter The adapter of the underlying SUT.
     * @param {Object} sutContext The custom context object provided by the SUT adapter.
     * @async
     */
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);

        //this.limitIndex = this.roundArguments.assets;
       // await helper.createCar(this.sutAdapter, this.workerIndex, this.roundArguments);
    }

    /**
     * Assemble TXs for the round.
     * @return {Promise<TxStatus[]>}
     */
    async submitTransaction() {
        this.txIndex++;
        let eGOID = "eGO1"

        this.query = {
            eGOID: eGOID,
        }

        let args = {
            contractId: 'conversion',
            contractVersion: '1',
            contractFunction: 'ReadPubliceGO',
            contractArguments: [],
            transientMap: {QueryInput: JSON.stringify(this.query)} 
        };

        await this.sutAdapter.sendRequests(args);
    }
}

/**
 * Create a new instance of the workload module.
 * @return {WorkloadModuleInterface}
 */
function createWorkloadModule() {
    return new ReadPubliceGOWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;