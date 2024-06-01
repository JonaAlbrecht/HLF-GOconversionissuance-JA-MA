# HLF GO conversion issuance Masters thesis Jona Albrecht

In this repo, you can find the source code for my Masters thesis project on the potential of Blockchain technology for data sharing between Guarantee of Origin schemes during energy carrier conversion issuance. The Masters thesis is still ongoing, wherefore the source code, documentation and project description in this repository are not final.

---

## Project Description:

**Requirements Analysis**

[Energy Carrier Conversion](Project-Description/Literature-Review/Conversion-Issuance-basicinfo.md)

[Requirements Analysis](Project-Description/Literature-Review/Requirements-Analysis.md)

**Platform-agnostic architecture**

[Platform-agnostic architecture](Project-Description/platform-agnostic-architecture/platform-agnostic-architecture.md)

**Prototype-description**

Not finished, but all the source code is available in the version 1 folder.

---

**Step 1**
[Installing Prerequisites and Fabric Binaries](Project-Description/README-files/Step1.md)

**Step 2**
[Bringing up the network](Project-Description/README-files/Step2.md)

**Step 3**
[Executing the transaction flow](Project-Description/README-files/Step3.md)

**Step 4**
[Deploying on Multi-host (not yet finished)](Project-Description/README-files/Step5.md)

**Which problems of GO schemes relating to energy carrier conversion have I identified?**

**Low harmonization between different carrier GO schemes:** alternative energy carrier national schemes & supra-national platforms still immature

**Increased complexity:** as a result of a multitude of different attribute inheritance scenarios. In the absence of full automation this will lead to even longer GO approval cycles

**High transaction costs:** prior to 2022, registry operating costs were as high as 3-7% of GO prices. Operating costs of the conversion issuance IT-solution will further increase transaction cost.

**Double Counting:** conversion issuance poses the threat of double counting renewable attributes between schemes.
Invasion of privacy: Market participants reveal private data to GO registry operators (ceding their data sovereignty). Conversion issuance will require sharing private information across registries, aggravating the privacy problem.

**Low transparency & trust issues:** GO buyers are currently unable to verify the data on their GOs. After conversion issuance, buyers will find conversion-issued GOs even less trustworthy given that complex upstream cross-registry GO processes remain intransparent.

**Low reliability of data sources:** Different standards towards verification/audit of production data between supra-national schemes impacts the reliability of any GO data stemming from conversion issuance

**Temporal & spatial decoupling:** Book-and-claim decoupling disincentivizes space-specific and time-specific consumption of renewable energy. This is aggravated in alternative energy carriers (especially district heating & cooling) because of higher transmission losses. At the same time, real-time trading would go against the central function of AECs as energy storage for load flexibility.

**Single point of failure:** GO registries are a single point of failure vulnerable to an outside security attack & inside corruption by an employee. In the cross-carrier scenario (if a central conversion registry were to be employed) the single point of failure issue might be aggravated.

**How can the Blockchain/ Distributed Ledger Technology (DLT) fulfil the requirements of a cross-carrier interoperable system of GO schemes?**

**Verifiability:**
Signatures & Public Key Infrastructure: decentralized identity management using asymmetric encryption serves as the basis for the verification of data
On-chain hashes: GO private data will be verifiable by a buyer since a hash of the data is stored on-chain (accessible by all scheme participants)  
Hardware Security Modules: using HSMs, metering data can be signed directly by the production/conversion device

**Privacy:**
Off-chain data storage: GO owner can store GO on their local database (retains data sovereignty). Given that a hash of the GO is stored on-chain, the owner couldn’t change the GO data without invalidating it

**Scalability and Automation**
Smart Contracts: DLT can automate complex business logic and authentication processes using digital signatures and smart contracts
Given verifiable input data & storage in the GO owners local database, any issuing body could issue GOs for any carrier, avoiding bottlenecks and increasing system throughput

**Security:**
Since GO owners store their certificates in their local database, there is no single point of failure
