/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Contract, ContractFactory, Overrides } from "@ethersproject/contracts";

import type { PacksTokenInfoFacet } from "../PacksTokenInfoFacet";

export class PacksTokenInfoFacet__factory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer);
  }

  deploy(overrides?: Overrides): Promise<PacksTokenInfoFacet> {
    return super.deploy(overrides || {}) as Promise<PacksTokenInfoFacet>;
  }
  getDeployTransaction(overrides?: Overrides): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): PacksTokenInfoFacet {
    return super.attach(address) as PacksTokenInfoFacet;
  }
  connect(signer: Signer): PacksTokenInfoFacet__factory {
    return super.connect(signer) as PacksTokenInfoFacet__factory;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): PacksTokenInfoFacet {
    return new Contract(address, _abi, signerOrProvider) as PacksTokenInfoFacet;
  }
}

const _abi = [
  {
    inputs: [
      {
        internalType: "string",
        name: "_license",
        type: "string",
      },
    ],
    name: "addNewLicense",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "collectibleNumber",
        type: "uint256",
      },
      {
        internalType: "string",
        name: "asset",
        type: "string",
      },
    ],
    name: "addSecondaryVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "collectibleNumber",
        type: "uint256",
      },
      {
        internalType: "string",
        name: "asset",
        type: "string",
      },
    ],
    name: "addVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getLicense",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "versionNumber",
        type: "uint256",
      },
    ],
    name: "getLicenseVersion",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "collectibleId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "propertyIndex",
        type: "uint256",
      },
      {
        internalType: "string",
        name: "value",
        type: "string",
      },
    ],
    name: "updateMetadata",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "collectibleNumber",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "versionNumber",
        type: "uint256",
      },
    ],
    name: "updateSecondaryVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "collectibleNumber",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "versionNumber",
        type: "uint256",
      },
    ],
    name: "updateVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b50610aed806100206000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c8063c99d150b1161005b578063c99d150b146100e6578063d4ca6610146100f9578063efebe3bd1461010c578063ff09a1a41461011f57610088565b806313e5d37a1461008d5780636b9bd574146100a257806380faea7d146100cb578063c5e4dd82146100de575b600080fd5b6100a061009b3660046108d1565b610132565b005b6100b56100b036600461090c565b6101e1565b6040516100c291906109d8565b60405180910390f35b6100a06100d9366004610969565b610297565b6100b561032b565b6100a06100f4366004610969565b6103e4565b6100a0610107366004610924565b610478565b6100a061011a366004610924565b61055d565b6100a061012d36600461098a565b610643565b600061013c610779565b8054909150610100900473ffffffffffffffffffffffffffffffffffffffff16331461019d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019490610a49565b60405180910390fd5b60006101a7610779565b600e8101546000908152600782016020908152604090912085519293506101d292909186019061079d565b50600e01805460010190555050565b606060006101ed610779565b600019848101600090815260078301602090815260409182902080548351600260018316156101000290960190911694909404601f810183900483028501830190935282845293945091929183018282801561028a5780601f1061025f5761010080835404028352916020019161028a565b820191906000526020600020905b81548152906001019060200180831161026d57829003601f168201915b5050505050915050919050565b60006102a1610779565b8054909150610100900473ffffffffffffffffffffffffffffffffffffffff1633146102f9576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019490610a49565b6000610303610779565b6000199485016000908152600490910160205260409020939092016008909301929092555050565b60606000610337610779565b600e810154600019908101600090815260078301602090815260409182902080548351600260018316156101000290960190911694909404601f81018390048302850183019093528284529394509192918301828280156103d95780601f106103ae576101008083540402835291602001916103d9565b820191906000526020600020905b8154815290600101906020018083116103bc57829003601f168201915b505050505091505090565b60006103ee610779565b8054909150610100900473ffffffffffffffffffffffffffffffffffffffff163314610446576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019490610a49565b6000610450610779565b6000199485016000908152600490910160205260409020939092016005909301929092555050565b6000610482610779565b8054909150610100900473ffffffffffffffffffffffffffffffffffffffff1633146104da576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019490610a49565b60006104e4610779565b60001980860160009081526004830160205260409020600781015460069091018054939450869390929190910190811061051a57fe5b90600052602060002001908051906020019061053792919061079d565b506000199093016000908152600490930160205250506040902060070180546001019055565b6000610567610779565b8054909150610100900473ffffffffffffffffffffffffffffffffffffffff1633146105bf576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019490610a49565b60006105c9610779565b6000198086016000908152600480840160205260409091209081015460039091018054939450869390929190910190811061060057fe5b90600052602060002001908051906020019061061d92919061079d565b506000199093016000908152600493840160205260409020909201805460010190555050565b600061064d610779565b8054909150610100900473ffffffffffffffffffffffffffffffffffffffff1633146106a5576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019490610a49565b60006106af610779565b905080600501600060018703815260200190815260200160002060020184815481106106d757fe5b90600052602060002090602091828204019190069054906101000a900460ff1661072d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019490610a80565b82816005016000600188038152602001908152602001600020600101858154811061075457fe5b90600052602060002001908051906020019061077192919061079d565b505050505050565b7f8ae35b0282f76a84f1af63b27d5d1e20fc710ae70d8a101653e7c1b36c5fe8b590565b828054600181600116156101000203166002900490600052602060002090601f0160209004810192826107d35760008555610819565b82601f106107ec57805160ff1916838001178555610819565b82800160010185558215610819579182015b828111156108195782518255916020019190600101906107fe565b50610825929150610829565b5090565b5b80821115610825576000815560010161082a565b600082601f83011261084e578081fd5b813567ffffffffffffffff8082111561086357fe5b60405160207fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0601f850116820101818110838211171561089f57fe5b6040528281528483016020018610156108b6578384fd5b82602086016020830137918201602001929092529392505050565b6000602082840312156108e2578081fd5b813567ffffffffffffffff8111156108f8578182fd5b6109048482850161083e565b949350505050565b60006020828403121561091d578081fd5b5035919050565b60008060408385031215610936578081fd5b82359150602083013567ffffffffffffffff811115610953578182fd5b61095f8582860161083e565b9150509250929050565b6000806040838503121561097b578182fd5b50508035926020909101359150565b60008060006060848603121561099e578081fd5b8335925060208401359150604084013567ffffffffffffffff8111156109c2578182fd5b6109ce8682870161083e565b9150509250925092565b6000602080835283518082850152825b81811015610a04578581018301518582016040015282016109e8565b81811115610a155783604083870101525b50601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe016929092016040019392505050565b6020808252600d908201527f57726f6e67206164647265737300000000000000000000000000000000000000604082015260600190565b6020808252600b908201527f4e6f7420616c6c6f77656400000000000000000000000000000000000000000060408201526060019056fea264697066735822122007437fd8b4db6d1f1626e245b8aa0374a9c95a4f3958f5aa798b6e7ef0140e3464736f6c63430007060033";
