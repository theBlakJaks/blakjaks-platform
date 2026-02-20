

\# Oobit's Plug & Pay SDK

Power your wallet with embedded gloabal payments

\#\# Builder guide Plug & Pay

Issuing payment programs is slow, complex, and compliance heavy  
Users hold stablecoins and want to spend them everywhere.

Oobit's Plug & Pay solves both.

\*\*\*

\#\# What you get

The \*\*Plug & Pay SDK\*\* is a white labeled wallet-native payments solution designed to seamlessly connect self-custody crypto wallets or exchanges with traditional merchant payment rails.

Oobit runs the entire payment stack. Wallets just plug it in.

\*\*\*

\#\# Stand out better & faster

:credit\\\_card: \*\*Wallet-Native Payments\*\*\\  
Your wallet just got spending functionality directly within your app.

:shield: \*\*Compliance handled\*\*\\  
Oobit runs KYC, AML, and risk screening end to end.

:jigsaw: \*\*Issuing handled\*\*\\  
Card issuing, activation, and lifecycle fully managed by Oobit. No monthly commitment.

:earth\\\_africa: \*\*Settlement handled\*\*\\  
Oobit manages fiat settlement through Visa globally.

:art: \*\*White label solution\*\*\\  
Fully white label cards available on \*\*Google Wallet\*\* and \*\*Apple Pay\*\*.

\#\# Wherever Visa works, your wallet works too

\*\*\*

\#\# Get started

1\. Get your Plug & Pay account and API keys by submitting your info here.  
2\. Immediately after your approval, you can start using our sandbox environment.  
3\. Once you've completed the KYB process, your API keys will be made available in the developers tab of the dashboard.

   If you have any questions, reach out to \[Wallets@oobit.com\](mailto:wallets@oobit.com)

\<br /\>

\# Quick Start

Get started with Oobit Plug & Pay

\#\#\# 1\. Get Your API Key

Receive your API credentials from Oobit to authenticate your integration.

Contact \[wallets@oobit.com\](mailto:wallets@oobit.com) to request your API key.

\#\#\# 2\. Set Up Your Backend

Configure your backend server to generate access tokens for your users.

→ \[Authentication Guide\](authentication)

\#\#\# 3\. Implement the SDK

Add the Oobit Widget to your React Native or Expo app.

→ \[SDK Getting Started\](../docs/getting-started)

\#\#\# 4\. Go Live\!

Test your integration and launch.

\<br /\>

\# FAQ

\<br /\>

\#\#\# What is Oobit Plug and Pay?

Plug & Pay is Oobit’s embedded payment service that lets wallets enable real world spending directly inside their product. Oobit handles compliance, card issuing, settlement, and global acceptance so wallets do not need to build payment infrastructure.

\#\#\# Who is Plug and Pay built for?

Plug and Pay is built for, Crypto wallets, Web3 apps, Stablecoin platforms, Exchanges expanding into payments  
Any product that wants to enable real world spending without running a card or compliance stack.

\#\#\# How difficult is the integration?

Integration is lightweight.  
Wallets integrate a few lines of code and can go live in days instead of months.  
Oobit provides documentation, sandbox access, and engineering support during onboarding.

\#\#\# Do wallets need licenses or issuer relationships?

No. Wallets do not need licenses, issuer banks, or card network relationships.  
Oobit operates the full regulated payment stack.

\#\#\# Do wallets need to manage KYC or compliance?

No. Oobit runs KYC, AML, and risk screening end to end.  
Compliance workflows are embedded and handled fully by Oobit.

\#\#\# Who handles card issuing and lifecycle management?

Oobit handles card issuing, activation, lifecycle management, and termination.  
Wallets do not interact with issuers or card networks directly.

\#\#\# Where can users spend with Plug & Pay?

Users can pay online and in store wherever Visa is accepted worldwide.  
This includes over 150 million merchants globally.

\#\#\# Does Plug & Pay support Apple Pay and Google Pay?

Yes. Plug & Pay supports payments through Apple Pay and Google Pay where available.  
Which cryptocurrencies does Plug and Pay support  
Plug & Pay currently supports stablecoins.  
Support for additional crypto assets is planned and will be introduced gradually based on demand, liquidity, and network efficiency.

\#\#\# Which networks are supported for funding?

