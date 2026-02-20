\# Introduction

Welcome to Stargate V2 documentation\!

You can find here necessary information and code examples required to build on top of Stargate.

\#\#\# New features

A quick summary of V1 → V2 upgrades goes as follows:

\* \*\*Cost Reduction\*\*: V2 drastically reduces the cost for users and developers compared to V1 through transaction batching (Stargate Bus) and a one-to-one transaction mode (Taxi Mode).  
\* \*\*More Chains\*\*: V2 introduces "Hydra," a novel expansion to offer Bridging as a Service. This feature allows for the seamless flow of assets across chains, including those without native assets, by locking assets in core pools on source chains and minting corresponding assets on destination chains. This mechanism ensures that assets are always redeemable and leverages Protocol Locked Liquidity for internal accounting. The assets used as wrapped assets on destination are built on the OFT Standard.  
\* \*\*Capital Efficiency\*\*: To address V1's limitations regarding dynamics and scalability, V2 introduces an off-chain mechanism called the AI Planning Module to adapt more swiftly to volume changes and user preferences, moving beyond the constraints of on-chain-only operations.

\#\#\# Interfaces

Stargate V2 has been built on top of LayerZero V2, which means there is a lot of different functionality built into the protocol. It also opens up a lot of interesting surfaces to build on. If you want to learn more about LayerZero omnichain messaging, please refer to its \[documentation\](https://docs.layerzero.network).

It also means that \*\*the Stargate interfaces have changed\*\*.

Stargate V2 interfaces are the same as the IOFT interface for OFTs on LayerZero V2. IOFT interface is \[available here\](https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/oapp/contracts/oft/interfaces/IOFT.sol). Documentation for building on IOFT is \[here\](https://docs.layerzero.network/v2/developers/evm/oft/quickstart).

\# Pool

A pool is a regular Stargate liquidity pool where e.g. USDC will be deposited. Liquidity from these pools is later used to enable cross chain swaps of the same asset.

\#\# Deposit

{% code fullWidth="true" %}

\`\`\`solidity  
function deposit(  
    address \_receiver,  
    uint256 \_amountLD  
) external payable nonReentrantAndNotPaused returns (uint256 amountLD)  
\`\`\`

{% endcode %}

\#\# Withdraw

There are two ways you can withdraw your tokens from the liquidity pool. The first is a standard function which returns the pool's underlying token in exchange for the liquidity token on the same chain the method is called:

{% code fullWidth="true" %}

\`\`\`solidity  
function redeem(  
    uint256 \_amountLD,  
    address \_receiver  
) external nonReentrantAndNotPaused returns (uint256 amountLD)  
\`\`\`

{% endcode %}

The second function also allows for redeeming the underlying token, but it also sends it to the destination chain that user wants. This function can only be used in taxi mode. Here's a signature of the function:

{% code fullWidth="true" %}

\`\`\`solidity  
function redeemSend(  
    SendParam calldata \_sendParam,  
    MessagingFee calldata \_fee,  
    address \_refundAddress  
) external payable nonReentrantAndNotPaused  
    returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)  
\`\`\`

{% endcode %}

\#\#\# Credits

Redeeming liquidity tokens for underlying pool tokens, e.g., LP to USDC, may in some cases be limited by the \*\*credits available\*\* on the particular chain you want to redeem on. For the \`redeem()\` function to successfully process, an adequate number of credits must be available on the local blockchain where the redeem transaction is initiated. If you call \`redeemSend()\` enough credits need to be available on the destination chain. You can read more about \[Credits\](https://stargateprotocol.gitbook.io/stargate/v2-developer-docs/integrate-with-stargate/credit-allocation-system).

\#\#\# Composability

Because \`redeemSend()\` is using the LayerZero protocol to send the message to the destination chain \- it is also composable. You can read more about \[Composability\](https://stargateprotocol.gitbook.io/stargate/v2-developer-docs/integrate-with-stargate/composability).

\#\# Code

The code for the ERC20 token pool lives in \`StargatePool.sol\` and is using \`StargatePoolNative.sol\`for the native token.

When you call \`stargateType()\` method from the \`IStargate\` interface on the Pool asset it will return:

{% code fullWidth="true" %}

\`\`\`solidity  
StargateType.Pool  
\`\`\`

{% endcode %}

\# Hydra (OFTs)

\#\# Introduction

Hydra extends Stargate via Bridging as a Service (BaaS). With Hydra, Stargate enables users to transfer Hydra-wrapped versions of USDC, USDT, and ETH to Hydra chains (and between Hydra chains) quickly.&\#x20;

\#\# How Hydra Works

Hydra operates on a foundational principle where Stargate's core pools, residing on chains with native assets (e.g., Ethereum, Arbitrum, Optimism), are leveraged to facilitate asset bridging to newer chains lacking native assets.&\#x20;

The minting of Hydra assets on Chain X uses the \[Omnichain Fungible Tokens (OFT) Standard\](https://docs.layerzero.network/v2/developers/evm/oft/native-transfer). This process is initiated when assets, such as USDC, are bridged from a core chain (e.g., Arbitrum) to a Hydra-enabled chain (referred to as Chain X in this context). The bridged assets are securely locked within Stargate’s pool contracts on the origin chain, while an equivalent asset is minted on Chain X.  A basic outline of the Hydra process goes as follows:

\* When a user bridges USDC from Arbitrum to Chain X, their USDC assets get locked in the secure USDC pool on Arbitrum, and an asset minted on Chain X.&\#x20;  
\* The user's USDC will always sit in an underlying Pool contract until they want to come back to Arbitrum (or any other Stargate core chain)

Since the asset minted on Chain X is an OFT, it can be horizontally composed across all current and future Hydra chains. The user could bridge from Chain X to Y, and always come back through Stargate to Arbitrum (or any other core chain). In other words, underlying assets are always redeemable from any core Stargate chain.

\#\# Code

Hydra code lives in \`StargateOFT.sol\`.&\#x20;

When you call \`stargateType()\` method from the\`IStargate\` interface on a Hydra asset it will return:

{% code fullWidth="true" %}

\`\`\`solidity  
StargateType.OFT  
\`\`\`

{% endcode %}

\# Estimating Fees

Stargate offers five distinct methods to estimate transfer fees. Let's begin by exploring the most commonly utilized ones.

\#\# High level functions

The two highest level functions are:

1\. \`quoteOFT\`  
2\. \`quoteSend\`

They are both part of \[\`IStargate\` interface.\](https://github.com/stargate-protocol/stargate-v2/blob/main/packages/stg-evm-v2/src/interfaces/IStargate.sol)

\#\#\# quoteOFT

This method provides a quote for sending OFT to another chain. It can be used to calculate minimum amount of tokens you will receive on destination chain after you swap.

This function also returns maximum number of tokens possible to bridge to a particular chain. It is very important taking into consideration the \[Credits\](https://stargateprotocol.gitbook.io/stargate/v2-developer-docs/integrate-with-stargate/credit-allocation-system) mechanism in Stargate.

This is how the interface of the function looks like:

{% code fullWidth="true" %}

\`\`\`solidity  
/// @notice Provides a quote for sending OFT to another chain.  
/// @dev Implements the IOFT interface  
/// @param \_sendParam The parameters for the send operation  
/// @return limit The information on OFT transfer limits  
/// @return oftFeeDetails The details of OFT transaction cost or reward  
/// @return receipt The OFT receipt information, indicating how many tokens would be sent and received  
function quoteOFT(  
    SendParam calldata \_sendParam  
) external view returns (  
    OFTLimit memory limit,  
    OFTFeeDetail\[\] memory oftFeeDetails,  
    OFTReceipt memory receipt  
)  
\`\`\`

{% endcode %}

As you can see, the only input parameter is \`SendParam\`:

{% code fullWidth="true" %}

\`\`\`solidity  
/\*\*  
 \* @dev Struct representing token parameters for the OFT send() operation.  
 \*/  
struct SendParam {  
    uint32 dstEid; // Destination endpoint ID.  
    bytes32 to; // Recipient address.  
    uint256 amountLD; // Amount to send in local decimals.  
    uint256 minAmountLD; // Minimum amount to send in local decimals.  
    bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message.  
    bytes composeMsg; // The composed message for the send() operation.  
    bytes oftCmd; // The OFT command to be executed, unused in default OFT implementations.  
}  
\`\`\`

{% endcode %}

It contains all the information required to send the transfer. If you want to learn more about preparing this struct please read \[How to Swap\](https://stargateprotocol.gitbook.io/stargate/v2-developer-docs/integrate-with-stargate/how-to-swap).

Now, let's analyze the output of \`quoteOFT()\`:

\* \`OFTLimit limit\` \- it returns minimum and maximum amounts of tokens in local decimals that can be transferred to the receiver. The maximum amount of tokens received on the destination chain might be limited by the credits mechanism in Stargate.\\  
  \\  
  Example value: \`OFTLimit({ minAmountLD: 1000000000000 \[1e12\], maxAmountLD: 18446744073709551615000000000000 \[1.844e31\] })\`  
\* \`OFTFeeDetail\[\] oftFeeDetails\` \- array of structs containing information about fees or rewards in local decimals with their descriptions. Note that \`feeAmountLD\` is \`int256\` so it can be positive or negative. If you would like to learn more read \[Treasury fees and rewards\](\#treasury-fees-and-rewards).\\  
  \\  
  Example value: \`\[OFTFeeDetail({ feeAmountLD: 1000000000000 \[1e12\], description: "reward" })\]\`  
\* \`OFTReceipt receipt\`:

{% code fullWidth="true" %}

\`\`\`solidity  
struct OFTReceipt {  
    uint256 amountSentLD; // Amount of tokens ACTUALLY debited from the sender in local decimals.  
    // @dev In non-default implementations, the amountReceivedLD COULD differ from this value.  
    uint256 amountReceivedLD; // Amount of tokens to be received on the remote side.  
}  
\`\`\`

{% endcode %}

&\#x20;\\  
Example value: \`OFTReceipt({ amountSentLD: 100000000000000 \[1e14\], amountReceivedLD: 100000000000000 \[1.01e14\] })\`\\  
\\  
\`amountReceivedLD\` from \`quoteOFT()\` can be used to override \`SendParam.minAmountLD\` that is later passed to \`quoteSend()\`. \`minAmountLD\` is minimum amount of tokens to send. If due to applied fees/reward the actual amount sent would drop below this value then the fee library will revert with \`SlippageTooHigh\`.

\#\#\# quoteSend

This method provides a way to calculate total fee for a given \`send()\` operation. It reverts with \`InvalidAmount\` if send mode is drive but value is specified.

This is an interface of the function:

{% code fullWidth="true" %}

\`\`\`solidity  
function quoteSend(  
    SendParam calldata \_sendParam,  
    bool \_payInLzToken  
) external view returns (MessagingFee memory fee)  
\`\`\`

{% endcode %}

It accepts \`SendParam\` and a \`boolean\` whether to pay in LayerZero token. For more information on how to prepare the \`SendParam\` please read \[How to Swap\](https://stargateprotocol.gitbook.io/stargate/v2-developer-docs/integrate-with-stargate/how-to-swap).

\`quoteSend\` returns \`MessagingFee\` struct:

{% code fullWidth="true" %}

\`\`\`solidity  
struct MessagingFee {  
    uint256 nativeFee;  
    uint256 lzTokenFee;  
}  
\`\`\`

{% endcode %}

\#\# Lower level functions

Below you can see some of the lower level functions which might be useful for advanced use cases. In a typical use case, when you call \`quoteSend\` these lower level functions are called automatically and there's no need to call them directly.

\#\#\# quoteTaxi

This function is part of \`ITokenMessaging\` interface:

{% code fullWidth="true" %}

\`\`\`solidity  
function quoteTaxi(  
    TaxiParams calldata \_params,  
    bool \_payInLzToken  
) external view returns (MessagingFee memory fee);  
\`\`\`

{% endcode %}

This function accepts \`TaxiParams\` and a boolean indicating whether to pay in LayerZero token as input parameters. It returns a quote for how much needs to be paid for the transfer.

Let's focus on the \`TaxiParams\` here:

{% code fullWidth="true" %}

\`\`\`solidity  
struct TaxiParams {  
    address sender;  
    uint32 dstEid;  
    bytes32 receiver;  
    uint64 amountSD;  
    bytes composeMsg;  
    bytes extraOptions;  
}  
\`\`\`

{% endcode %}

This is what you need to provide to the above function. You can also programatically convert \`SendParam\` to \`TaxiParams\` by calling:

\<pre class="language-solidity" data-full-width="true"\>\<code class="lang-solidity"\>using MessagingHelper for SendParam;

// ...

function \_ld2sd(uint256 \_amountLD) internal view returns (uint64 amountSD) {  
    unchecked {  
        amountSD \= SafeCast.toUint64(\_amountLD / convertRate);  
    }  
}

// ...

uint64 amountSD \= \_ld2sd(sendParam.amountLD);

\<strong\>sendParam.toTaxiParams(amountSD)  
\</strong\>\</code\>\</pre\>

\#\#\# quoteRideBus

This function is part of the\[\`ITokenMessaging\` interface\](https://github.com/stargate-protocol/stargate-v2/blob/main/packages/stg-evm-v2/src/interfaces/ITokenMessaging.sol):

\<pre class="language-solidity" data-full-width="true"\>\<code class="lang-solidity"\>\<strong\>function quoteRideBus(  
\</strong\>\<strong\>    uint32 \_dstEid, bool \_nativeDrop  
\</strong\>\<strong\>) external view returns (MessagingFee memory fee);  
\</strong\>\</code\>\</pre\>

It returns a total fee for the bus ride transfer and accepts Destination Endpoint Id (\`\_dstEid\`) and a boolean that represents whether to pay for a native drop on the destination.

\#\# Treasury fees and rewards

There are two types of Stargate token instances that can exist on particular chain. Only one instance will exist per asset per chain. A token on specific chain is either using a \[\*\*Pool\*\*\](https://github.com/stargate-protocol/stargate-v2/blob/main/packages/stg-evm-v2/src/interfaces/IStargatePool.sol) or it is a \*\*Hydra\*\* \*\*OFT\*\*.

When sending tokens from \*\*Pool\*\* it can either charge a treasury fee or reward you for the transfer.

If you transfer from \*\*Hydra OFT\*\* there is no reward, but the treasury fee can be charged.

As a reminder you can query treasury fees or rewards using \[\`quoteOFT()\`\](\#quoteoft). Fees within the Stargate protocol are dynamic, and are set by the AI Planning Module on a per pathway basis.

\#\#\# Reward

The reward is capped by the treasury fee pool. The function \`addTreasuryFee()\` can be called by the treasurer, which will emit the following event:

{% code fullWidth="true" %}

\`\`\`solidity  
event TreasuryFeeAdded(uint64 amountSD);  
\`\`\`

{% endcode %}

\# How to Swap

\#\# Overview

Stargate V2 allows for same-asset bridging only, which means that USDC on Ethereum can only be swapped with USDC on some other chain.

When performing a swap you have two main options for balancing speed and gas costs:

1\. Taking a taxi: \*\*Immediately\*\* performs a swap and sends an omnichain message to the destination chain.  
2\. Riding the bus: Allows the user to take advantage of cheaper gas costs thanks to \*\*transaction batching\*\*. When you use this approach your swap will immediately be settled on the local chain with instant guaranteed finality. However, you may need to wait before you receive the target asset on the destination chain. The message will be sent to destination chain when a "bus" reaches a set number of passengers (between 2-10). An impatient user can also choose to \`driveBus\`, by buying up the remaining bus tickets.&\#x20;

Instant guaranteed finality ensures that your swap will be executed, even when taking the bus.

\#\#\# OFT standard

As a reminder Stargate V2 interfaces are built upon the IOFT interface for OFTs on LayerZero V2. IOFT interface is \[available here\](https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/oapp/contracts/oft/interfaces/IOFT.sol). Documentation for building on IOFT is \[here\](https://docs.layerzero.network/v2/developers/evm/oft/composing\#sending-token).

This means that when you execute a swap on Stargate you are actually calling \`OFT.send()\`. Lets take a look at \[\`IStargate\`\](https://github.com/stargate-protocol/stargate-v2/blob/main/packages/stg-evm-v2/src/interfaces/IStargate.sol) interface that extends \`OFT\` standard:

{% code fullWidth="true" %}

\`\`\`solidity  
// SPDX-License-Identifier: BUSL-1.1  
pragma solidity ^0.8.0;

import { IOFT, SendParam, MessagingFee, MessagingReceipt, OFTReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

enum StargateType {  
    Pool,  
    OFT  
}

struct Ticket {  
    uint56 ticketId;  
    bytes passenger;  
}

/// @title Interface for Stargate.  
/// @notice Defines an API for sending tokens to destination chains.  
interface IStargate is IOFT {  
    /// @dev This function is same as \`send\` in OFT interface but returns the ticket data if in the bus ride mode,  
    /// which allows the caller to ride and drive the bus in the same transaction.  
    function sendToken(  
        SendParam calldata \_sendParam,  
        MessagingFee calldata \_fee,  
        address \_refundAddress  
    ) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt, Ticket memory ticket);

    /// @notice Returns the Stargate implementation type.  
    function stargateType() external pure returns (StargateType);  
}  
\`\`\`

{% endcode %}

As you can see above the Stargate interface isn't much different from an OFT. The most important piece of the interface is:

{% code fullWidth="true" %}

\`\`\`solidity  
SendParam calldata \_sendParam  
\`\`\`

{% endcode %}

Let's explain it:

{% code fullWidth="true" %}

\`\`\`solidity  
/\*\*  
 \* @dev Struct representing token parameters for the OFT send() operation.  
 \*/  
struct SendParam {  
    uint32 dstEid; // Destination endpoint ID.  
    bytes32 to; // Recipient address.  
    uint256 amountLD; // Amount to send in local decimals.  
    uint256 minAmountLD; // Minimum amount to send in local decimals.  
    bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message.  
    bytes composeMsg; // The composed message for the send() operation.  
    bytes oftCmd; // The OFT command to be executed, unused in default OFT implementations.  
}  
\`\`\`

{% endcode %}

The biggest Stargate specific difference is the use of last three properties of the struct above.

\#\#\# SendParam.extraOptions

\`extraOptions\`&\#x20;

\*\*If you use taxi mode\*\* then these options are LayerZero's \[execution options\](https://docs.layerzero.network/v2/developers/evm/gas-settings/options). You can use \[\`OptionsBuilder\`\](https://docs.layerzero.network/v2/developers/evm/gas-settings/options) to prepare them. The exception to the above is that you don't need to put \`addExecutorLzReceiveOption()\` in them, because it is handled automatically by Stargate.

\* The practical example of using \`extraOptions\` can be found in \[Composability\](https://stargateprotocol.gitbook.io/stargate/v2-developer-docs/integrate-with-stargate/composability) section where \[\`addExecutorLzComposeOption()\`\](https://docs.layerzero.network/v2/developers/evm/gas-settings/options\#lzcompose-option) is used to enable composing functionality  
\* Another interesting option is \[\`addExecutorNativeDropOption()\`\](https://docs.layerzero.network/v2/developers/evm/gas-settings/options\#lznativedrop-option) which can be used to drop native tokens to the address you specify.

\*\*If you use bus mode\*\* these are \`options\` from \`RideBusParams\`:

{% code fullWidth="true" %}

\`\`\`solidity  
struct RideBusParams {  
    address sender;  
    uint32 dstEid;  
    bytes32 receiver;  
    uint64 amountSD;  
    bool nativeDrop;  
}  
\`\`\`

{% endcode %}

\#\#\# SendParam.composeMsg

Check the \[Composability\](https://stargateprotocol.gitbook.io/stargate/v2-developer-docs/integrate-with-stargate/composability) page to learn more about it. If you don't plan to use any destination logic, feel free to just use: \`new bytes(0)\`.

\#\#\# SendParam.oftCmd

The OFT command to be executed, unused in default OFT implementation, but in Stargate it is used to indicate the transportation mode.

{% code fullWidth="true" %}

\`\`\`solidity  
pragma solidity ^0.8.22;

library OftCmdHelper {  
    function taxi() internal pure returns (bytes memory) {  
        return "";  
    }

    function bus() internal pure returns (bytes memory) {  
        return new bytes(1);  
    }

    function drive(bytes memory \_passengers) internal pure returns (bytes memory) {  
        return \_passengers;  
    }  
}  
\`\`\`

{% endcode %}

Empty bytes are "taxi", \`bytes(1)\` is riding a bus. If you pass a bytes array of \`\_passengers\` it indicates you want to drive a bus.

\#\# Take a taxi

Let's start with the first high-level example.

Users can opt to pay for their transactions to be bridged immediately by taking a taxi. Take a look at \`prepareTakeTaxi()\` in the code example below:

{% code fullWidth="true" %}

\`\`\`solidity  
pragma solidity ^0.8.19;

import { IStargate } from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";  
import { MessagingFee, OFTReceipt, SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

contract StargateIntegration {  
    function prepareTakeTaxi(  
        address \_stargate,  
        uint32 \_dstEid,  
        uint256 \_amount,  
        address \_receiver  
    ) external view returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) {  
        sendParam \= SendParam({  
            dstEid: \_dstEid,  
            to: addressToBytes32(\_receiver),  
            amountLD: \_amount,  
            minAmountLD: \_amount,  
            extraOptions: new bytes(0),  
            composeMsg: new bytes(0),  
            oftCmd: ""  
        });

        IStargate stargate \= IStargate(\_stargate);

        (, , OFTReceipt memory receipt) \= stargate.quoteOFT(sendParam);  
        sendParam.minAmountLD \= receipt.amountReceivedLD;

        messagingFee \= stargate.quoteSend(sendParam, false);  
        valueToSend \= messagingFee.nativeFee;

        if (stargate.token() \== address(0x0)) {  
            valueToSend \+= sendParam.amountLD;  
        }  
    }

    function addressToBytes32(address \_addr) internal pure returns (bytes32) {  
        return bytes32(uint256(uint160(\_addr)));  
    }  
}  
\`\`\`

{% endcode %}

...and the following code initiates an omnichain transaction using the example Alice account:

{% code fullWidth="true" %}

\`\`\`solidity  
StargateIntegration integration \= new StargateIntegration();

// as Alice  
ERC20(sourceChainPoolToken).approve(stargate, amount);

(uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) \=  
    integration.prepareTakeTaxi(stargate, destinationEndpointId, amount, alice);

IStargate(stargate).sendToken{ value: valueToSend }(sendParam, messagingFee, ALICE);  
\`\`\`

{% endcode %}

The above code executes a swap and requests an immediate taxi ride of the assets to the destination chain.

\#\# Ride the bus

Here is an example of how to perform an omnichain swap using Solidity and bus mode:

{% code fullWidth="true" %}

\`\`\`solidity  
pragma solidity ^0.8.19;

import { IStargate } from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";  
import { MessagingFee, OFTReceipt, SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

contract StargateIntegration {  
    function prepareRideBus(  
        address \_stargate,  
        uint32 \_dstEid,  
        uint256 \_amount,  
        address \_receiver  
    ) external view returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) {  
        sendParam \= SendParam({  
            dstEid: \_dstEid,  
            to: addressToBytes32(\_receiver),  
            amountLD: \_amount,  
            minAmountLD: \_amount,  
            extraOptions: new bytes(0),  
            composeMsg: new bytes(0),  
            oftCmd: new bytes(1)  
        });

        IStargate stargate \= IStargate(\_stargate);

        (, , OFTReceipt memory receipt) \= stargate.quoteOFT(sendParam);  
        sendParam.minAmountLD \= receipt.amountReceivedLD;

        messagingFee \= stargate.quoteSend(sendParam, false);  
        valueToSend \= messagingFee.nativeFee;

        if (stargate.token() \== address(0x0)) {  
            valueToSend \+= sendParam.amountLD;  
        }  
    }

    function addressToBytes32(address \_addr) internal pure returns (bytes32) {  
        return bytes32(uint256(uint160(\_addr)));  
    }  
}  
\`\`\`

{% endcode %}

The function \`prepareRideBus\` contains logic to interact with Stargate and prepare arguments for token swap. You can send the swap transaction using code below:

\<pre class="language-solidity" data-full-width="true"\>\<code class="lang-solidity"\>\<strong\>StargateIntegration integration \= new StargateIntegration();  
\</strong\>  
// as Alice  
ERC20(sourceChainPoolToken).approve(stargate, amount);

(uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) \=  
    integration.prepareRideBus(stargate, destinationEndpointId, amount, alice);

IStargate(stargate).sendToken{ value: valueToSend }(sendParam, messagingFee, ALICE);  
\</code\>\</pre\>

The bus ride isn't instant. The swap is locally settled instantly, but you need to wait to receive tokens on the destination chain because bus transactions are batched together.

\#\#\#\# Bus Ticket

When you board a bus, you will receive a \`Ticket\` for your journey to the destination chain. This ticket can be acquired by capturing parameters from the \`sendToken()\` function.

{% code fullWidth="true" %}

\`\`\`solidity  
(, , Ticket memory ticket) \= stargate.sendToken{ value: valueToSend }(sendParam, messagingFee, ALICE);  
\`\`\`

{% endcode %}

\`Ticket\` is a struct:

{% code fullWidth="true" %}

\`\`\`solidity  
struct Ticket {  
    uint56 ticketId;  
    bytes passenger;  
}  
\`\`\`

{% endcode %}

\#\#\#\# Checking if the Bus has already left

If you want to check whether your bus has already left, compare your \`Ticket.ticketId\` with \`busQueues\[dstEid\].nextTicketId\`. If the \`nextTicketId\` is greater than your \`ticketId\` it means that your tokens were sent to the destination chain.

\# Modes of Transport: Taxi and Bus

There are two modes of transport for sending Stargate transactions. The first is \*\*taxi\*\*, where tokens are sent to the destination chain at the moment of swap. The second is \*\*bus ride\*\*. Bus ride means that multiple user swaps are batched together. Tokens are sent to the destination chain when the \*\*bus is driven.\*\*&\#x20;

Driving the Bus: This will either happen automatically via the planner when the bus is full, or during the regularly scheduled bus service, commissioned by the Stargate Foundation, while parameters are perfected.&\#x20;

\# Composability

{% hint style="info" %}  
Note: Only Stargate's taxi() method is composable, you cannot perform destination logic with rideBus().  
{% endhint %}

\#\# Composable methods

The following methods are composable:

1\. \`IStargate.sendToken()\`  
2\. \`IStargate.send()\`  
3\. \`IStargatePool.redeemSend()\`

\#\# Architecture

\#\#\# Send

To take advantage of compose feature you need to modify \`SendParam\` struct passed to \`IStargate.sendToken()\`.

First, you need to change:

{% code fullWidth="true" %}

\`\`\`solidity  
bytes calldata composeMsg  
\`\`\`

{% endcode %}

Make sure it is non-zero bytes. You would usually use this field with ABI encode and decode to pass your application-specific input that contracts along the way understand.

You also need to pass additional gas for the compose call. You need to set this value to the amount of gas your \`lzCompose\` function in the compose receiver consumes.

For "taxi" you can use typical LayerZero's OptionsBuilder. Make sure to pass it as \`SendParam.extraOptions\`:

\<pre class="language-solidity" data-full-width="true"\>\<code class="lang-solidity"\>bytes memory extraOptions \= \_composeMsg.length \> 0  
\<strong\>    ? OptionsBuilder.newOptions().addExecutorLzComposeOption(0, 200\_000, 0\) // compose gas limit  
\</strong\>    : bytes("");  
\</code\>\</pre\>

\#\#\# Receive

Stargate will attempt to call LayerZero's \`Endpoint.sendCompose()\` on the destination chain when it distributes tokens to receiver.

Here's how the Stargate internal call looks like:

{% code fullWidth="true" %}

\`\`\`solidity  
endpoint.sendCompose(\_payload.receiver, \_guid, \_payload.composeIdx, composeMsg);  
\`\`\`

{% endcode %}

where \`composeMsg\` is:

{% code fullWidth="true" %}

\`\`\`solidity  
composeMsg \= OFTComposeMsgCodec.encode(\_origin.nonce, \_origin.srcEid, amountLD, \_payload.composeMsg);  
\`\`\`

{% endcode %}

and \`receiver\` is an address that was supposed to receive tokens on the destination chain.

Stargate is using standard \[OFTComposeMsgCodec\](https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/oapp/contracts/oft/libs/OFTComposeMsgCodec.sol) for encoding a composed message. This means that when you receive this message in the composer it will be encoded using the aforementioned codec.

To access your custom application specific message (the one you passed as \`SendParams.composeMsg\`) you have to call:

{% code fullWidth="true" %}

\`\`\`solidity  
bytes memory \_composeMessage \= OFTComposeMsgCodec.composeMsg(\_message);  
\`\`\`

{% endcode %}

\#\#\# \*\*Implementing "composer receiver"\*\*

To receive a composed message from Stargate and perform additional logic the receiver address has to be a smart contract implementing \[ILayerZeroComposer\](https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/protocol/contracts/interfaces/ILayerZeroComposer.sol). LayerZero's Endpoint defaults to calling the \`lzCompose()\` function on the receiver contract address. &\#x20;

Here's how an example receiver can look like:

{% code fullWidth="true" %}

\`\`\`solidity  
pragma solidity ^0.8.19;

import { ILayerZeroComposer } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";

contract ComposerReceiver is ILayerZeroComposer {  
    event ComposeAcknowledged(address indexed \_from, bytes32 indexed \_guid, bytes \_message, address \_executor, bytes \_extraData);

    uint256 public acknowledgedCount;

    function lzCompose(  
        address \_from,  
        bytes32 \_guid,  
        bytes calldata \_message,  
        address \_executor,  
        bytes calldata \_extraData  
    ) external payable {  
        acknowledgedCount++;

        emit ComposeAcknowledged(\_from, \_guid, \_message, \_executor, \_extraData);  
    }

    fallback() external payable {}  
    receive() external payable {}  
}  
\`\`\`

{% endcode %}

This very simple example above will emit \`ComposeAcknowledged\` each time a composed call is received and increment the \`acknowledgedCount\` by 1\. A more advanced contract example is detailed below.

\#\# External contract interaction example

Below you can find a Solidity example of doing a swap through external smart contract with a composed message, using the \`taxi\` method.&\#x20;

This example illustrates the process of swapping Token A on the source chain for Token B on the destination chain. Following this, it demonstrates how to swap Token B for Token C on the destination chain by leveraging an external smart contract through a composed call.

\#\#\# Send

Preparing arguments:

{% code fullWidth="true" %}

\`\`\`solidity  
pragma solidity ^0.8.19;

import { IStargate, Ticket } from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";  
import { MessagingFee, OFTReceipt, SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";  
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

contract StargateIntegrationWithCompose {  
    using OptionsBuilder for bytes;  
      
    function prepareTakeTaxiAndAMMSwap(  
        address \_stargate,  
        uint32 \_dstEid,  
        uint256 \_amount,  
        address \_composer,  
        bytes memory \_composeMsg  
    ) external view returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) {  
        bytes memory extraOptions \= \_composeMsg.length \> 0  
            ? OptionsBuilder.newOptions().addExecutorLzComposeOption(0, 200\_000, 0\) // compose gas limit  
            : bytes("");

        sendParam \= SendParam({  
            dstEid: \_dstEid,  
            to: addressToBytes32(\_composer),  
            amountLD: \_amount,  
            minAmountLD: \_amount,  
            extraOptions: extraOptions,  
            composeMsg: \_composeMsg,  
            oftCmd: ""  
        });

        IStargate stargate \= IStargate(\_stargate);

        (, , OFTReceipt memory receipt) \= stargate.quoteOFT(sendParam);  
        sendParam.minAmountLD \= receipt.amountReceivedLD;

        messagingFee \= stargate.quoteSend(sendParam, false);  
        valueToSend \= messagingFee.nativeFee;

        if (stargate.token() \== address(0x0)) {  
            valueToSend \+= sendParam.amountLD;  
        }  
    }

    function addressToBytes32(address \_addr) internal pure returns (bytes32) {  
        return bytes32(uint256(uint160(\_addr)));  
    }  
}  
\`\`\`

{% endcode %}

Sending transaction:

{% code fullWidth="true" %}

\`\`\`solidity  
bytes memory \_composeMsg \= abi.encode(\_tokenReceiver, \_oftOnDestination, \_tokenOut, \_amountOutMinDest, \_deadline);

(uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) \=  
        integration.prepareTakeTaxiAndAMMSwap(stargate, destinationEndpointId, amount, address(composer), \_composeMsg);  
          
IStargate stargate \= IStargate(stargate);

IStargate(stargate).sendToken{ value: valueToSend }(sendParam, messagingFee, refundAddress);  
\`\`\`

{% endcode %}

\#\#\# Receive

On the receive side we will use dummy \`IMockAMM\` interface to demonstrate how the external call to the swap function can look like:

\<pre class="language-solidity" data-full-width="true"\>\<code class="lang-solidity"\>pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";  
import { ILayerZeroComposer } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";  
import { OFTComposeMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";  
\<strong\>  
\</strong\>\<strong\>import { IMockAMM } from './interfaces/IMockAMM.sol';  
\</strong\>  
contract ComposerReceiverAMM is ILayerZeroComposer {  
    IMockAMM public immutable amm;  
    address public immutable endpoint;  
    address public immutable stargate;

    event ReceivedOnDestination(address token);

    constructor(address \_amm, address \_endpoint, address \_stargate) {  
        amm \= IMockAMM(\_amm);  
        endpoint \= \_endpoint;  
        stargate \= \_stargate;  
    }

    function lzCompose(  
        address \_from,  
        bytes32 \_guid,  
        bytes calldata \_message,  
        address \_executor,  
        bytes calldata \_extraData  
    ) external payable {  
        require(\_from \== stargate, "\!stargate");  
        require(msg.sender \== endpoint, "\!endpoint");

        uint256 amountLD \= OFTComposeMsgCodec.amountLD(\_message);  
        bytes memory \_composeMessage \= OFTComposeMsgCodec.composeMsg(\_message);

        (address \_tokenReceiver, address \_oftOnDestination, address \_tokenOut, uint \_amountOutMinDest, uint \_deadline) \=  
            abi.decode(\_composeMessage, (address, address, address, uint, uint));

        address\[\] memory path \= new address\[\](2);  
        path\[0\] \= \_oftOnDestination;  
        path\[1\] \= \_tokenOut;

        IERC20(\_oftOnDestination).approve(address(amm), amountLD);

        try amm.swapExactTokensForTokens(  
            amountLD,  
            \_amountOutMinDest,  
            path,    
            \_tokenReceiver,   
            \_deadline   
        ) {  
            emit ReceivedOnDestination(\_tokenOut);  
        } catch {  
            IERC20(\_oftOnDestination).transfer(\_tokenReceiver, amountLD);  
            emit ReceivedOnDestination(\_oftOnDestination);  
        }  
    }

    fallback() external payable {}  
    receive() external payable {}  
}  
\</code\>\</pre\>

As shown above, \`lzCompose()\` will attempt to swap token B received from Stargate into token C and transfer it to the receiver address. If the swap fails in the try/catch clause it will send the original token B to the receiver address instead.

\# Credit Allocation System

\#\# Introduction

Credits are a way of tracking inflows and outflows of tokens in the protocol.&\#x20;

\#\# Instant Guaranteed Finality

Thanks to the credit allocation mechanism, Stargate maintains a crucial property of cross-chain systems, which is Instant Guaranteed Finality.

Instant Guaranteed Finality means that Stargate swaps are settled locally immediately, without the risk of revert, rollback or double spending on the source chain. You still need to wait for the tokens to be delivered on the destination chain by the underlying messaging protocol, but Stargate ensures the success of the destination transaction.

It is possible because Stargate was designed to hold following invariant true:

1\. For each pool:\\  
   pool balance \>=\\  
   local unallocated credits \+ sum of allocated credits in remote paths  
2\. Sum of pool balances \>= sum of OFT supplies \+ sum of total values locked

\#\# AI Planning Module

Credits in Stargate V2 are handled by the AI Planning Module (Planner in codebase), which conducts automated credit rebalancing within the protocol. It’s role is simply to ensure credits are allocated and reallocated to pathways that see the most volume. Stargate V1 had static credits on pathways. Stargate V2 has dynamic credits and therefore much greater capital efficiency.

Code related to rebalancing credits can be found in \`CreditMessaging\` contract.

\#\# Pathway credit operations

In rare cases you may run into some issues with the credits mechanism. For example when there's not enough credits \`PathLib\` might revert with \`Path\_InsufficientCredit\`. In this section you can find high-level overview of credit operations in Stargate to assist you in debugging.

\#\#\# StargateBase contract

In the \`PathLib\` library there are methods to increase and decrease credits for paths to different endpoints. These functions are called both by Pool and Hydra tokens. In \`StargateBase\` contract there's a function \`\_inflowAndCharge()\` triggered when value is transferred from an account into Stargate to execute a swap as part of \`sendToken()\` call.\\  
\\  
The system reduces the credits for the destination pathway where the user is transferring tokens:

{% code fullWidth="true" %}

\`\`\`solidity  
paths\[\_sendParam.dstEid\].decreaseCredit(amountOutSD); // remove the credit from the path  
\`\`\`

{% endcode %}

There are also two methods that can be indirectly called by the Planner: \`sendCredits()\` and \`receiveCredits()\` to increase or decrease credit balances for different paths.

\#\#\# StargatePool contract

The \`StargatePool\` contract also performs operations on credits as part of its lifecycle.

It increases/decreases local credits based on fee or rewards in \`redeemSend()\` when redeeming tokens on destination endpoint:

{% code fullWidth="true" %}

\`\`\`solidity  
if (amountInSD \> amountOutSD) {  
    // fee  
    uint64 fee \= amountInSD \- amountOutSD;  
    paths\[localEid\].decreaseCredit(fee);  
    poolBalanceSD \-= fee;  
} else if (amountInSD \< amountOutSD) {  
    // reward  
    uint64 reward \= amountOutSD \- amountInSD;  
    paths\[localEid\].increaseCredit(reward);  
    poolBalanceSD \+= reward;  
}  
\`\`\`

{% endcode %}

When \`redeem()\` is called instead and tokens are redeemed locally it subtracts redeemed amount from local credits:

{% code fullWidth="true" %}

\`\`\`solidity  
amountSD \= paths\[localEid\].tryDecreaseCredit(amountSD);  
\`\`\`

{% endcode %}

\# Mainnet Contracts

\#\#\# Ethereum

\`endpointID:\` \`30101\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x3E368B6C95c6fEfB7A16dCc0D756389F3c658a06\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x52B35406CB2FB5e0038EdEcFc129A152a1f74087\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0xe171AFcd1E0394b3312e68ca823D5BC87F3Db311\</td\>\</tr\>\<tr\>\<td\>FeeLibV1mETH.sol\</td\>\<td\>0x6D5521F46b2cba9443feFC09cBaC3B15AE0F73eB\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x5871A7f88b0f3F5143Bf599Fd45F8C0Dc237E881\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0x77b2043768d28E9C9aB44E1aBfC95944bcE57931\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0xc026395860Db2d07ee33e05fE50ed7bD583189C7\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x933597a323Eb81cAe705C5bC29985172fd5A3973\</td\>\</tr\>\<tr\>\<td\>StargatePoolmETH.sol\</td\>\<td\>0x268Ca24DAefF1FaC2ed883c598200CcbB79E931D\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xFF551fEDdbeDC0AeE764139cCD9Cb644Bb04A6BD\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x6d6620eFa72948C5f68A3C8646d58C00d3f4A980\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x1041D127b2d4BC700F0F563883bC689502606918\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# BNB Chain

\`endpointID:\` \`30102\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x622244fFF1328586D0754D67cc6Ab77e7ab38B7D\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0xDd002227d9bC27f10066ED9A17bE89c43bCafC31\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x68D7877b16002AD34836ba55416bcA9B92B55589\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x962Bd449E630b0d928f308Ce63f1A21F02576057\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x138EB30f73BC423c6455C53df6D89CB01d9eBc63\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x26727C78B0209d9E787b2f9ac8f0238B122a3098\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x6E3d884C96d640526F273C61dfcF08915eBd7e2B\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x0a6A15964fEe494A881338D65940430797F0d97C\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Avalanche

\`endpointID:\` \`30106\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0xDFc47DCeF7e8f9Ab19a1b8Af3eeCF000C7ea0B80\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x22BdF9633F3e679785638Db690b85dC0Dc8B35B8\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x6CE9bf8CDaB780416AD1fd87b318A077D2f50EaC\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x5634c4a5FEd09819E3c46D86A965Dd9447d86e47\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x12dC9256Acc9895B076f6638D628382881e62CeE\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x8db623d439C8c4DFA1Ca94E4CD3eB8B3Aaff8331\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x17E450Be3Ba9557F2378E20d64AD417E59Ef9A34\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xC2b638Cb5042c1B3c5d5C969361fB50569840583\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Polygon

\`endpointID:\` \`30109\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x3Fc69CC4A842838bCDC9499178740226062b14E4\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x4e422B0aCb2Bd7e3aC70B5c0E5eb806e86a94038\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0xd240a859Efc77b7455AD1B1402357784a2D72a1B\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x9Aa02D4Fae7F58b8E8f34c66E756cC734DAc7fe4\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0xd47b03ee6d86Cf251ee7860FB2ACf9f91B9fD4d7\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x4694900bDbA99Edf07A2E46C4093f88F9106a90D\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x6CE9bf8CDaB780416AD1fd87b318A077D2f50EaC\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x36ed193dc7160D3858EC250e69D12B03Ca087D08\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Arbitrum

\`endpointID:\` \`30110\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0xda82A31dF339BfDF0123661134b4DB63Cb1706f5\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x80F755e3091b2Ad99c08Da8D13E9C7635C1b8161\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x1F605162282570dFa6255D27895587f4117F52FA\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x957b12606690C7692eF92bb5c34a0E63baED99C7\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0xA45B5130f36CDcA45667738e2a258AB09f4A5f7F\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0xe8CDF27AcD73a434D661C84887215F7598e7d0d3\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0xcE8CcA271Ebc0533920C83d39F417ED6A0abB7D0\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x3da4f8E456AC648c489c286B99Ca37B666be7C4C\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x19cFCE47eD54a88614648DC3f19A5980097007dD\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x146c8e409C113ED87C6183f4d25c50251DFfbb3a\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# OP Mainnet

\`endpointID:\` \`30111\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x80F755e3091b2Ad99c08Da8D13E9C7635C1b8161\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x1F605162282570dFa6255D27895587f4117F52FA\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x3da4f8E456AC648c489c286B99Ca37B666be7C4C\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x146c8e409C113ED87C6183f4d25c50251DFfbb3a\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0xe8CDF27AcD73a434D661C84887215F7598e7d0d3\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0xcE8CcA271Ebc0533920C83d39F417ED6A0abB7D0\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x19cFCE47eD54a88614648DC3f19A5980097007dD\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xFBb5A71025BEf1A8166C9BCb904a120AA17d6443\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0xF1fCb4CBd57B67d683972A59B6a7b1e2E8Bf27E6\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x644abb1e17291b4403966119d15Ab081e4a487e9\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Metis

\`endpointID:\` \`30151\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1METIS.sol\</td\>\<td\>0xcE8CcA271Ebc0533920C83d39F417ED6A0abB7D0\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0xe8CDF27AcD73a434D661C84887215F7598e7d0d3\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x19cFCE47eD54a88614648DC3f19A5980097007dD\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x1F605162282570dFa6255D27895587f4117F52FA\</td\>\</tr\>\<tr\>\<td\>StargatePoolETH.sol\</td\>\<td\>0x36ed193dc7160D3858EC250e69D12B03Ca087D08\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x4dCBFC0249e8d5032F89D6461218a9D2eFff5125\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xF1fCb4CBd57B67d683972A59B6a7b1e2E8Bf27E6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0xcbE78230CcA58b9EF4c3c5D1bC0D7E4b3206588a\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x3da4f8E456AC648c489c286B99Ca37B666be7C4C\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Linea

\`endpointID:\` \`30183\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x6E3d884C96d640526F273C61dfcF08915eBd7e2B\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0xE89Ca5C58E2978c031f7796Ca8580bC88Ea0B3dD\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0x81F6138153d473E8c5EcebD3DC8Cd4903506B075\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x25BBf59ef9246Dc65bFac8385D55C5e524A7B9eA\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x5f688F563Dc16590e570f97b542FA87931AF2feD\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xf5F74d2508e97A3a7CCA2ccb75c8325D66b46152\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Mantle

\`endpointID:\` \`30181\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x2BC3141AaeA1d84bcd557EeB543253fd9685c0C4\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x288968ffF40543F168eAf29A54D5C0affD3C8df7\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0xa81274AFac523D639DbcA2C32c1470f1600cCEBe\</td\>\</tr\>\<tr\>\<td\>FeeLibV1mETH.sol\</td\>\<td\>0x6eC3EfD27d8b1070Fe96910EF416D54e845045c9\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x0184857631ddb3e9E230Bca303F0Ab1e516FC0c8\</td\>\</tr\>\<tr\>\<td\>StargatePoolETH.sol\</td\>\<td\>0x4c1d3Fc3fC3c177c3b633427c2F769276c547463\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0xAc290Ad4e0c891FDc295ca4F0a6214cf6dC6acDC\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0xB715B85682B731dB9D5063187C450095c91C57FC\</td\>\</tr\>\<tr\>\<td\>StargatePoolmETH.sol\</td\>\<td\>0xF7628d84a2BbD9bb9c8E686AC95BB5d55169F3F1\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x02DC1042E623A8677B002981164ccc05d25d486a\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x41B491285A4f888F9f636cEc8a363AB9770a0AEF\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x4e8c9BaC25CEF251352aCe831270D564615b9Ce1\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Base

\`endpointID:\` \`30184\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x17E450Be3Ba9557F2378E20d64AD417E59Ef9A34\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x08ed1d79D509A6f1020685535028ae60C144441E\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x9Aa02D4Fae7F58b8E8f34c66E756cC734DAc7fe4\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0xdc181Bd607330aeeBEF6ea62e03e5e1Fb4B6F7C7\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x27a16dc786820B16E5c9028b75B99F6f604b5d26\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xDFc47DCeF7e8f9Ab19a1b8Af3eeCF000C7ea0B80\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x5634c4a5FEd09819E3c46D86A965Dd9447d86e47\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xd47b03ee6d86Cf251ee7860FB2ACf9f91B9fD4d7\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Kava

\`endpointID:\` \`30177\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0xA76CD3a43751090c40a35C37B38aA06973Cc6184\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x62207a4d054376052Bfcede2c00d113E97D4D247\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x41A5b0470D96656Fb3e8f68A218b39AdBca3420b\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x10e28bA4D7fc9cf39F34E20bbC5C58694b2f1A92\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x6B73D3cBbb278Ce2E8698E983AecCdD94Dc4594B\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xb7A05A3a687ef09cc70E3F98b5f6a62f32E3AE58\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Scroll

\`endpointID:\` \`30214\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x2A6c43e0DBDCde23d40c82F45682BC6D8A6dB219\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x503C5cFEa3477E0A576C8Cf5354023854b7A06Ff\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x4dCBFC0249e8d5032F89D6461218a9D2eFff5125\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0xC2b638Cb5042c1B3c5d5C969361fB50569840583\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x3Fc69CC4A842838bCDC9499178740226062b14E4\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xd240a859Efc77b7455AD1B1402357784a2D72a1B\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x4e422B0aCb2Bd7e3aC70B5c0E5eb806e86a94038\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xcbE78230CcA58b9EF4c3c5D1bC0D7E4b3206588a\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Aurora

\`endpointID:\` \`30211\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x6E3d884C96d640526F273C61dfcF08915eBd7e2B\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0xE89Ca5C58E2978c031f7796Ca8580bC88Ea0B3dD\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x81F6138153d473E8c5EcebD3DC8Cd4903506B075\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x25BBf59ef9246Dc65bFac8385D55C5e524A7B9eA\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x5f688F563Dc16590e570f97b542FA87931AF2feD\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xf5F74d2508e97A3a7CCA2ccb75c8325D66b46152\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Core

\`endpointID: 30153\`

\<table\>\<thead\>\<tr\>\<th width="266"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x693604E757AC7e2c4A8263594A18d69c35562341\</td\>\</tr\>\<tr\>\<td\>RewardLib.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>RewardRegistryLib.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateStaking.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Sonic

\`endpointID: 30332\`&\#x20;

\<table\>\<thead\>\<tr\>\<th width="266"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x3a1293Bdb83bBbDd5Ebf4fAc96605aD2021BbC0f\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x88853D410299BCBfE5fCC9Eef93c03115E908279\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x2d93FbcE4CffC15DD385A80B3f4CC1D4E76C38b3\</td\>\</tr\>\<tr\>\<td\>RewardLib.json\</td\>\<td\>0x549943e04f40284185054145c6E4e9568C1D3241\</td\>\</tr\>\<tr\>\<td\>RewardRegistryLib.json\</td\>\<td\>0xB0B2391a32E066FDf354ef7f4199300f920789F0\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.json\</td\>\<td\>0x164A2dE1bc5dc56F329909F7c97Bae929CaE557B\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.json\</td\>\<td\>0xA272fFe20cFfe769CdFc4b63088DCD2C82a2D8F9\</td\>\</tr\>\<tr\>\<td\>StargateStaking.json\</td\>\<td\>0xbbA60da06c2c5424f03f7434542280FCAd453d10\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x2086f755A6d9254045C257ea3d382ef854849B0f\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0xa7F3e26df31Abcb20a6Fe6bE35DdC60702a32455\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Unichain

\`endpointID: 30320\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xAf368c91793CB22739386DFCbBb2F1A9e4bCBeBf\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0xE1AD845D93853fff44990aE0DcecD8575293681e\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xd9492653457A69E9f4987DB43D7fa0112E620Cb4\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.json\</td\>\<td\>0xe9aBA835f813ca05E50A6C0ce65D0D74390F7dE7\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xB1EeAD6959cb5bB9B20417d6689922523B2B86C3\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x6D205337F45D6850c3c3006e28d5b52c8a432c35\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Gnosis

\`endpointID: 30145\`

\<table\>\<thead\>\<tr\>\<th width="266"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xE1AD845D93853fff44990aE0DcecD8575293681e\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x6D205337F45D6850c3c3006e28d5b52c8a432c35\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xd9492653457A69E9f4987DB43D7fa0112E620Cb4\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x824D8FcDC36E81618377D140BEC12c3B7E4e4cbA\</td\>\</tr\>\<tr\>\<td\>StargatePoolETH.json\</td\>\<td\>0xe9aBA835f813ca05E50A6C0ce65D0D74390F7dE7\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.json\</td\>\<td\>0xB1EeAD6959cb5bB9B20417d6689922523B2B86C3\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xAf368c91793CB22739386DFCbBb2F1A9e4bCBeBf\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Soneium

\`endpointID: 30340\`

\<table\>\<thead\>\<tr\>\<th width="256"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x693604E757AC7e2c4A8263594A18d69c35562341\</td\>\</tr\>\<tr\>\<td\>RewardLib.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>RewardRegistryLib.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateStaking.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\</tbody\>\</table\>

\#\# Hydra CAs

\#\#\# Kaia

\`endpointID:\` \`30150\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0xB83ab1FF56cCD2B9E9914c68C182135C3a7ECFcd\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x8d92105ae654f494CE10B3b3e4C58186E3e0dA00\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x6eFfA1afE190a652a8204D318fec03D3dD9402d2\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.sol\</td\>\<td\>0x55Acee547DF909CF844e32DD66eE55a6F81dC71b\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.sol\</td\>\<td\>0xBB4957E44401a31ED81Cab33539d9e8993FA13Ce\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.sol\</td\>\<td\>0x01A7c805cc47AbDB254CD8AaD29dE5e447F59224\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.sol\</td\>\<td\>0x8619bA1B324e099CB2227060c4BC5bDEe14456c6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x16F3F98D82d965988E6853681fD578F4d719A1c0\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x259EF40ebe42073bd70966519B53791f03a9212f\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Iota

\`endpointID:\` \`30284\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x0dB9afb4C33be43a0a0e396Fd1383B4ea97aB10a\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0xCd4302D950e7e6606b6910Cd232758b5ad423311\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x711b5aAFd4d0A5b7B863Ca434A2678D086830d8E\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.sol\</td\>\<td\>0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.sol\</td\>\<td\>0x9c2dc7377717603eB92b2655c5f2E7997a4945BD\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.sol\</td\>\<td\>0x8e8539e4CcD69123c623a106773F2b0cbbc58746\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.sol\</td\>\<td\>0x77C71633C34C3784ede189d74223122422492a0f\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x1C10CC06DC6D35970d1D53B2A23c76ef370d4135\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x8c1014B5936dD88BAA5F4DB0423C3003615E03a0\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Taiko

\`endpointID:\` \`30290\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0xCd4302D950e7e6606b6910Cd232758b5ad423311\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x711b5aAFd4d0A5b7B863Ca434A2678D086830d8E\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.sol\</td\>\<td\>0x77C71633C34C3784ede189d74223122422492a0f\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.sol\</td\>\<td\>0x1C10CC06DC6D35970d1D53B2A23c76ef370d4135\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x45d417612e177672958dC0537C45a8f8d754Ac2E\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x8c1014B5936dD88BAA5F4DB0423C3003615E03a0\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Rari Chain

\`endpointID:\` \`30235\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x9c2dc7377717603eB92b2655c5f2E7997a4945BD\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x8e8539e4CcD69123c623a106773F2b0cbbc58746\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.sol\</td\>\<td\>0x875bee36739e7Ce6b60E056451c556a88c59b086\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.sol\</td\>\<td\>0x17d65bF79E77B6Ab21d8a0afed3bC8657d8Ee0B2\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0xC1B8045A6ef2934Cf0f78B0dbD489969Fa9Be7E4\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x77C71633C34C3784ede189d74223122422492a0f\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Sei

\`endpointID:\` \`30280\`

{% hint style="info" %}  
Note: Sei has a mix of Pools (for stables) and Hydra (for WETH). This doesn't change anything from a development standpoint, but will change the bridge limits (credits).  
{% endhint %}

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0xDe48600aA18Ae707f5D57e0FaafEC7C118ABaeb2\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0xCd4302D950e7e6606b6910Cd232758b5ad423311\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x711b5aAFd4d0A5b7B863Ca434A2678D086830d8E\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0xd69A3D88438f042a5a0b995b970F78FC8120ED67\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.sol\</td\>\<td\>0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.sol\</td\>\<td\>0x5c386D85b1B82FD9Db681b9176C8a4248bb6345B\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x45d417612e177672958dC0537C45a8f8d754Ac2E\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x0dB9afb4C33be43a0a0e396Fd1383B4ea97aB10a\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0x8c1014B5936dD88BAA5F4DB0423C3003615E03a0\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x1502FA4be69d526124D453619276FacCab275d3D\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x873cfB4bAe1Ab6A5DE753400e9d0616e10Dced22\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Flare

\`endpointID:\` \`30295\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0xCd4302D950e7e6606b6910Cd232758b5ad423311\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x711b5aAFd4d0A5b7B863Ca434A2678D086830d8E\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x8c1014B5936dD88BAA5F4DB0423C3003615E03a0\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.sol\</td\>\<td\>0x1502FA4be69d526124D453619276FacCab275d3D\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.sol\</td\>\<td\>0x8e8539e4CcD69123c623a106773F2b0cbbc58746\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.sol\</td\>\<td\>0x77C71633C34C3784ede189d74223122422492a0f\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.sol\</td\>\<td\>0x1C10CC06DC6D35970d1D53B2A23c76ef370d4135\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x45d417612e177672958dC0537C45a8f8d754Ac2E\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x090194F1EEDc134A680e3b488aBB2D212dba8c01\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Gravity

\`endpointID:\` \`30294\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x77C71633C34C3784ede189d74223122422492a0f\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x1C10CC06DC6D35970d1D53B2A23c76ef370d4135\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x45d417612e177672958dC0537C45a8f8d754Ac2E\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.sol\</td\>\<td\>0xf6f832466Cd6C21967E0D954109403f36Bc8ceaA\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.sol\</td\>\<td\>0x17d65bF79E77B6Ab21d8a0afed3bC8657d8Ee0B2\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.sol\</td\>\<td\>0xC1B8045A6ef2934Cf0f78B0dbD489969Fa9Be7E4\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.sol\</td\>\<td\>0x0B38e83B86d491735fEaa0a791F65c2B99535396\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x9c2dc7377717603eB92b2655c5f2E7997a4945BD\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x0dB9afb4C33be43a0a0e396Fd1383B4ea97aB10a\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Lightlink&\#x20;

\`endpointID: 30309\`&\#x20;

{% hint style="info" %}  
Note: Lightlink has a mix of Pools (for ETH) and Hydra (for Stables). This doesn't change anything from a development standpoint, but will change the bridge limits (credits).  
{% endhint %}

\<table\>\<thead\>\<tr\>\<th width="266"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xB0D502E938ed5f4df2E681fE6E419ff29631d62b\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x701a95707A0290AC8B90b3719e8EE5b210360883\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x6D5E6657ef23f3636Af84EE9Db5B51b4AD2CF129\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x06Eb48763f117c7Be887296CDcdfad2E4092739C\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614\</td\>\</tr\>\<tr\>\<td\>RewardLib.json\</td\>\<td\>0x6694340fc020c5E6B96567843da2df01b2CE1eb6\</td\>\</tr\>\<tr\>\<td\>RewardRegistryLib.json\</td\>\<td\>0xe7Ec689f432f29383f217e36e680B5C855051f25\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.json\</td\>\<td\>0x5c1a97C144A97E9b370F833a06c70Ca8F2f30DE5\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x8EE21165Ecb7562BA716c9549C1dE751282b9B33\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>StargateStaking.json\</td\>\<td\>0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x693604E757AC7e2c4A8263594A18d69c35562341\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x3052A0F6ab15b4AE1df39962d5DdEFacA86DaB47\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Abstract

\`endpointID: 30324\`

{% hint style="info" %}  
Note: Abstract has a mix of Pools (for ETH) and Hydra (for Stables). This doesn't change anything from a development standpoint, but will change the bridge limits (credits).  
{% endhint %}

\<table\>\<thead\>\<tr\>\<th width="256"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xc0BdF9152E5FE7E29ac2de8072fA42A3565DF751\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x79f51a560298740C764a487655F8fB94c42AB4Fd\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x583548D69D63f4d56A75B78c55a0cE1584D29BBE\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x9C7007501FAEA5011D2E04cBDD4F65B8890a3F40\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xDD46bF5693Cdd732D09091794efcf3bA62920157\</td\>\</tr\>\<tr\>\<td\>RewardLib.json\</td\>\<td\>0xBc6dE829570780D1248ADb5AC4FF35b92B293e97\</td\>\</tr\>\<tr\>\<td\>RewardRegistryLib.json\</td\>\<td\>0xAFf6D1E61fedA42fEfB77E70084e38F68b9a7646\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.json\</td\>\<td\>0x5F9c011dFf285E76fa64c14301fD6493A2F3B671\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x91a5Fe991ccB876d22847967CEd24dCd7A426e0E\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x943C484278b8bE05D119DfC73CfAa4c9D8f11A76\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.json\</td\>\<td\>0x221F0E1280Ec657503ca55c708105F1e1529527D\</td\>\</tr\>\<tr\>\<td\>StargateStaking.json\</td\>\<td\>0x945320436aBd33D21C0d7d79290627293b3cC7bd\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x183D6b82680189bB4dB826F739CdC9527D467B25\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x953519953FE196a0c8A031157C751Fc732Ea5599\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Peaq

\`EndpointID: 30302\`

\<table\>\<thead\>\<tr\>\<th width="256"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x352d8275AAE3e0c2404d9f68f6cEE084B5bEB3DD\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x4CC10835f7E5D2eEc2E1c2c0Afd239B41ac29e32\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x6D5E6657ef23f3636Af84EE9Db5B51b4AD2CF129\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x6694340fc020c5E6B96567843da2df01b2CE1eb6\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xF2c0e57f48276112a596e141817D93bE472Ed6c5\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0xe7Ec689f432f29383f217e36e680B5C855051f25\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x5c1a97C144A97E9b370F833a06c70Ca8F2f30DE5\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x07cd5A2702394E512aaaE54f7a250ea0576E5E8C\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x8943cb63EEF1B3Dba5F455bFB704477436E31c1A\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Flow

\`endpointID:\` 30336

\<table\>\<thead\>\<tr\>\<th width="256"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Goat&\#x20;

\`endpointID: 30361\`

\<table\>\<thead\>\<tr\>\<th width="256"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x164A2dE1bc5dc56F329909F7c97Bae929CaE557B\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0xa7F3e26df31Abcb20a6Fe6bE35DdC60702a32455\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x2d93FbcE4CffC15DD385A80B3f4CC1D4E76C38b3\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT\</td\>\<td\>0x4F5F42799d1E01662B629Ede265baEa223e9f9C7\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x3a1293Bdb83bBbDd5Ebf4fAc96605aD2021BbC0f\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x87C367a0522AEb8aD9F9660D2250f1eAC403C70F\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x88853D410299BCBfE5fCC9Eef93c03115E908279\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xbbA60da06c2c5424f03f7434542280FCAd453d10\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x549943e04f40284185054145c6E4e9568C1D3241\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xB0B2391a32E066FDf354ef7f4199300f920789F0\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x370DC69d5B49E6844C867efA752b419EaC49ABa8\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Berachain

\`endpointID:\` 30362

\<table\>\<thead\>\<tr\>\<th width="256"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Rootstock

\`endpointID:\` 30333

\<table\>\<thead\>\<tr\>\<th width="256"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Hemi

\`endpointID: 30329\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\<tr\>\<td\>RewardLib.json\</td\>\<td\>0xF2c0e57f48276112a596e141817D93bE472Ed6c5\</td\>\</tr\>\<tr\>\<td\>RewardRegistryLib.json\</td\>\<td\>0xC53e6d7018e2D10EbEd643302567f8dE752804fB\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.json\</td\>\<td\>0xe4111e53f1b59bBEE7dd88394ee995f058B404ea\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>StargateStaking.json\</td\>\<td\>0x8943cb63EEF1B3Dba5F455bFB704477436E31c1A\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Vana

\`endpointID: 30330\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0xC53e6d7018e2D10EbEd643302567f8dE752804fB\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xB0D502E938ed5f4df2E681fE6E419ff29631d62b\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xF2c0e57f48276112a596e141817D93bE472Ed6c5\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x693604E757AC7e2c4A8263594A18d69c35562341\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Ink

\`endpointID:\` 30339

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Glue

\`endpointID:\` 30342

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Fuse

\`endpointID:\` 30138

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Superposition

\`endpointID:\` 30327

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xAfB39384cd5B7d84ed4D569b7ceC294eb1Dc5EE5\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x5c1a97C144A97E9b370F833a06c70Ca8F2f30DE5\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x8EE21165Ecb7562BA716c9549C1dE751282b9B33\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x06Eb48763f117c7Be887296CDcdfad2E4092739C\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0xe7Ec689f432f29383f217e36e680B5C855051f25\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Degen

\`endpointID:\` 30267

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x8731d54E9D02c286767d56ac03e8037C07e01e98\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x06D538690AF257Da524f25D0CD52fD85b1c2173E\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Codex

\`endpointID:  30323\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xAF54BE5B6eEc24d6BFACf1cce4eaF680A8239398\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x45A01E4e04F14f7A4a6702c74187c5F6222033cd\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Story

\`endpointID: 30364\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xbbA60da06c2c5424f03f7434542280FCAd453d10\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x549943e04f40284185054145c6E4e9568C1D3241\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xB0B2391a32E066FDf354ef7f4199300f920789F0\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x164A2dE1bc5dc56F329909F7c97Bae929CaE557B\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0xBAb93B7ad7fE8692A878B95a8e689423437cc500\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xA4BbDdefaEE27cd778C4CED30C0535ec06a8502e\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0xA272fFe20cFfe769CdFc4b63088DCD2C82a2D8F9\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x2086f755A6d9254045C257ea3d382ef854849B0f\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x3a1293Bdb83bBbDd5Ebf4fAc96605aD2021BbC0f\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x88853D410299BCBfE5fCC9Eef93c03115E908279\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0xa7F3e26df31Abcb20a6Fe6bE35DdC60702a32455\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Apechain

\`endpointID: 30312\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x99e799CBD972362a84145D98498Db4430A66a734\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x60f2a61f07a51874C37ad2eD741727CcfCdFFD52\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xB0B2391a32E066FDf354ef7f4199300f920789F0\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x897aafF731077C228d6fF6F2c9E7cFd8E985F29D\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0xf4D9235269a96aaDaFc9aDAe454a0618eBE37949\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xc6Bc407706B7140EE8Eef2f86F9504651b63e7f9\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x28E0f0eed8d6A6a96033feEe8b2D7F32EB5CCc48\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x2086f755A6d9254045C257ea3d382ef854849B0f\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xEb8d955d8Ae221E5b502851ddd78E6C4498dB4f6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xBE574b6219C6D985d08712e90C21A88fd55f1ae8\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0xA4BbDdefaEE27cd778C4CED30C0535ec06a8502e\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# TelosEVM&\#x20;

\`endpointID: 30199\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th width="491"\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xbbA60da06c2c5424f03f7434542280FCAd453d10\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x549943e04f40284185054145c6E4e9568C1D3241\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xB0B2391a32E066FDf354ef7f4199300f920789F0\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x164A2dE1bc5dc56F329909F7c97Bae929CaE557B\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0xBAb93B7ad7fE8692A878B95a8e689423437cc500\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xA4BbDdefaEE27cd778C4CED30C0535ec06a8502e\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0xA272fFe20cFfe769CdFc4b63088DCD2C82a2D8F9\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x2086f755A6d9254045C257ea3d382ef854849B0f\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x3a1293Bdb83bBbDd5Ebf4fAc96605aD2021BbC0f\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x88853D410299BCBfE5fCC9Eef93c03115E908279\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0xa7F3e26df31Abcb20a6Fe6bE35DdC60702a32455\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Plume (Phoenix)

\`endpointID: 30370\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th width="491"\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x5e3291174F9C07A9a73DEBE08954617a4D95E253\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x45d2Cf18FD16090D180c23C6eAF9cd8541DBAadB\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xabD218304Aad937EEA0822C598fFCe59F4409e61\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x193564d8012A3fe2A2D886E5CaEb8920aF85CC85\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0xca59cA09E5602fAe8B629DeE83FfA819741f14be\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x3D07d5059004f494a5F075d23cB383359e5aC412\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x4683CE822272CD66CEa73F5F1f9f5cBcaEF4F066\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x9909fa99b7F7ee7F1c0CBf133f411D43083631E6\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x2D870D17e640eD6c057afBAA0DF56B8DEa5Cf2F6\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xf26d57bbE1D99561B13003783b5e040B71AdCb14\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0xBBFAB55b6C2ee954610cF92A750db332ba97Dd60\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# XDC

\`endpointID: 30365\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th width="491"\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xef9ec60e186c8A1a0439AF0AedB6dEb9f34A2c88\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0xa628bb551A3B98d4D3Fd9c4C329005307B9557e9\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x29eE6138DD4C9815f46D34a4A1ed48F46758A402\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0xD34e23b4509fF894FA939DC29baC987b7A5465C0\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0xa7348290de5cf01772479c48D50dec791c3fC212\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x936Ab8C674bcb567CD5dEB85D8A216494704E9D8\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0xB0d27478A40223e427697Da523c6A3DAF29AaFfB\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x8E2E38711080bF8AAb9C74f434d2bae70e67ae44\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xA4272ad93AC5d2FF048DD6419c88Eb4C1002Ec6b\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x2761c39102BCF7fc6365580d94cd1882F9cc2650\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x67B302E35Aef5EEE8c32D934F5856869EF428330\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Nibiru

\`endpointID: 30369\`

\<table\>\<thead\>\<tr\>\<th width="257"\>Contract\</th\>\<th width="491"\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0xc7616B08FfEC8B4ba47188bfd1A814316F3E3d79\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x01500764dd66079eaB0c2881149bDF93f9Cf394d\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x6BebD4BDDff9478cf8ddDfc54278F805bE9c51b6\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0xCc0587aeBDa397146cc828b445dB130a94486e74\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0xcdA5b77E2E2268D9E09c874c1b9A4c3F07b37555\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x28BEc7E30E6faee657a03e19Bf1128AaD7632A00\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0x108f4c02C9fcDF862e5f5131054c50f13703f916\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0x12a272A581feE5577A5dFa371afEB4b2F3a8C2F8\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0xC16977205c53Cd854136031BD2128F75D6ff63C9\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0x08C49257767c1f92634A9cDbF0663Af0356a472A\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x851C9D74BF5cfAEB4a0082A55a65A8F2718b337F\</td\>\</tr\>\</tbody\>\</table\>

\# Testnet Contracts

\#\# Sepolia&\#x20;

\`endpointID:\` \`40161\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0xF03283E7D9ffe4547ac3C571F6fFFA952422ACfa\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0xf80598283618e1BD9cAef85662653B268FDdf1F1\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x3393921e381705E7E79fa2Ac37C3D56dc66EdBA2\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x1a8B0C2F4cc508981470ec6C0F5e84C18A8af5F5\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0x9Cc7e185162Aa5D1425ee924D97a87A0a34A0706\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x4985b8fcEA3659FD801a5b857dA1D00e985863F0\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x9D819CcAE96d41d8F775bD1259311041248fF980\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xE62F51D9DA2b082abed838E9Ac48D0EDFFbfedaE\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0xfB112f7FC5725de9F630abB23E4916d6fd7526d3\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x41945d449bd72AE0E237Eade565D8Bde2aa5e969\</td\>\</tr\>\</tbody\>\</table\>

\#\# BNB Testnet

\`endpointID:\` \`40102\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x6C2d1Dc35C69296C0a1661D9f1c757d6Fc3080E8\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x3C0Dea5955cb490F78e330A213c960cA63f66314\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0xf1b69ee3097c6E8CC6487B7667dB818FeDC7b1a9\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xc26eD6ceC052D6A4935C240628841c069d2E7327\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0xe19525580913971d220dBa3BbD01eE2A0b1adc6F\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x0d7aB83370b492f2AB096c80111381674456e8d8\</td\>\</tr\>\</tbody\>\</table\>

\#\# Arbitrum Sepolia Testnet

\`endpointID:\` \`40231\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x2D942075b09c0B955994cf5bf71E25e584f23668\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x9554E739735ef03C7458577bBa6549aEc619Ac50\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x7470E97cc02b0D5be6CFFAd3fd8012755db16156\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0xD58fCBA3E5A0F5a41A708A70C3B66BcfA64aE5DE\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0x6fddB6270F6c71f31B62AE0260cfa8E2e2d186E0\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x543BdA7c6cA4384FE90B1F5929bb851F52888983\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0xB956d6FDFB235636DE7885C5166756823bb27e3a\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xba94Baa17F11145Bd072B2D14e3aaA50ec104c4a\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0x657C13E8668B4eD33e524E3F8BD8559667E3Eb9b\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xd1E255BB6354D237172802646B0d6dDCFC8c509E\</td\>\</tr\>\</tbody\>\</table\>

\#\# Optimism Sepolia Testnet

\`endpointID:\` \`40232\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x095f40616FA98Ff75D1a7D0c68685c5ef806f110\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x6fddB6270F6c71f31B62AE0260cfa8E2e2d186E0\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0x543BdA7c6cA4384FE90B1F5929bb851F52888983\</td\>\</tr\>\<tr\>\<td\>StargateMultiRewarder.sol\</td\>\<td\>0x2D942075b09c0B955994cf5bf71E25e584f23668\</td\>\</tr\>\<tr\>\<td\>StargatePoolNative.sol\</td\>\<td\>0xa31dCc5C71E25146b598bADA33E303627D7fC97e\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.sol\</td\>\<td\>0x314B753272a3C79646b92A87dbFDEE643237033a\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.sol\</td\>\<td\>0x6bD6De24CA0756698e3F2B706bBe717c2209633b\</td\>\</tr\>\<tr\>\<td\>StargateStaking.sol\</td\>\<td\>0xB956d6FDFB235636DE7885C5166756823bb27e3a\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0xea461D9B1a3d1d45E2Aa3a358c3b8cB9bF2c7063\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0x7470E97cc02b0D5be6CFFAd3fd8012755db16156\</td\>\</tr\>\</tbody\>\</table\>

\#\# Kaia Kairos Testnet

\`endpointID:\` \`40150\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>FeeLibV1ETH.sol\</td\>\<td\>0x314B753272a3C79646b92A87dbFDEE643237033a\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.sol\</td\>\<td\>0x6bD6De24CA0756698e3F2B706bBe717c2209633b\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.sol\</td\>\<td\>0xea461D9B1a3d1d45E2Aa3a358c3b8cB9bF2c7063\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.sol\</td\>\<td\>0x653DbE336414A7C83e6Fbc89762Bb73eafaD2Bd3\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.sol\</td\>\<td\>0x6312184c0cbe3D032daD2F2085b0e340B84F8b3B\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.sol\</td\>\<td\>0xf626Acea3FfBe6228149A651Aa8a8DF0c0e7A575\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.sol\</td\>\<td\>0x77A5eBAA6862E5026a12BFA5695dF4057865D6ED\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.sol\</td\>\<td\>0xdc443e1B760B1E3d2582a613a0Bc3608eBCc71Df\</td\>\</tr\>\<tr\>\<td\>Treasurer.sol\</td\>\<td\>0xAD28ba8f98B9CB5Cb0a7D5c8883CB56ADA656707\</td\>\</tr\>\</tbody\>\</table\>

\#\# Mantle Testnet

\`endpointID:\` \`40246\`

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x824D8FcDC36E81618377D140BEC12c3B7E4e4cbA\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0x40461291347e1eCbb09499F3371D3f17f10d7159\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0x3022b87ac063DE95b1570F46f5e470F8B53112D8\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0xBAb93B7ad7fE8692A878B95a8e689423437cc500\</td\>\</tr\>\<tr\>\<td\>StargatePoolETH.json\</td\>\<td\>0xE1AD845D93853fff44990aE0DcecD8575293681e\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDC.json\</td\>\<td\>0x6D205337F45D6850c3c3006e28d5b52c8a432c35\</td\>\</tr\>\<tr\>\<td\>StargatePoolUSDT.json\</td\>\<td\>0xd9492653457A69E9f4987DB43D7fa0112E620Cb4\</td\>\</tr\>\<tr\>\<td\>StargateStaking.json\</td\>\<td\>0xcD65253CBFCbee2D144a64D1f30f33fB15459858\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8\</td\>\</tr\>\</tbody\>\</table\>

\#\# Story Odyssey Testnet&\#x20;

\`endpointID:\` \`40340\`&\#x20;

\<table\>\<thead\>\<tr\>\<th width="247"\>Contract\</th\>\<th\>Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>CreditMessaging.json\</td\>\<td\>0x28E0f0eed8d6A6a96033feEe8b2D7F32EB5CCc48\</td\>\</tr\>\<tr\>\<td\>FeeLibV1ETH.json\</td\>\<td\>0x57E62D957ceAa67B49F51101De62b9E54e01FCE3\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDC.json\</td\>\<td\>0xEb8d955d8Ae221E5b502851ddd78E6C4498dB4f6\</td\>\</tr\>\<tr\>\<td\>FeeLibV1USDT.json\</td\>\<td\>0xBE574b6219C6D985d08712e90C21A88fd55f1ae8\</td\>\</tr\>\<tr\>\<td\>OFTTokenETH.json\</td\>\<td\>0xd8cF92E9B6Fae6B32f795AcB11Edd50E8dD6Ff4d\</td\>\</tr\>\<tr\>\<td\>OFTWrapper.json\</td\>\<td\>0x60f2a61f07a51874C37ad2eD741727CcfCdFFD52\</td\>\</tr\>\<tr\>\<td\>StargateOFTETH.json\</td\>\<td\>0xad11a8BEb98bbf61dbb1aa0F6d6F2ECD87b35afA\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDC.json\</td\>\<td\>0xCD9A74e5fe451025E92b5b8F74117c6E275Aa7c8\</td\>\</tr\>\<tr\>\<td\>StargateOFTUSDT.json\</td\>\<td\>0x4bb13347ce7Cbf8884ADB137AEDa0355Ef61B259\</td\>\</tr\>\<tr\>\<td\>TokenMessaging.json\</td\>\<td\>0xf4D9235269a96aaDaFc9aDAe454a0618eBE37949\</td\>\</tr\>\<tr\>\<td\>Treasurer.json\</td\>\<td\>0x99e799CBD972362a84145D98498Db4430A66a734\</td\>\</tr\>\</tbody\>\</table\>

\# Asset IDs

\#\# Pool Assets

\#\#\# Ethereum&\#x20;

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="101"\>ID\</th\>\<th width="158"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\<tr\>\<td\>METIS\</td\>\<td\>17\</td\>\<td\>S\*METIS\</td\>\</tr\>\<tr\>\<td\>mETH\</td\>\<td\>22\</td\>\<td\>S\*mETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# BNB Chain

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="159"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Avalanche

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="161"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Polygon

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="166"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Arbitrum

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="167"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Optimism

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="171"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Metis

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="175"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>m.USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>13\</td\>\<td\>S\*WETH\</td\>\</tr\>\<tr\>\<td\>METIS\</td\>\<td\>17\</td\>\<td\>S\*METIS\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Linea

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="174"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Mantle

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="177"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>13\</td\>\<td\>S\*WETH\</td\>\</tr\>\<tr\>\<td\>mETH\</td\>\<td\>22\</td\>\<td\>S\*mETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Base

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="180"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Kava

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="185"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Scroll

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="191"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC.e\</td\>\<td\>1\</td\>\<td\>S\*USDC.e\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Aurora

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Lightlink

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Core

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>2\</td\>\<td\>S\*USDT\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Abstract

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Soneium

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Hemi

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Sonic

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Gnosis

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>1\</td\>\<td\>S\*USDC\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Unichain

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>ID\</th\>\<th width="195"\>lpTokenSymbol\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>13\</td\>\<td\>S\*ETH\</td\>\</tr\>\</tbody\>\</table\>

\# (V2) Supported Networks and Assets

\#\# Pool Assets

\#\#\# Ethereum&\#x20;

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="117"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"\>0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://etherscan.io/address/0xdAC17F958D2ee523a2206206994597C13D831ec7"\>0xdac17f958d2ee523a2206206994597c13d831ec7\</a\>\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\<tr\>\<td\>METIS\</td\>\<td\>18\</td\>\<td\>\<a href="https://etherscan.io/address/0x9e32b13ce7f2e80a01932b42553652e053d6ed8e"\>0x9e32b13ce7f2e80a01932b42553652e053d6ed8e\</a\>\</td\>\</tr\>\<tr\>\<td\>mETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://etherscan.io/address/0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa"\>0xd5f7838f5c461feff7fe49ea5ebaf7728bb0adfa\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# BNB Chain

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>18\</td\>\<td\>\<a href="https://bscscan.com/token/0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"\>0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>18\</td\>\<td\>\<a href="https://bscscan.com/address/0x55d398326f99059fF775485246999027B3197955"\>0x55d398326f99059fF775485246999027B3197955\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Avalanche

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://snowtrace.io/token/0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E"\>0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://snowtrace.io/token/0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7"\>0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Polygon

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://polygonscan.com/address/0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"\>0x3c499c542cef5e3811e1192ce70d8cc03d5c3359\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://polygonscan.com/address/0xc2132d05d31c914a87c6611c10748aeb04b58e8f"\>0xc2132d05d31c914a87c6611c10748aeb04b58e8f\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Arbitrum

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://arbiscan.io/token/0xaf88d065e77c8cc2239327c5edb3a432268e5831"\>0xaf88d065e77c8cc2239327c5edb3a432268e5831\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://arbiscan.io/token/0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9"\>0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9\</a\>\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Optimism

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://optimistic.etherscan.io/token/0x0b2c639c533813f4aa9d7837caf62653d097ff85"\>0x0b2c639c533813f4aa9d7837caf62653d097ff85\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://optimistic.etherscan.io/address/0x94b008aa00579c1307b0ef2c499ad98a8ce58e58\#code"\>0x94b008aa00579c1307b0ef2c499ad98a8ce58e58\</a\>\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Metis

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="436"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>m.USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://andromeda-explorer.metis.io/address/0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC"\>0xbb06dca3ae6887fabf931640f67cab3e3a16f4dc\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://andromeda-explorer.metis.io/address/0x420000000000000000000000000000000000000A"\>0x420000000000000000000000000000000000000a\</a\>\</td\>\</tr\>\<tr\>\<td\>METIS\</td\>\<td\>18\</td\>\<td\>\<a href="https://andromeda-explorer.metis.io/token/0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000"\>0xdeaddeaddeaddeaddeaddeaddeaddeaddead0000\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Linea

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Mantle

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="435"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.mantle.xyz/token/0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9"\>0x09bc4e0d864854c6afb6eb9a9cdf58ac190d0df9\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.mantle.xyz/address/0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE"\>0x201eba5cc46d216ce6dc03f6a759e8e766e956ae\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.mantle.xyz/address/0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111"\>0xdeaddeaddeaddeaddeaddeaddeaddeaddead1111\</a\>\</td\>\</tr\>\<tr\>\<td\>mETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.mantle.xyz/token/0xcDA86A272531e8640cD7F1a92c01839911B90bb0"\>0xcda86a272531e8640cd7f1a92c01839911b90bb0\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Base

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://basescan.org/token/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"\>0x833589fcd6edb6e08f4c7c32d4f71b54bda02913\</a\>\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Kava

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://kavascan.com/address/0x919C1c267BC06a7039e03fcc2eF738525769109c"\>0x919c1c267bc06a7039e03fcc2ef738525769109c\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Scroll

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC.e\</td\>\<td\>6\</td\>\<td\>\<a href="https://scrollscan.com/token/0x06efdbff2a14a7c8e15944d1f4a48f9f95f663a4"\>0x06efdbff2a14a7c8e15944d1f4a48f9f95f663a4\</a\>\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Aurora

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.aurora.dev/address/0x368EBb46ACa6b8D0787C96B2b20bD3CC3F2c45F7"\>0x368ebb46aca6b8d0787c96b2b20bd3cc3f2c45f7\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Sei (stablecoins)

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://seitrace.com/token/0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1?chain=pacific-1"\>0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://seitrace.com/address/0x0dB9afb4C33be43a0a0e396Fd1383B4ea97aB10a?chain=pacific-1"\>0x0dB9afb4C33be43a0a0e396Fd1383B4ea97aB10a\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# zkSync Era (Coming Soon...)

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.zksync.io/address/0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4"\>0x1d17cbcf0d6d143135ae902365d2e5e2a16538d4\</a\>\</td\>\</tr\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Lightlink

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="115"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Core

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://scan.coredao.org/address/0xa4151b2b3e269645181dccf2d426ce75fcbdeca9"\>0xa4151b2b3e269645181dccf2d426ce75fcbdeca9\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://scan.coredao.org/address/0x900101d06a7426441ae63e9ab3b9b0f63be145f1"\>0x900101d06a7426441ae63e9ab3b9b0f63be145f1\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Soneium

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>0xbA9986D2381edf1DA03B0B9c1f8b00dc4AacC369\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Sonic

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://sonicscan.org/address/0x29219dd400f2bf60e5a23d13be72b486d4038894"\>0x29219dd400f2bf60e5a23d13be72b486d4038894\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Gnosis

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://gnosis.blockscout.com/address/0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1"\>0x6a023ccd1ff6f2045c3309768ead9e68f978f6e1\</a\>\</td\>\</tr\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://gnosisscan.io/address/0x2a22f9c3b484c3629090feed35f17ff8f88f76f0"\>0x2a22f9c3b484c3629090feed35f17ff8f88f76f0\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Unichain

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>ETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://unichain.blockscout.com/address/0xe9aBA835f813ca05E50A6C0ce65D0D74390F7dE7?tab=token\_transfers"\>0xe9aBA835f813ca05E50A6C0ce65D0D74390F7dE7\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\# Hydra Supported Assets

\#\#\# Kaia

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://klaytnscope.com/account/0xe2053bcf56d2030d2470fb454574237cf9ee3d4b"\>0xe2053bcf56d2030d2470fb454574237cf9ee3d4b\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://klaytnscope.com/account/0x9025095263d1e548dc890a7589a4c78038ac40ab"\>0x9025095263d1e548dc890a7589a4c78038ac40ab\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://klaytnscope.com/account/0x55acee547df909cf844e32dd66ee55a6f81dc71b"\>0x55acee547df909cf844e32dd66ee55a6f81dc71b\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Iota

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.evm.iota.org/token/0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6"\>0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.evm.iota.org/token/0xC1B8045A6ef2934Cf0f78B0dbD489969Fa9Be7E4"\>0xC1B8045A6ef2934Cf0f78B0dbD489969Fa9Be7E4\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.evm.iota.org/token/0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8"\>0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Taiko

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://taikoscan.io/address/0x19e26b0638bf63aa9fa4d14c6baf8d52ebe86c5c"\>0x19e26B0638bf63aa9fa4d14c6baF8D52eBE86C5C\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://taikoscan.io/address/0x9c2dc7377717603eB92b2655c5f2E7997a4945BD"\>0x9c2dc7377717603eB92b2655c5f2E7997a4945BD\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Rari Chain

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://mainnet.explorer.rarichain.org/token/0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6"\>0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://mainnet.explorer.rarichain.org/token/0x362FAE9A75B27BBc550aAc28a7c1F96C8D483120"\>0x362FAE9A75B27BBc550aAc28a7c1F96C8D483120\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Sei (WETH)

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://seitrace.com/token/0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8?chain=pacific-1"\>0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Flare

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://mainnet.flarescan.com/token/0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6"\>0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://mainnet.flarescan.com/token/0x0B38e83B86d491735fEaa0a791F65c2B99535396"\>0x0B38e83B86d491735fEaa0a791F65c2B99535396\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://mainnet.flarescan.com/token/0x1502FA4be69d526124D453619276FacCab275d3D"\>0x1502FA4be69d526124D453619276FacCab275d3D\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Gravity

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="438"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.gravity.xyz/address/0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6"\>0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.gravity.xyz/address/0x816E810f9F787d669FB71932DeabF6c83781Cd48"\>0x816E810f9F787d669FB71932DeabF6c83781Cd48\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.gravity.xyz/address/0xf6f832466Cd6C21967E0D954109403f36Bc8ceaA"\>0xf6f832466Cd6C21967E0D954109403f36Bc8ceaA\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Lightlink

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://phoenix.lightlink.io/address/0xbCF8C1B03bBDDA88D579330BDF236B58F8bb2cFd"\>0xbCF8C1B03bBDDA88D579330BDF236B58F8bb2cFd\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://phoenix.lightlink.io/address/0x808d7c71ad2ba3FA531b068a2417C63106BC0949"\>0x808d7c71ad2ba3FA531b068a2417C63106BC0949\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Abstract

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://abscan.org/address/0x84A71ccD554Cc1b02749b35d22F684CC8ec987e1"\>0x84A71ccD554Cc1b02749b35d22F684CC8ec987e1\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://abscan.org/address/0x0709f39376deee2a2dfc94a58edeb2eb9df012bd"\>0x0709f39376deee2a2dfc94a58edeb2eb9df012bd\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>-\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Peaq

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>0xbbA60da06c2c5424f03f7434542280FCAd453d10\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>0xf4D9235269a96aaDaFc9aDAe454a0618eBE37949\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>0x6694340fc020c5E6B96567843da2df01b2CE1eb6\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Flow

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://evm.flowscan.io/address/0xF1815bd50389c46847f0Bda824eC8da914045D14"\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://evm.flowscan.io/address/0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8"\>0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://evm.flowscan.io/address/0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590"\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Goat

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.goat.network/address/0x3022b87ac063DE95b1570F46f5e470F8B53112D8"\>0x3022b87ac063DE95b1570F46f5e470F8B53112D8\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.goat.network/address/0xE1AD845D93853fff44990aE0DcecD8575293681e"\>0xE1AD845D93853fff44990aE0DcecD8575293681e\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.goat.network/address/0x3a1293Bdb83bBbDd5Ebf4fAc96605aD2021BbC0f"\>0x3a1293Bdb83bBbDd5Ebf4fAc96605aD2021BbC0f\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Bera

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://berascan.com/address/0x549943e04f40284185054145c6E4e9568C1D3241"\>0x549943e04f40284185054145c6E4e9568C1D3241\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://berascan.com/address/0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590"\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Rootstock

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.rootstock.io/address/0x74c9f2b00581f1b11aa7ff05aa9f608b7389de67"\>0x74c9f2b00581f1b11aa7ff05aa9f608b7389de67\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.rootstock.io/address/0xaf368c91793cb22739386dfcbbb2f1a9e4bcbebf"\>0xaf368c91793cb22739386dfcbbb2f1a9e4bcbebf\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.rootstock.io/address/0x45f1a95a4d3f3836523f5c83673c797f4d4d263b"\>0x45f1A95A4D3f3836523F5c83673c797f4d4d263B\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Hemi

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.hemi.xyz/address/0xad11a8BEb98bbf61dbb1aa0F6d6F2ECD87b35afA"\>0xad11a8BEb98bbf61dbb1aa0F6d6F2ECD87b35afA\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.hemi.xyz/address/0xbB0D083fb1be0A9f6157ec484b6C79E0A4e31C2e"\>0xbB0D083fb1be0A9f6157ec484b6C79E0A4e31C2e\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Vana

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>0x88853D410299BCBfE5fCC9Eef93c03115E908279\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Ink

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.inkonchain.com/address/0xF1815bd50389c46847f0Bda824eC8da914045D14"\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Glue

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.glue.net/address/0xEe45ed3f6c675F319BB9de62991C1E78B484e0B8"\>0xEe45ed3f6c675F319BB9de62991C1E78B484e0B8\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.glue.net/address/0xE1AD845D93853fff44990aE0DcecD8575293681e"\>0xE1AD845D93853fff44990aE0DcecD8575293681e\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.glue.net/address/0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590"\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Fuse

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.fuse.io/address/0xc6Bc407706B7140EE8Eef2f86F9504651b63e7f9"\>0xc6Bc407706B7140EE8Eef2f86F9504651b63e7f9\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.fuse.io/address/0x3695Dd1D1D43B794C0B13eb8be8419Eb3ac22bf7"\>0x3695Dd1D1D43B794C0B13eb8be8419Eb3ac22bf7\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.fuse.io/address/0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590"\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Superposition

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.superposition.so/address/0x6c030c5CC283F791B26816f325b9C632d964F8A1"\>0x6c030c5CC283F791B26816f325b9C632d964F8A1\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Degen

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.degen.tips/address/0xF1815bd50389c46847f0Bda824eC8da914045D14"\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.degen.tips/address/0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8"\>0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://explorer.degen.tips/address/0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590"\>0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Codex

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.codex.is/address/0xbbA60da06c2c5424f03f7434542280FCAd453d10"\>0xbbA60da06c2c5424f03f7434542280FCAd453d10\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Story

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://kmnzxolweu42.blockscout.com/address/0xF1815bd50389c46847f0Bda824eC8da914045D14"\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6 \</td\>\<td\>\<a href="https://kmnzxolweu42.blockscout.com/address/0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8"\>0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://kmnzxolweu42.blockscout.com/token/0x58930309F22fCBd758dE30b63caC7baBB8860cd8"\>0x58930309F22fCBd758dE30b63caC7baBB8860cd8\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Apechain

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://apescan.io/address/0xF1815bd50389c46847f0Bda824eC8da914045D14"\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6 \</td\>\<td\>\<a href="https://apescan.io/address/0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8"\>0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://apescan.io/address/0xf4D9235269a96aaDaFc9aDAe454a0618eBE37949"\>0xf4D9235269a96aaDaFc9aDAe454a0618eBE37949\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Telos

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://www.teloscan.io/address/0xF1815bd50389c46847f0Bda824eC8da914045D14?tab=transactions"\>0xF1815bd50389c46847f0Bda824eC8da914045D14\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6 \</td\>\<td\>\<a href="https://www.teloscan.io/address/0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8"\>0x674843C06FF83502ddb4D37c2E09C01cdA38cbc8\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://www.teloscan.io/address/0xBAb93B7ad7fE8692A878B95a8e689423437cc500"\>0xBAb93B7ad7fE8692A878B95a8e689423437cc500\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Plume (Phoenix)

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://explorer.plume.org/token/0x78adD880A697070c1e765Ac44D65323a0DcCE913"\>0x78adD880A697070c1e765Ac44D65323a0DcCE913\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6 \</td\>\<td\>\<a href="https://explorer.plume.org/token/0xda6087E69C51E7D31b6DBAD276a3c44703DFdCAd"\>0xda6087E69C51E7D31b6DBAD276a3c44703DFdCAd\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://phoenix-explorer.plumenetwork.xyz/address/0xca59cA09E5602fAe8B629DeE83FfA819741f14be"\>0xca59cA09E5602fAe8B629DeE83FfA819741f14\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# XDC

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://xdcscan.com/token/0xCc0587aeBDa397146cc828b445dB130a94486e74"\>0xCc0587aeBDa397146cc828b445dB130a94486e74\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6 \</td\>\<td\>\<a href="https://xdcscan.com/token/0xcdA5b77E2E2268D9E09c874c1b9A4c3F07b37555"\>0xcdA5b77E2E2268D9E09c874c1b9A4c3F07b37555\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://xdcscan.com/address/0xa7348290de5cf01772479c48D50dec791c3fC212"\>0xa7348290de5cf01772479c48D50dec791c3fC212\</a\>\</td\>\</tr\>\</tbody\>\</table\>

\#\#\# Nibiru

\<table data-full-width="true"\>\<thead\>\<tr\>\<th width="118"\>Asset\</th\>\<th width="103"\>Decimals\</th\>\<th width="459"\>Contract Address\</th\>\</tr\>\</thead\>\<tbody\>\<tr\>\<td\>USDC\</td\>\<td\>6\</td\>\<td\>\<a href="https://nibiscan.io/token/0x0829F361A05D993d5CEb035cA6DF3446b060970b?type=erc20"\>0x0829F361A05D993d5CEb035cA6DF3446b060970b\</a\>\</td\>\</tr\>\<tr\>\<td\>USDT\</td\>\<td\>6 \</td\>\<td\>\<a href="https://nibiscan.io/token/0x43F2376D5D03553aE72F4A8093bbe9de4336EB08"\>0x43F2376D5D03553aE72F4A8093bbe9de4336EB08\</a\>\</td\>\</tr\>\<tr\>\<td\>WETH\</td\>\<td\>18\</td\>\<td\>\<a href="https://nibiscan.io/token/0xcdA5b77E2E2268D9E09c874c1b9A4c3F07b37555"\>0xcdA5b77E2E2268D9E09c874c1b9A4c3F07b37555\</a\>\</td\>\</tr\>\</tbody\>\</table\>