Plug & Pay supports multi network funding including TRC20, ERC20, and BNB Smart Chain.  
Additional networks are added over time.

\#\#\# Can wallets fully brand the card design?

Yes. Plug and Pay supports fully branded card designs.  
Wallets can customize the card look and feel so it aligns with their brand and feels native to their product.

\#\#\# Are there monthly spending limits?

Yes. Oobit applies clear daily and monthly spending limits.

\*\*Daily limit\*\*  
Up to 5,000 USD per day

\*\*Monthly limit\*\*  
Up to 150,000 USD per month

These limits may be updated from time to time. If any changes occur, users and partners will be notified.

\#\#\# What does the customer journey look like?

1\. Users access Plug and Pay inside the wallet  
2\. Complete identity verification in minutes  
3\. Fund directly from host wallet balance  
4\. Cards activate instantly and available via Apple and Google wallets.  
5\. Users spend online or in store wherever Visa works.

Oobit handles everything behind the scenes.

\#\#\# How do wallets earn money with Plug & Pay?

Wallets earn revenue through transaction based fees.  
Once live, partners can add an affiliate fee to each transaction processed through Plug & Pay.

\#\#\# How do wallets get paid?

Wallets are paid according to the commercial terms defined in the partner agreement.  
Oobit provides analytics and reporting, and settlements are made on the agreed payout schedule.

\#\#\# Are there any integration or platform fees?

Yes. Oobit charges a subscription fee that provides full access to Plug and Pay, includes analytics and reporting, engineering and integration support.  
Partners can also add affiliate fees once live.

\#\#\# Are there unsupported countries?

Yes. Some countries are not supported due to regulatory or compliance restrictions.  
Oobit maintains an updated list of supported and unsupported countries.  
Coverage expands over time.  
For the most current availability, partners should contact their Oobit account representative.

\#\#\# How are chargebacks handled?

At Oobit, we treat chargebacks seriously and have processes in place to prevent and handle chargebacks.  
Oobit manages monitoring, workflows, and resolution in line with card network requirements.  
For detailed chargeback policies, partners should reach out to their Oobit account representative.

\#\#\# Is Plug and Pay global from day one?

Yes. Plug and Pay is designed for global use with localized onboarding and compliance flows.  
Wallets can onboard users from over 100 countries.

\<br /\>

\# Getting Started

Get up and running with the Oobit Plug & Pay SDK in your React Native or Expo app

The Oobit React Native SDK allows you to embed the Oobit SDK in your mobile app, enabling crypto-to-card payment experiences for your users.

\#\# Installation

\`\`\`bash  
npm install @oobit/react-native-sdk  
\`\`\`

Or with yarn:

\`\`\`bash  
yarn add @oobit/react-native-sdk  
\`\`\`

\#\#\# Peer Dependencies

Install dependencies

\`\`\`bash  
npm install react-native-webview  
\`\`\`

\#\# Prerequisites

Before using the SDK, you need:

1\. \*\*Access Token\*\* \- A JWT token from your backend (\[learn more\](https://docs.oobit.com/docs/authentication))  
2\. \*\*User Wallet Address\*\* \- The user's crypto wallet address to deposit from  
3\. \*\*onTransactionRequested\*\* \- A callback function that navigates the user to a transaction confirmation screen

\#\# Basic Usage

\`\`\`tsx  
import { WidgetSDK } from "@oobit/react-native-sdk";

function MyScreen() {  
  return (  
    \<WidgetSDK  
      accessToken={accessToken}  
      userWalletAddress="0x1234567890abcdef..."  
      onTransactionRequested={(transaction) \=\> {  
        // Navigate to your transaction confirmation screen  
        navigation.navigate("ConfirmTransaction", { transaction });  
      }}  
    /\>  
  );  
}  
\`\`\`

\#\# Handling Events

The SDK provides callbacks for important events:

| Callback                 | Parameters                                                      | Required | Description                         |  
| \------------------------ | \--------------------------------------------------------------- | \-------- | \----------------------------------- |  
| \`onTransactionRequested\` | transaction: \[TransactionRequest\](https://docs.oobit.com/docs/types\#transactionrequest) | Yes      | User initiated a crypto transaction |  
| \`onClose\`                | \-                                                               | No       | User requested to close the widget  |

\#\# Full Example

\`\`\`tsx  
import React, { useRef, useState, useEffect } from "react";  
import { View, Alert, StyleSheet } from "react-native";  
import {  
  WidgetSDK,  
  WidgetSDKRef,  
  TransactionRequest,  
} from "@oobit/react-native-sdk";

export function WidgetScreen({ accessToken, walletAddress, onDismiss }) {  
  const handleTransactionRequested \= (transaction: TransactionRequest) \=\> {  
    const { symbol, amount } \= transaction.tokenMetadata;

    Alert.alert("Confirm Transaction", \`Send ${amount} ${symbol}?\`, \[  
      { text: "Cancel", style: "cancel" },  
      {  
        text: "Confirm",  
        onPress: () \=\> {  
          // Navigate to your signing flow  
          navigation.navigate("SignTransaction", { transaction });  
        },  
      },  
    \]);  
  };

  return (  
    \<View style={styles.container}\>  
      \<WidgetSDK  
        accessToken={accessToken}  
        userWalletAddress={walletAddress}  
        onTransactionRequested={handleTransactionRequested}  
        onClose={onDismiss}  
      /\>  
    \</View\>  
  );  
}

const styles \= StyleSheet.create({  
  container: {  
    flex: 1,  
  },  
});  
\`\`\`

\#\# Props Reference

| Prop                     | Type                                                                       | Required | Description                       |  
| \------------------------ | \-------------------------------------------------------------------------- | \-------- | \--------------------------------- |  
| \`accessToken\`            | \`string\`                                                                   | Yes      | JWT token from your backend       |  
| \`userWalletAddress\`      | \`string\`                                                                   | Yes      | User's crypto wallet address      |  
| \`onTransactionRequested\` | (transaction: \[TransactionRequest\](https://docs.oobit.com/docs/types\#transactionrequest) ) \=\> void | Yes      | Called when transaction requested |  
| \`onClose\`                | \`() \=\> void\`                                                               | No       | Called when widget closes         |

\#\# See Also

\* \[Component Reference\](https://docs.oobit.com/docs/component) \- Complete component documentation  
\* \[TypeScript Types\](https://docs.oobit.com/docs/types) \- All exported type definitions  
\* \[Handling Transactions\](https://docs.oobit.com/docs/transactions) \- Transaction handling guide

\<br /\>

\# Plug & Pay SDK Component

Complete API reference for the WidgetSDK component

The \`WidgetSDK\` component is the main entry point for embedding the Oobit Widget in your React Native application.

\#\# Import

\`\`\`tsx  
import { WidgetSDK } from "@oobit/react-native-sdk";  
\`\`\`

\#\# Basic Usage

\`\`\`tsx  
\<WidgetSDK  
  accessToken="your-jwt-token"  
  userWalletAddress="0x1234..."  
  onTransactionRequested={(transaction) \=\> {  
    // Navigate user to transaction confirmation screen  
    navigation.navigate('ConfirmTransaction', { transaction });  
  }}  
/\>  
\`\`\`

\*\*\*

\#\# Props

| Prop                     | Type                                        | Required | Description                                                                             |  
| \------------------------ | \------------------------------------------- | \-------- | \--------------------------------------------------------------------------------------- |  
| \`accessToken\`            | \`string\`                                    | Yes      | JWT token from your backend (\[Create Token API\](https://docs.oobit.com/docs/create-token))                      |  
| \`userWalletAddress\`      | \`string\`                                    | Yes      | User's crypto wallet address to deposit from                                            |  
| \`onTransactionRequested\` | \`(transaction: TransactionRequest) \=\> void\` | Yes      | Called when user initiates a transaction. See \[Handling Transactions\](https://docs.oobit.com/docs/transactions) |  
| \`onClose\`                | \`() \=\> void\`                                | No       | Called when user requests to close the widget                                           |

\> \*\*Security:\*\* Never generate tokens client-side. Always obtain them from your backend server.

\#\# Example

\`\`\`tsx  
\<WidgetSDK  
  accessToken={tokenFromBackend}  
  userWalletAddress="0x742d35Cc6634C0532925a3b844Bc9e7595f..."  
  onTransactionRequested={(transaction) \=\> {  
    const { symbol, amount } \= transaction.tokenMetadata;  
    navigation.navigate('ConfirmTransaction', { transaction });  
  }}  
  onClose={() \=\> navigation.goBack()}  
/\>  
\`\`\`

\*\*\*

\#\# See Also

\* \[TypeScript Types\](https://docs.oobit.com/docs/types) \- Complete type definitions  
\* \[Handling Transactions\](https://docs.oobit.com/docs/transactions) \- Transaction handling guide

\<br /\>

\# Authentication

Token lifecycle management and security best practices

The Plug & Pay SDK uses JWT tokens for authentication. This guide explains how tokens work and best practices for managing them in your application.

\#\# How Authentication Works

1\. Your mobile app requests a token from your backend  
2\. Your backend calls the \[Create Token API\](../docs/create-token) with your API credentials  
3\. Oobit returns a JWT token  
4\. Your backend forwards the token to your mobile app  
5\. Your app initializes the \`WidgetSDK\` with the token

\#\# Token Expiration

Tokens expire \*\*60 minutes after creation\*\*, regardless of user activity. When the token expires, the widget shows a 'Session Expired' modal with a button to return to the app.

\*\*\*

\#\# See Also

\* \[Create Token API\](../docs/create-token) \- API reference for token generation

\# Handling Transactions

Process crypto transaction requests from the widget

When the user initiates a crypto transaction, the SDK calls \`onTransactionRequested\` with a \[\`TransactionRequest\`\](https://docs.oobit.com/docs/types\#transactionrequest) object. Your app should navigate the user to a confirmation screen where they can review and approve the transaction.

\#\# The \`onTransactionRequested\` Callback

\`\`\`typescript React Native  
import { WidgetSDK, TransactionRequest } from '@oobit/react-native-sdk';

function WidgetScreen() {  
  const navigation \= useNavigation();

  const handleTransactionRequested \= (transaction: TransactionRequest) \=\> {  
    // Navigate to your transaction confirmation screen  
    navigation.navigate('TransactionConfirmation', { transaction });  
  };

  return (  
    \<WidgetSDK  
      accessToken={accessToken}  
      userWalletAddress={walletAddress}  
      onTransactionRequested={handleTransactionRequested}  
      onClose={() \=\> navigation.goBack()}  
    /\>  
  );  
}  
\`\`\`

\`\`\`typescript React Web  
import { WidgetSDK, TransactionRequest } from '@oobit/react-web';

function WidgetPage() {  
  const router \= useRouter();

  const handleTransactionRequested \= (transaction: TransactionRequest) \=\> {  
    // Navigate to your transaction confirmation screen  
    router.push({ pathname: '/confirm', query: { transaction } });  
  };

  return (  
    \<WidgetSDK  
      accessToken={accessToken}  
      userWalletAddress={walletAddress}  
      onTransactionRequested={handleTransactionRequested}  
      onClose={() \=\> router.back()}  
    /\>  
  );  
}  
\`\`\`

\*\*\*

\#\# TransactionRequest Type

The \[\`TransactionRequest\`\](https://docs.oobit.com/docs/types\#transactionrequest) is a union type that can be either an \*\*EVM\*\* or \*\*Solana\*\* transaction. Use the \`type\` field to discriminate between chains.

\`\`\`typescript  
type TransactionRequest \= EvmTransactionRequest | SolanaTransactionRequest;  
\`\`\`

\#\#\# Discriminating by Chain

\`\`\`typescript  
function handleTransaction(transaction: TransactionRequest) {  
  switch (transaction.type) {  
    case 'evm':  
      // Handle EVM transaction (Ethereum, Polygon, BSC, etc.)  
      handleEvmTransaction(transaction);  
      break;  
    case 'solana':  
      // Handle Solana transaction  
      handleSolanaTransaction(transaction);  
      break;  
  }  
}  
\`\`\`

\*\*\*

\#\# EVM Transactions

EVM transactions are used for Ethereum-compatible blockchains.

\`\`\`typescript  
interface EvmTransactionRequest {  
  type: 'evm';  
  chainId: number;  
  transaction: EvmTransactionData;  
  tokenMetadata: TransactionTokenMetadata;  
}

interface EvmTransactionData {  
  to: string;  
  data: string;  
  value: string;  
}  
\`\`\`

| Field               | Type                                                             | Description                                            |  
| \------------------- | \---------------------------------------------------------------- | \------------------------------------------------------ |  
| \`type\`              | \`'evm'\`                                                          | Identifies this as an EVM transaction                  |  
| \`chainId\`           | \`number\`                                                         | Network identifier (1 \= Ethereum, 137 \= Polygon, etc.) |  
| \`transaction.to\`    | \`string\`                                                         | Destination address                                    |  
| \`transaction.data\`  | \`string\`                                                         | Encoded transaction data (hex)                         |  
| \`transaction.value\` | \`string\`                                                         | Native token value in wei (hex)                        |  
| \`tokenMetadata\`     | \[\`TransactionTokenMetadata\`\](https://docs.oobit.com/docs/types\#transactiontokenmetadata) | Token info for display                                 |

\*\*\*

\#\# Solana Transactions

Solana transactions are used for the Solana blockchain.

\`\`\`typescript  
interface SolanaTransactionRequest {  
  type: 'solana';  
  transaction: string;  
  tokenMetadata: TransactionTokenMetadata;  
}  
\`\`\`

| Field           | Type                                                             | Description                             |  
| \--------------- | \---------------------------------------------------------------- | \--------------------------------------- |  
| \`type\`          | \`'solana'\`                                                       | Identifies this as a Solana transaction |  
| \`transaction\`   | \`string\`                                                         | Serialized transaction (base64 encoded) |  
| \`tokenMetadata\` | \[\`TransactionTokenMetadata\`\](https://docs.oobit.com/docs/types\#transactiontokenmetadata) | Token info for display                  |

\*\*\*

\#\# Token Metadata

Both transaction types include \[\`tokenMetadata\`\](https://docs.oobit.com/docs/types\#transactiontokenmetadata) for displaying transaction details to the user.

\`\`\`typescript  
interface TransactionTokenMetadata {  
  symbol: string;  
  amount: string;  
  decimals: number;  
}  
\`\`\`

| Field      | Type     | Description                               |  
| \---------- | \-------- | \----------------------------------------- |  
| \`symbol\`   | \`string\` | Token symbol (e.g., "USDC", "ETH", "SOL") |  
| \`amount\`   | \`string\` | Human-readable amount to send             |  
| \`decimals\` | \`number\` | Token decimal places                      |

\*\*\*

\#\# See Also

\* \[SDK Component Reference\](https://docs.oobit.com/docs/component) \- \`onTransactionRequested\` callback details  
\* \[TypeScript Types\](https://docs.oobit.com/docs/types) \- Complete type definitions

\<br /\>

\# TypeScript Types

Complete reference for all exported TypeScript types and interfaces

The SDK exports comprehensive TypeScript definitions for type-safe development. This page documents all exported types, interfaces, and constants.

\#\# Importing Types

\`\`\`typescript React Native  
import type {  
  WidgetSDKConfig,  
  WidgetSDKRef,  
  TransactionRequest,  
  EvmTransactionRequest,  
  SolanaTransactionRequest,  
  EvmTransactionData,  
  TransactionTokenMetadata,  
} from '@oobit/react-native-sdk';  
\`\`\`

\`\`\`typescript React Web  
import type {  
  WidgetSDKConfig,  
  WidgetSDKRef,  
  TransactionRequest,  
  EvmTransactionRequest,  
  SolanaTransactionRequest,  
  EvmTransactionData,  
  TransactionTokenMetadata,  
} from '@oobit/react-web';  
\`\`\`

\*\*\*

\#\# Core Types

\#\#\# \`WidgetSDKConfig\`

Configuration interface for the \`WidgetSDK\` component props.

\`\`\`typescript  
interface WidgetSDKConfig {  
  accessToken: string;  
  userWalletAddress: string;  
  onTransactionRequested: (transaction: TransactionRequest) \=\> void;  
  onClose?: () \=\> void;  
}  
\`\`\`

| Property                 | Type                                        | Required | Description                            |  
| \------------------------ | \------------------------------------------- | \-------- | \-------------------------------------- |  
| \`accessToken\`            | \`string\`                                    | Yes      | JWT access token from your backend     |  
| \`userWalletAddress\`      | \`string\`                                    | Yes      | User's wallet address for deposits     |  
| \`onTransactionRequested\` | \`(transaction: TransactionRequest) \=\> void\` | Yes      | Callback when transaction is requested |  
| \`onClose\`                | \`() \=\> void\`                                | No       | Callback when widget is closed         |

\*\*\*

\#\# Transaction Types

\#\#\# \`TransactionRequest\`

Union type representing a transaction request. Can be either EVM or Solana.

\`\`\`typescript  
type TransactionRequest \= EvmTransactionRequest | SolanaTransactionRequest;  
\`\`\`

Use the \`type\` field to discriminate between chains:

\`\`\`typescript  
function handleTransaction(tx: TransactionRequest) {  
  if (tx.type \=== 'evm') {  
    // Handle EVM transaction  
    console.log('Chain ID:', tx.chainId);  
  } else {  
    // Handle Solana transaction  
    console.log('Solana transaction');  
  }  
}  
\`\`\`

See \[Handling Transactions\](https://docs.oobit.com/docs/transactions) for detailed usage.

\*\*\*

\#\#\# \`EvmTransactionRequest\`

EVM-compatible blockchain transaction (Ethereum, Polygon, BSC, etc.).

\`\`\`typescript  
interface EvmTransactionRequest {  
  type: 'evm';  
  chainId: number;  
  transaction: EvmTransactionData;  
  tokenMetadata: TransactionTokenMetadata;  
}  
\`\`\`

| Property        | Type                                                    | Description                                            |  
| \--------------- | \------------------------------------------------------- | \------------------------------------------------------ |  
| \`type\`          | \`'evm'\`                                                 | Discriminator for EVM transactions                     |  
| \`chainId\`       | \`number\`                                                | Network identifier (1 \= Ethereum, 137 \= Polygon, etc.) |  
| \`transaction\`   | \[\`EvmTransactionData\`\](\#evmtransactiondata)             | Transaction data to be signed                          |  
| \`tokenMetadata\` | \[\`TransactionTokenMetadata\`\](\#transactiontokenmetadata) | Token info for display                                 |

\*\*\*

\#\#\# \`EvmTransactionData\`

Raw EVM transaction data.

\`\`\`typescript  
interface EvmTransactionData {  
  to: string;  
  data: string;  
  value: string;  
}  
\`\`\`

| Property | Type     | Description                     |  
| \-------- | \-------- | \------------------------------- |  
| \`to\`     | \`string\` | Destination address             |  
| \`data\`   | \`string\` | Encoded transaction data (hex)  |  
| \`value\`  | \`string\` | Native token value in wei (hex) |

\*\*\*

\#\#\# \`SolanaTransactionRequest\`

Solana blockchain transaction.

\`\`\`typescript  
interface SolanaTransactionRequest {  
  type: 'solana';  
  transaction: string;  
  tokenMetadata: TransactionTokenMetadata;  
}  
\`\`\`

| Property        | Type                                                    | Description                           |  
| \--------------- | \------------------------------------------------------- | \------------------------------------- |  
| \`type\`          | \`'solana'\`                                              | Discriminator for Solana transactions |  
| \`transaction\`   | \`string\`                                                | Serialized transaction (base64)       |  
| \`tokenMetadata\` | \[\`TransactionTokenMetadata\`\](\#transactiontokenmetadata) | Token info for display                |

\*\*\*

\#\#\# \`TransactionTokenMetadata\`

Token information for display purposes.

\`\`\`typescript  
interface TransactionTokenMetadata {  
  symbol: string;  
  amount: string;  
  decimals: number;  
}  
\`\`\`

| Property   | Type     | Description                        |  
| \---------- | \-------- | \---------------------------------- |  
| \`symbol\`   | \`string\` | Token symbol (e.g., "USDC", "ETH") |  
| \`amount\`   | \`string\` | Human-readable amount              |  
| \`decimals\` | \`number\` | Token decimal places               |

\*\*\*

\#\# See Also

\* \[Component Reference\](https://docs.oobit.com/docs/component) \- WidgetSDK component props  
\* \[Handling Transactions\](https://docs.oobit.com/docs/transactions) \- Transaction handling guide

\# Create Token

Generate an access token for the widget

\# Create Token

Generate a JWT access token for authenticating the widget.

\#\# Endpoint

\`\`\`  
POST {BASE\_URL}/v1/widget/auth/create-token  
\`\`\`

| Environment | Base URL                        |  
| \----------- | \------------------------------- |  
| Development | \`https://v2.dev-api-oobit.com\`  |  
| Production  | \`https://v2.prod-api-oobit.com\` |

\#\# Request

\#\#\# Headers

| Header      | Value        | Required |  
| \----------- | \------------ | \-------- |  
| \`x-api-key\` | Your API key | Yes      |

\#\#\# Example

\`\`\`bash  
curl \-X POST {BASE\_URL}/v1/widget/auth/create-token \\  
  \-H "x-api-key: your-api-key"  
\`\`\`

\#\# Response

\#\#\# Success (200 OK)

\`\`\`json  
{  
  "success": true,  
  "message": "Token created successfully",  
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",  
  "expiresAt": "2025-12-23T12:00:00.000Z"  
}  
\`\`\`

| Field       | Type    | Description                                                                |  
| \----------- | \------- | \-------------------------------------------------------------------------- |  
| \`success\`   | boolean | Indicates wether the token was created successfully                        |  
| \`message\`   | string  | Human-readable status message                                              |  
| \`token\`     | string  | JWT access token for the widget                                            |  
| \`expiresAt\` | string  | ISO 8601 timestamp indicating when the token expires and must be refreshed |

\#\#\# Error Responses

\#\#\#\# 401 Unauthorized

Invalid API key.

\`\`\`json  
{  
  "error": "Unauthorized",  
  "message": "Invalid API key"  
}  
\`\`\`

\#\#\#\# 403 Forbidden

Provider not authorized for this operation.

\`\`\`json  
{  
  "error": "Forbidden",  
  "message": "Provider not authorized"  
}  
\`\`\`

\#\#\#\# 429 Too Many Requests

Rate limit exceeded.

\`\`\`json  
{  
  "error": "Rate limit exceeded",  
  "message": "Too many requests. Please try again later.",  
}  
\`\`\`

\#\#\#\# 500 Internal Server Error

Server-side error.

\`\`\`json  
{  
  "error": "Internal server error",  
  "message": "An unexpected error occurred"  
}  
\`\`\`

\*\*\*

\#\# See Also

\* \[Authentication Guide\](../docs/authentication) \- Token lifecycle management

\# Supported Currencies

Supported cryptocurrencies and networks for production and development environments

This page lists all supported cryptocurrencies and their available networks. Use this reference to understand which assets you can integrate with the Widget.

\*\*\*

\#\# Production Currencies

The following cryptocurrencies are currently active and available for use in the production environment.

\#\#\# Supported Networks

| Network         | Native Currency | Type   |  
| \--------------- | \--------------- | \------ |  
| Ethereum        | ETH             | EVM    |  
| BNB Smart Chain | BNB             | EVM    |  
| Solana          | SOL             | SVM    |  
| Arbitrum        | ARB             | EVM L2 |  
| Avalanche       | AVAX            | EVM    |  
| Polygon         | \-               | EVM L2 |

\#\#\# Supported Tokens

| Token                 | Symbol | Networks                                   |  
| \--------------------- | \------ | \------------------------------------------ |  
| USDT                  | USDT   | Ethereum, BNB Smart Chain, Solana, Polygon |  
| USDC                  | USDC   | Ethereum, BNB Smart Chain, Solana, Polygon |  
| Chainlink             | LINK   | Ethereum                                   |  
| Dai                   | DAI    | Ethereum                                   |  
| Uniswap               | UNI    | Ethereum                                   |  
| Shiba Inu             | SHIB   | Ethereum                                   |  
| Maker                 | MKR    | Ethereum                                   |  
| The Graph             | GRT    | Ethereum                                   |  
| Compound              | COMP   | Ethereum                                   |  
| Sushi                 | SUSHI  | Ethereum                                   |  
| Synthetix             | SNX    | Ethereum                                   |  
| Basic Attention Token | BAT    | Ethereum                                   |  
| Chiliz                | CHZ    | Ethereum                                   |  
| Decentraland          | MANA   | Ethereum                                   |  
| Enjin Coin            | ENJ    | Ethereum                                   |  
| OMG Network           | OMG    | Ethereum                                   |  
| Tether Gold           | XAUT   | Ethereum                                   |  
| yearn.finance         | YFI    | Ethereum                                   |  
| EURC                  | EURC   | Ethereum                                   |  
| EURR                  | EURR   | Ethereum                                   |  
| USDR                  | USDR   | Ethereum                                   |  
| USAT                  | USAT   | Ethereum                                   |  
| Bonk                  | BONK   | Solana                                     |  
| OOB                   | OOB    | Solana                                     |  
| OFFICIAL TRUMP        | TRUMP  | Solana                                     |

\*\*\*

\#\# Development/Testnet Currencies

The following currencies are available in the development environment for testing. These use testnet contracts and have no real value.

\> \*\*Testing Deposits\*\*: You can mint testnet tokens to your wallet address to test the deposit flow. Click the contract address links below to interact with the token contracts on testnet block explorers.

\#\#\# Native Testnet Currencies

| Currency | Symbol | Network         | Testnet                                                                                                                         |  
| \-------- | \------ | \--------------- | \------------------------------------------------------------------------------------------------------------------------------- |  
| Ethereum | ETH    | Ethereum        | \<Anchor label="Sepolia Faucet" target="\_blank" href="https://sepoliafaucet.com"\>Sepolia Faucet\</Anchor\>                         |  
| BNB      | BNB    | BNB Smart Chain | \<Anchor label="BSC Testnet Faucet" target="\_blank" href="https://testnet.bnbchain.org/faucet-smart"\>BSC Testnet Faucet\</Anchor\> |  
| Solana   | SOL    | Solana          | \<Anchor label="Devnet Faucet" target="\_blank" href="https://faucet.solana.com"\>Devnet Faucet\</Anchor\>                           |

\#\#\# ERC-20 Testnet Tokens (Ethereum Sepolia)

| Currency | Symbol | Contract Address                                                                                                                                                                                                      |  
| \-------- | \------ | \--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |  
| USDC     | USDC   | \<Anchor label="0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238" target="\_blank" href="https://sepolia.etherscan.io/address/0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"\>0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238\</Anchor\> |  
| USDT     | USDT   | \<Anchor label="0x2F22064e87195D6D5aD22277FEDDFa2e2f59165F" target="\_blank" href="https://sepolia.etherscan.io/address/0x2F22064e87195D6D5aD22277FEDDFa2e2f59165F"\>0x2F22064e87195D6D5aD22277FEDDFa2e2f59165F\</Anchor\> |

\#\#\# BEP-20 Testnet Tokens (BNB Smart Chain Testnet)

| Currency | Symbol | Contract Address                                                                                                                                                                                                     |  
| \-------- | \------ | \-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |  
| USDT     | USDT   | \<Anchor label="0x337610d27c682E347C9cD60BD4b3b107C9d34dDd" target="\_blank" href="https://testnet.bscscan.com/address/0x337610d27c682E347C9cD60BD4b3b107C9d34dDd"\>0x337610d27c682E347C9cD60BD4b3b107C9d34dDd\</Anchor\> |

\#\#\# SPL Testnet Tokens (Solana Devnet)

| Currency | Symbol | Contract Address                                                                                                                                                                                                               |  
| \-------- | \------ | \------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |  
| USDC     | USDC   | \<Anchor label="Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr" target="\_blank" href="https://solscan.io/token/Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr?cluster=devnet"\>Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr\</Anchor\> |  
| USDT     | USDT   | \<Anchor label="EJwZgeZrdC8TXTQbQBoL6bfuAnFUUy1PVCMB4DYPzVaS" target="\_blank" href="https://solscan.io/token/EJwZgeZrdC8TXTQbQBoL6bfuAnFUUy1PVCMB4DYPzVaS?cluster=devnet"\>EJwZgeZrdC8TXTQbQBoL6bfuAnFUUy1PVCMB4DYPzVaS\</Anchor\> |

\*\*\*

\#\# Minting Testnet Tokens

To test the deposit flow with testnet tokens:

1\. \*\*Get testnet native currency first\*\* \- Visit the faucet links above to receive testnet ETH, SOL, or BNB for gas fees

2\. \*\*Connect your wallet to the testnet\*\* \- Configure your wallet to connect to the appropriate testnet network

3\. \*\*Mint or request tokens\*\* \- Click on the contract address links above to open the block explorer. Some tokens have a \`mint\` function you can call, while others require requesting from a faucet

4\. \*\*Initiate a test deposit\*\* \- Once you have testnet tokens, you can test the deposit flow through the Widget in development mode

\> \*\*Note\*\*: Testnet tokens have no monetary value and are only for testing purposes.  
