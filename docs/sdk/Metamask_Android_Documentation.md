\# Embedded Wallets SDK for Android

\#\# Overview​

MetaMask Embedded Wallets SDK (formerly Web3Auth Plug and Play) provides a seamless authentication experience for Android applications with social logins, external wallets, and more. Our Android SDK, written in Kotlin, simplifies how you connect users to their preferred wallets and manage authentication state natively.

\#\# Requirements​

\- Android API version \`24\` or newer  
\- Android Compile and Target SDK: \`34\`  
\- Basic knowledge of Java or Kotlin development

\#\# Prerequisites​

\- Set up your project on the \[Embedded Wallets dashboard\](https://dashboard.web3auth.io/).

See the \[dashboard setup\](https://docs.metamask.io/embedded-wallets/dashboard/) guide to learn more.

\#\# Installation​

Install the Web3Auth Android SDK by adding it to your project dependencies:

\#\#\# 1\. Add JitPack repository​

In your project-level Gradle file add JitPack repository:

\`\`\`  
dependencyResolutionManagement {  
    repositoriesMode.set(RepositoriesMode.FAIL\_ON\_PROJECT\_REPOS)  
    repositories {  
        google()  
        mavenCentral()  
        maven { url "https://jitpack.io" } // \<-- Add this line  
    }  
}

\`\`\`

\#\#\# 2\. Add Web3Auth dependency​

Then, in your app-level \`build.gradle\` dependencies section, add the following:

\`\`\`  
dependencies {  
    // ...  
    implementation 'com.github.web3auth:web3auth-android-sdk:9.1.2'  
}

\`\`\`

\#\#\# 1\. Update permissions​

Open your app's \`AndroidManifest.xml\` file and add the following permission. Ensure the \`\<uses-permission\>\` element is a direct child of the \`\<manifest\>\` root element.

\`\`\`  
\<uses-permission android:name="android.permission.INTERNET" /\>

\`\`\`

\#\#\# 2\. Configure AndroidManifest.xml File​

Ensure your main activity launchMode is set to \*\*singleTop\*\* in your \`AndroidManifest.xml\`:

\`\`\`  
\<activity  
  android:launchMode="singleTop"  
  android:name=".YourActivity"\>  
  // ...  
\</activity\>

\`\`\`

From version \*\*7.1.2\*\*, set \`android:allowBackup\` to \`false\` and add \`tools:replace="android:fullBackupContent"\` in your \`AndroidManifest.xml\` file:

\`\`\`  
\<application  
        android:allowBackup="false"  
        tools:replace="android:fullBackupContent"  
        android:dataExtractionRules="@xml/data\_extraction\_rules"  
        android:fullBackupContent="@xml/backup\_rules"  
        android:icon="@mipmap/ic\_launcher"\>  
\</application\>

\`\`\`

\#\#\# 3\. Handle redirects​

Once the gradles and permission has been updated, you need to configure your Embedded Wallets project by allowlisting your scheme and package name.

\#\#\#\# Configure a Plug n Play project​

\- From the \[Embedded Wallets dashboard\](https://dashboard.web3auth.io/), create or open an existing Web3Auth project.  
\- Allowlist \`{SCHEME}://{YOUR\_APP\_PACKAGE\_NAME}\` in the dashboard. This step is mandatory for the redirect to work.

\#\#\#\# Configure deep link​

Open your app's \`AndroidManifest.xml\` file and add the following deep link intent filter to your main activity:

\`\`\`  
\<intent-filter\>  
  \<action android:name="android.intent.action.VIEW" /\>

  \<category android:name="android.intent.category.DEFAULT" /\>  
  \<category android:name="android.intent.category.BROWSABLE" /\>

  \<data android:scheme="{scheme}" android:host="{YOUR\_APP\_PACKAGE\_NAME}"/\>  
  \<\!-- Accept URIs: w3a://com.example.w3aflutter \--\>  
\</intent-filter\>

\`\`\`

\#\#\# 4\. Triggering login exceptions​

The Android SDK uses the custom tabs and from current implementation of Chrome custom tab, it's not possible to add a listener directly to Chrome custom tab close button and trigger login exceptions.

Apply the \`setCustomTabsClosed\` method in your login screen to trigger login exceptions for Android.

\`\`\`  
class MainActivity : AppCompatActivity() {  
    // Additional code

    override fun onResume() {  
        super.onResume()  
        if (Web3Auth.getCustomTabsClosed()) {  
            Toast.makeText(this, "User closed the browser.", Toast.LENGTH\_SHORT).show()  
            web3Auth.setResultUrl(null)  
            Web3Auth.setCustomTabsClosed(false)  
        }  
    }

    // Additional code  
}

\`\`\`

\#\# Initialize Embedded Wallets​

\#\#\# 1\. Create an Embedded Wallets instance​

Create an Embedded Wallets instance and configure it with your project settings:

\`\`\`  
import com.web3auth.core.Web3Auth  
import com.web3auth.core.types.Web3AuthOptions

var web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
  )  
)

// Handle user signing in when app is in background  
web3Auth.setResultUrl(intent?.data)

\`\`\`

\#\#\# 2\. Set result URL​

Whenever user initiates a login flow, a new intent of CustomTabs is launched. It's necessary step to use \`setResultUrl\` in \`onNewIntent\` method to successful track the login process.

\`\`\`  
override fun onNewIntent(intent: Intent?) {  
  super.onNewIntent(intent)

  // Handle user signing in when app is active  
  web3Auth.setResultUrl(intent.data)  
}

\`\`\`

\#\#\# 3\. Initialize the Embedded Wallets instance​

After instantiating Embedded Wallets, the next step is to initialize it using the \`initialize\` method. This method is essential for setting up the SDK, checking for any active sessions, and fetching the whitelabel configuration from your dashboard.

Once the \`initialize\` method executes successfully, you can use the \`getPrivKey\` or \`getEd25519PrivKey\` methods to verify if an active session exists. If there is no active session, these methods will return an empty string; otherwise, they will return the respective private key.

If the API call to fetch the project configuration fails, the method will throw an error.

\`\`\`  
val initializeCF: CompletableFuture\<Void\> \= web3Auth.initialize()  
initializeCF.whenComplete { \_, error \-\>  
  if (error \== null) {  
    // Check for the active session  
    if(web3Auth.getPrivKey()isNotEmpty()) {  
      // Active session found  
    }  
    // No active session is not present

  } else {  
    // Handle the error  
  }  
}

\`\`\`

\#\# Advanced configuration​

The Web3Auth Android SDK offers a rich set of advanced configuration options:

\- \*\*Custom authentication:\*\* Define authentication methods.  
\- \*\*Whitelabeling and UI customization:\*\* Personalize the modal's appearance.  
\- \*\*Multi-Factor Authentication (MFA):\*\* Set up and manage MFA.  
\- \*\*Dapp Share:\*\* Share dapp sessions across devices.

See the \[advanced configuration sections\](https://docs.metamask.io/embedded-wallets/sdk/android/advanced/) to learn more about each configuration option.

\`\`\`  
val web3Auth \= Web3Auth(  
    Web3AuthOptions(  
        context \= this,  
        clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
        network \= Network.SAPPHIRE\_MAINNET, // or Network.SAPPHIRE\_DEVNET  
        redirectUrl \= "YOUR\_APP\_SCHEME://auth"  
    )  
)

\`\`\`

\#\# Blockchain integration​

Embedded Wallets is blockchain agnostic, enabling integration with any blockchain network. Out of the box, Embedded Wallets offers robust support for both \*\*Solana\*\* and \*\*Ethereum\*\*.

\#\#\# Ethereum integration​

For Ethereum integration, you can get the private key using the \`getPrivKey\` method and use it with web3j or other Ethereum libraries:

\`\`\`  
import org.web3j.crypto.Credentials  
import org.web3j.protocol.core.DefaultBlockParameterName  
import org.web3j.protocol.Web3j  
import org.web3j.protocol.http.HttpService

// Use your Web3Auth instance to get the private key  
val privateKey \= web3Auth.getPrivKey()

// Generate the Credentials  
val credentials \= Credentials.create(privateKey)

// Get the address  
val address \= credentials.address

// Create the Web3j instance using your RPC URL  
val web3 \= Web3j.build(HttpService("YOUR\_RPC\_URL"))

// Get the balance  
val balanceResponse \= web3.ethGetBalance(address, DefaultBlockParameterName.LATEST).send()

// Convert the balance from Wei to Ether format  
val ethBalance \= BigDecimal.valueOf(balanceResponse.balance.toDouble()).divide(BigDecimal.TEN.pow(18))

\`\`\`

\#\#\# Solana integration​

For Solana integration, you can get the Ed25519 private key using the \`getEd25519PrivKey\` method and use it with sol4k or any other Solana libraries:

\`\`\`  
import org.sol4k.Connection  
import org.sol4k.Keypair

val connection \= Connection(RpcUrl.DEVNET)

// Use your Web3Auth instance to get the private key  
val ed25519PrivateKey \= web3Auth.getEd25519PrivKey()

// Generate the Solana KeyPair  
val solanaKeyPair \= Keypair.fromSecretKey(ed25519PrivateKey.hexToByteArray())

// Get the user account  
val userAccount \= solanaKeyPair.publicKey.toBase58()

// Get the user balance  
val userBalance \= connection.getBalance(userAccount).toBigDecimal()

\`\`\`

\# Advanced Configuration

The Embedded Wallets SDK provides extensive configuration options that allow you to customize authentication flows, UI appearance, blockchain integrations, and security features to meet your application's specific requirements.

\#\# Configuration structure​

When setting up Embedded Wallets, you'll pass in the options to the constructor. This consists of:

\`\`\`  
import com.web3auth.core.Web3Auth  
import com.web3auth.core.types.Web3AuthOptions

var web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
  )  
)

// Handle user signing in when app is in background  
web3Auth.setResultUrl(intent?.data)

\`\`\`

\#\#\# Web3AuthOptions​

The Web3Auth Constructor takes an object with \`Web3AuthOptions\` as input.

| Parameter | Description |  
| \--- | \--- |  
| context | Android context to launch web-based authentication, usually is the current activity. It's a mandatory field, and accepts android.content.Context as a value. |  
| clientId | Your Embedded Wallets Client ID. You can get it from Embedded Wallets dashboard under project details. It's a mandatory field of type String |  
| network | Defines the Embedded Wallets Network. It's a mandatory field of type Network. |  
| redirectUrl | URL that Embedded Wallets will redirect API responses upon successful authentication from browser. It's a mandatory field of type Uri. |  
| sessionTime? | Allows developers to configure the session management time. Session time is in seconds, default is 86400 seconds which is 1 day. sessionTime can be max 30 days. |  
| useCoreKitKey? | Use CoreKit (or SFA) key to get core kit key given by SFA SDKs. It's an optional field with default value as false. Useful for Wallet Pregeneration. |  
| chainNamespace? | Chain Namespace \[EIP155 and SOLANA\]. It takes ChainNamespace as a value. |

\#\# Session management​

Control how long users stay authenticated and how sessions persist. The session key is stored in the device's encrypted Keystore.

\*\*Key Configuration Options:\*\*

\- \`sessionTime\` \- Session duration in seconds. Controls how long users remain authenticated before needing to log in again.

Minimum: 1 second (\`1\`).  
Maximum: 30 days (\`86400 \* 30\`).  
Default: 7 days (\`86400 \* 7\`).

\- Minimum: 1 second (\`1\`).  
\- Maximum: 30 days (\`86400 \* 30\`).  
\- Default: 7 days (\`86400 \* 7\`).

\`\`\`  
var web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    sessionTime \= 86400 \* 7, // 7 days (in seconds)  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
  )  
)

\`\`\`

\#\# Custom authentication methods​

Control the login options presented to your users. For detailed configuration options and implementation examples, see the \[custom authentication\](https://docs.metamask.io/embedded-wallets/sdk/android/advanced/custom-authentication/) section.

\#\# UI customization​

Create a seamless brand experience by customizing the Embedded Wallets login screens to match your application's design. For complete customization options, refer to the \[Whitelabeling & UI Customization\](https://docs.metamask.io/embedded-wallets/sdk/android/advanced/whitelabel/) section.

\#\# Multi-Factor Authentication​

Add additional security layers to protect user accounts with two-factor authentication. For detailed configuration options and implementation examples, see the \[Multi-Factor Authentication\](https://docs.metamask.io/embedded-wallets/sdk/android/advanced/mfa/) section.

\*\*Key Configuration Options:\*\*

\- \`mfaSettings\` \- Configure MFA settings for different authentication flows  
\- \`mfaLevel\` \- Control when users are prompted to set up MFA

\# Custom Authentication

Custom authentication is a way to authenticate users with your custom authentication service. For example, while authenticating with Google, you can use your own Google Client ID to authenticate users directly.

This feature, with Multi-Factor Authentication (MFA) turned off, can even make Embedded Wallets invisible to the end user.

This is a paid feature and the minimum \[pricing plan\](https://web3auth.io/pricing.html) to use this  
SDK in a production environment is the \*\*Growth Plan\*\*. You can use this feature in Web3Auth  
Sapphire Devnet network for free.

\#\# Getting an Auth Connection ID​

To enable this, you need to \[create a connection\](https://docs.metamask.io/embedded-wallets/dashboard/authentication/) from the \*\*Authentication\*\* tab of your project from the \[Embedded Wallets dashboard\](https://dashboard.web3auth.io/) with your desired configuration.

To configure a connection, you need to provide the particular details of the connection in the Embedded Wallets dashboard. This enables us to map a \`authConnectionId\` with your connection details. This \`authConnectionId\` helps us to identify the connection details while initializing the SDK. You can configure multiple connections for the same project, and you can also update the connection details anytime.

Learn more about the \[auth provider setup\](https://docs.metamask.io/embedded-wallets/authentication/) and the different configurations available for each connection.

\#\# Configuration​

\*\*"Auth Connection"\*\* is called \*\*"Verifier"\*\* in the Android SDK. It is the older terminology which we will be updating in the upcoming releases.

Consequentially, you will see the terms \*\*"Verifier ID"\*\* and \*\*"Aggregate Verifier"\*\* used in the codebase and documentation referring to \*\*"Auth Connection ID"\*\* and \*\*"Grouped Auth Connection"\*\* respectively.

To use custom authentication (using supported Social providers or Login providers like Auth0, AWS Cognito, Firebase, or your own custom JWT login), you can add the configuration using \`loginConfig\` parameter during the initialization.

The \`loginConfig\` parameter is a key value map. The key should be one of the \`Web3AuthProvider\` in its string form, and the value should be a \`LoginConfigItem\` instance.

After creating the verifier, you can use the following parameters in the \`LoginConfigItem\`.

| Parameter | Description |  
| \--- | \--- |  
| verifier | The name of the verifier that you have registered on the Embedded Wallets dashboard. It's a mandatory field, and it accepts a string value. |  
| typeOfLogin | Type of login of this verifier, this value will affect the login flow that is adapted. For example, if you choose google, a Google sign-in flow will be used. If you choose jwt, you should be providing your own JWT token, no sign-in flow will be presented. It's a mandatory field, and accepts TypeOfLogin as a value. |  
| clientId | Client ID provided by your login provider used for custom verifier. for example, Google's Client ID or Web3Auth's client ID if using JWT as TypeOfLogin. It's a mandatory field, and it accepts a string value. |  
| name? | Display name for the verifier. If null, the default name is used. It accepts a string value. |  
| description? | Description for the button. If provided, it renders as a full length button. else, icon button. It accepts a string value. |  
| verifierSubIdentifier? | The field in JWT token which maps to verifier ID. Please make sure you selected correct JWT verifier ID in the developer dashboard. It accepts a string value. |  
| logoHover? | Logo to be shown on mouse hover. It accepts a string value. |  
| logoLight? | Light logo for dark background. It accepts a string value. |  
| logoDark? | Dark logo for light background. It accepts a string value. |  
| mainOption? | Show login button on the main list. Is a boolean value. Default value is false. |  
| showOnModal? | Whether to show the login button on modal or not. Default value is true. |  
| showOnDesktop? | Whether to show the login button on desktop. Default value is true. |  
| showOnMobile? | Whether to show the login button on mobile. Default value is true. |

\#\#\# Usage​

\`\`\`  
import com.web3auth.core.Web3Auth  
import com.web3auth.core.types.Web3AuthOptions

val web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
    loginConfig \= hashMapOf("google" to LoginConfigItem(  
      verifier \= "verifier-name", // Get it from Web3Auth dashboard  
      typeOfLogin \= TypeOfLogin.GOOGLE,  
      clientId \= getString(R.string.google\_client\_id) // Google's client id  
    ))  
  )  
)

val loginCompletableFuture: CompletableFuture\<Web3AuthResponse\> \= web3Auth.login(  
    LoginParams(Provider.GOOGLE)  
)

\`\`\`

\#\# Configure extra login options​

Additional to the \`LoginConfig\` you can pass extra options to the \`login\` function to configure the login flow for cases requiring additional info for enabling login. The \`ExtraLoginOptions\` accepts the following parameters.

\#\#\# Parameters​

| Parameter | Description |  
| \--- | \--- |  
| additionalParams? | Additional params in HashMap format for OAuth login, use id\_token(JWT) to authenticate with web3auth. |  
| domain? | Your custom authentication domain in string format. For example, if you are using Auth0, it can be example.au.auth0.com. |  
| client\_id? | Client ID in string format, provided by your login provider used for custom verifier. |  
| leeway? | The value used to account for clock skew in JWT expirations. The value is in the seconds, and ideally should no more than 60 seconds or 120 seconds at max. It accepts a string value. |  
| verifierIdField? | The field in JWT token which maps to verifier ID. Please make sure you selected correct JWT verifier ID in the developer dashboard. It accepts a string value. |  
| isVerifierIdCaseSensitive? | Boolean to confirm whether the verifier ID field is case sensitive or not. |  
| display? | Allows developers the configure the display of UI. It takes Display as a value. |  
| prompt? | Prompt shown to the user during authentication process. It takes Prompt as a value. |  
| max\_age? | Max time allowed without reauthentication. If the last time user authenticated is greater than this value, then user must reauthenticate. It accepts a string value. |  
| ui\_locales? | The space separated list of language tags, ordered by preference. For instance fr-CA fr en. |  
| id\_token\_hint? | It denotes the previously issued ID token. It accepts a string value. |  
| id\_token? | JWT (ID token) to be passed for login. |  
| login\_hint? | Used to specify the user's email address or phone number for email/SMS passwordless login flows. It accepts a string value. For the SMS, the format should be: \+{country\_code}-{phone\_number} (for example \+1-1234567890) |  
| acr\_values? | acc\_values |  
| scope? | The default scope to be used on authentication requests. The defaultScope defined in the Auth0Client is included along with this scope. It accepts a string value. |  
| audience? | The audience, presented as the aud claim in the access token, defines the intended consumer of the token. It accepts a string value. |  
| connection? | The name of the connection configured for your application. If null, it will redirect to the Auth0 login page and show the login widget. It accepts a string value. |  
| state? | State |  
| response\_type? | Defines which grant to execute for the authorization server. It accepts a string value. |  
| nonce? | nonce |  
| redirect\_uri? | It can be used to specify the default URL, where your custom JWT verifier can redirect your browser to with the result. If you are using Auth0, it must be allowlisted in the allowed callback URLs in your Auth0's application. |

\#\#\# Single verifier Usage​

Auth0 has a special login flow, called the SPA flow. This flow requires a \`client\_id\` and \`domain\` to be passed, and Web3Auth will get the JWT \`id\_token\` from Auth0 directly. You can pass these configurations in the \`ExtraLoginOptions\` object in the login function.

\`\`\`  
import com.web3auth.core.Web3Auth  
import com.web3auth.core.types.Web3AuthOptions

val web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
    loginConfig \= hashMapOf("jwt" to LoginConfigItem(  
      verifier \= "verifier-name", // Get it from Web3Auth dashboard  
      typeOfLogin \= TypeOfLogin.JWT,  
      clientId \= getString (R.string.auth0\_project\_id) // Auth0's client id  
    ))  
  )  
)

val loginCompletableFuture: CompletableFuture\<Web3AuthResponse\> \= web3Auth.login(  
  LoginParams(  
    Provider.JWT,  
    extraLoginOptions \= ExtraLoginOptions(  
      domain: "https://username.us.auth0.com", // Domain of your Auth0 app  
      verifierIdField: "sub", // The field in jwt token which maps to verifier id.  
    )  
  )  
)

\`\`\`

\#\#\# Aggregate verifier Usage​

You can use aggregate verifier to combine multiple login methods to get the same address for the users regardless of their login providers. For example, combining a Google and email passwordless login, or Google and GitHub via Auth0 to access the same address for your user.

\`\`\`  
import com.web3auth.core.Web3Auth  
import com.web3auth.core.types.Web3AuthOptions

val web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
    loginConfig \= hashMapOf(  
      "google" to LoginConfigItem(  
        verifier \= "aggregate-sapphire",  
        verifierSubIdentifier= "w3a-google",  
        typeOfLogin \= TypeOfLogin.GOOGLE,  
        name \= "Aggregate Login",  
        clientId \= getString(R.string.web3auth\_google\_client\_id)  
      ),  
      "jwt" to LoginConfigItem(  
        verifier \= "aggregate-sapphire",  
        verifierSubIdentifier= "w3a-a0-email-passwordless",  
        typeOfLogin \= TypeOfLogin.JWT,  
        name \= "Aggregate Login",  
        clientId \= getString(R.string.web3auth\_auth0\_client\_id)  
      )  
    )  
  )  
)

// Google Login  
web3Auth.login(LoginParams(Provider.GOOGLE))

// Auth0 Login  
web3Auth.login(LoginParams(  
  Provider.JWT,  
  extraLoginOptions \= ExtraLoginOptions(  
    domain \= "https://web3auth.au.auth0.com",  
    verifierIdField \= "email",  
    isVerifierIdCaseSensitive \= false  
  )  
))

\`\`\`

\# Whitelabel

Embedded Wallets supports whitelabeling with application branding for a consistent user experience. You can customize three different aspects:

\- \*\*UI elements:\*\* Customize the appearance of modals and components  
\- \*\*Branding:\*\* Apply your brand colors, logos, and themes  
\- \*\*Translations:\*\* Localize the interface for your users

All of these settings can be easily managed directly from the Embedded Wallets dashboard. Once you update your branding, or UI preferences there, the changes will automatically apply to your integration.

This is a paid feature and the minimum \[pricing plan\](https://web3auth.io/pricing.html) to use this  
SDK in a production environment is the \*\*Growth Plan\*\*. You can use this feature in Web3Auth  
Sapphire Devnet network for free.

\#\# Customizing the Web3Auth login screens​

For defining custom UI, branding, and translations for your brand during Embedded Wallets instantiation, you just need to specify an additional parameter within the \`Web3AuthOptions\` object called \`whiteLabel\`. This parameter takes object called \`WhiteLabelData\`.

\#\#\# WhiteLabelData​

| Parameter | Description |  
| \--- | \--- |  
| appName? | Display name for the app in the UI. |  
| logoLight? | App logo to be used in dark mode. It accepts URL as a string. |  
| logoDark? | App logo to be used in light mode. It accepts URL as a string. |  
| defaultLanguage? | Language which will be used by Web3Auth, app will use browser language if not specified. Default language is Language.EN. Checkout Language for supported languages. |  
| mode? | Theme mode for the login modal. Choose between ThemeModes.AUTO, ThemeModes.LIGHT or ThemeModes.DARK background modes. Default value is ThemeModes.AUTO. |  
| theme? | Used to customize the theme of the login modal. It accepts HashMap as a value. |  
| appUrl? | URL to be used in the modal. It accepts URL as a string. |  
| useLogoLoader? | Use logo loader. If logoDark and logoLight are null, the default Web3Auth logo will be used for the loader. Default value is false. |

\#\#\# name​

The name of the application. This will be displayed in the key reconstruction page.

\#\#\#\# Standard screen without any change

Standard screen \*\*without\*\* any change

\#\#\#\# Name changed to Formidable Duo

Name changed to \`Formidable Duo\`

\#\#\# logoLight & logoDark​

The logo of the application. Displayed in dark and light mode respectively. This will be displayed  
in the key reconstruction page.

\#\#\#\# logoLight on dark mode

\`logoLight\` on dark mode

\#\#\#\# logoDark on light mode

\`logoDark\` on light mode

\#\#\# defaultLanguage​

Default language will set the language used on all OpenLogin screens. The supported languages are:

\- \`en\` \- English (default)  
\- \`de\` \- German  
\- \`ja\` \- Japanese  
\- \`ko\` \- Korean  
\- \`zh\` \- Mandarin  
\- \`es\` \- Spanish  
\- \`fr\` \- French  
\- \`pt\` \- Portuguese  
\- \`nl\` \- Dutch  
\- \`tr\` \- Turkish

\#\#\# dark​

Can be set to \`true\` or \`false\` with default set to \`false\`.

\#\#\#\# For Light: dark: false

For Light: \`dark: false\`

\#\#\#\# For Dark: dark: true

For Dark: \`dark: true\`

\#\#\# theme​

Theme is a record of colors that can be configured. As of, now only \`primary\` color can be set and  
has effect on OpenLogin screens (default primary color is \`\#0364FF\`). Theme affects icons and links.  
Examples below.

\#\#\#\# Standard color \#0364FF

Standard color \`\#0364FF\`

\#\#\#\# Color changed to \#D72F7A

Color changed to \`\#D72F7A\`

\#\#\# Example​

\`\`\`  
web3Auth \= Web3Auth (  
  Web3AuthOptions (  
    context \= this,  
    clientId \= getString (R.string.web3auth\_project\_id),  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse ("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
    // Optional whitelabel object  
    whiteLabel \= WhiteLabelData (  
      appName \= "Web3Auth Sample App",  
      appUrl \= null,  
      logoLight \= null,  
      logoDark \= null,  
      defaultLanguage \= Language.EN, // EN, DE, JA, KO, ZH, ES, FR, PT, NL  
      ThemeModes \= ThemeModes.DARK, // LIGHT, DARK, AUTO  
      useLogoLoader \= true,  
      theme \= hashMapOf (  
        "primary" to "\#229954"  
      )  
    )  
  )  
)

\`\`\`

\# Using Android SDK

Embedded Wallets provides a comprehensive set of functions to handle authentication, user management, and blockchain interactions in your Android applications. These functions allow you to implement features like user login, Multi-Factor Authentication (MFA), private key retrieval, and Wallet Services with minimal effort. Each function is designed to handle a specific aspect of Embedded Wallets' functionality, making it easy to integrate into your Android projects.

\#\# List of functions​

For detailed usage, configuration options, and code examples, refer to the dedicated documentation page for each function.

\#\#\# Authentication functions​

| Function Name | Description |  
| \--- | \--- |  
| login() | Logs in the user with the selected login provider. |  
| logout() | Logs out the user from the current session. |

\#\#\# User management functions​

| Function Name | Description |  
| \--- | \--- |  
| getUserInfo() | Retrieves the authenticated user's information. |

\#\#\# Private key functions​

| Function Name | Description |  
| \--- | \--- |  
| getPrivKey() | Retrieve the user's secp256k1 private key for EVM-compatible chains. |  
| getEd25519PrivKey() | Retrieve the user's ed25519 private key for chains like Solana, Near, Algorand. |

\#\#\# Security functions​

| Function Name | Description |  
| \--- | \--- |  
| enableMFA() | Enables MFA for the user. |  
| manageMFA() | Allows users to manage their MFA settings. |

\#\#\# Wallet Services functions​

| Function Name | Description |  
| \--- | \--- |  
| launchWalletServices() | Launches the templated wallet UI in WebView. |  
| request() | Opens templated transaction screens for signing EVM transactions. |

\# Logging in a User

To login in a user, you can use the \`login\` method. It will trigger login flow will navigate the user to a browser model allowing the user to login into the service. You can pass in the supported providers to the login method for specific social logins (such as GOOGLE, APPLE, FACEBOOK) and do whitelabel login.

\#\# Parameters​

The \`login\` method takes in \`LoginParams\` as a required input.

| Parameter | Description |  
| \--- | \--- |  
| loginProvider | It sets the OAuth login method to be used. You can use any of the supported values are GOOGLE, FACEBOOK, REDDIT, DISCORD, TWITCH, APPLE, LINE, GITHUB, KAKAO, LINKEDIN, TWITTER, WEIBO, WECHAT, EMAIL\_PASSWORDLESS, JWT, SMS\_PASSWORDLESS, and FARCASTER. |  
| extraLoginOptions? | It can be used to set the OAuth login options for corresponding loginProvider. For instance, you'll need to pass user's email address as. Default value for the field is null, and it accepts ExtraLoginOptions as a value. |  
| redirectUrl? | URL where user will be redirected after successfull login. By default user will be redirected to same page where login will be initiated. Default value for the field is null, and accepts Uri as a value. |  
| appState? | It can be used to keep track of the app state when user will be redirected to app after login. Default is null, and accepts a string value. |  
| mfaLevel? | Customize the MFA screen shown to the user during OAuth authentication. Default value for field is MFALevel.DEFAULT, which shows MFA screen every 3rd login. It accepts MFALevel as a value. |  
| dappShare? | Custom verifier logins can get a dapp share returned to them post successful login. This is useful if the dapps want to use this share to allow users to login seamlessly. It accepts a string value. |  
| curve? | It will be used to determine the public key encoded in the JWT token which returned in getUserInfo function after user login. This parameter won't change format of private key returned by We3Auth. Private key returned by getPrivKey is always secp256k1. To get the ed25519 key you can use getEd25519PrivKey method. The default value is Curve.SECP256K1. |

\#\# Usage​

\`\`\`  
import com.web3auth.core.Web3Auth  
import com.web3auth.core.types.Web3AuthOptions

val web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
  )  
)

val loginCompletableFuture: CompletableFuture\<Web3AuthResponse\> \= web3Auth.login(  
    LoginParams(Provider.GOOGLE)  
)

\`\`\`

\#\# Examples​

\`\`\`  
import com.web3auth.core.Web3Auth  
import com.web3auth.core.types.Web3AuthOptions

val web3Auth \= Web3Auth(  
  Web3AuthOptions(  
    context \= this,  
    clientId \= "YOUR\_WEB3AUTH\_CLIENT\_ID", // Pass your Web3Auth Client ID, ideally using an environment variable  
    network \= Network.MAINNET,  
    redirectUrl \= Uri.parse("{YOUR\_APP\_PACKAGE\_NAME}://auth"),  
  )  
)

val loginCompletableFuture: CompletableFuture\<Web3AuthResponse\> \= web3Auth.login(  
    LoginParams(Provider.GOOGLE)  
)

\`\`\`

\# Retrieve User Information

You can use the \`getUserInfo\` method to retrieve various details about the user, such as their login type, whether multi-factor authentication (MFA) is enabled, profile image, name, and other relevant information.

\#\# Usage​

\`\`\`  
val userInfo \= web3Auth.getUserInfo()

\`\`\`

\#\# UserInfo response​

\`\`\`  
{  
  "userInfo": {  
    "email": "w3a-heroes@web3auth.com",  
    "name": "Web3Auth Heroes",  
    "profileImage": "https://lh3.googleusercontent.com/a/Ajjjsdsmdjmnm...",  
    "verifier": "torus",  
    "verifierId": "w3a-heroes@web3auth.com",  
    "typeOfLogin": "google",  
    "aggregateVerifier": "w3a-google-sapphire",  
    "dappShare": "", // 24 words of seed phrase will be sent only incase of custom verifiers  
    "idToken": "\<jwtToken issued by Web3Auth\>",  
    "oAuthIdToken": "\<jwtToken issued by OAuth provider\>", // will be sent only incase of custom verifiers  
    "oAuthAccessToken": "\<accessToken issued by OAuth Provider\>", // will be sent only incase of custom verifiers  
    "isMfaEnabled": false // Returns whether the user has enabled MFA or not  
  }  
}

\`\`\`

\# Secp256k1 Private Key

To retrieve the secp256k1 private key of the user., use \`getPrivkey\` method. The method returns an EVM compatible private key which can be used to sign transactions on EVM compatible chains.

\#\# Usage​

\`\`\`  
val privateKey \= web3Auth.getPrivKey()

\`\`\`

Web3Auth supports two widely used cryptographic curves, Secp256k1 and Ed25519, making it chain-agnostic and compatible with multiple blockchain networks. \[Learn more about how to connect different blockchains\](https://docs.metamask.io/embedded-wallets/connect-blockchain/).

\# Ed25519 Private Key

To retrieve the secp256k1 private key of the user., use \`getEd25519PrivKey\` method. This private key can be used to sign transactions on Solana, Near, Algorand, and other chains that use the ed25519 curve.

\#\# Usage​

\`\`\`  
val privateKey \= web3Auth.getEd25519PrivKey()

\`\`\`

Web3Auth supports two widely used cryptographic curves, Secp256k1 and Ed25519, making it chain-agnostic and compatible with multiple blockchain networks. \[Learn more about how to connect different blockchains\](https://docs.metamask.io/embedded-wallets/connect-blockchain/).

\# Logging out a User

Logging out your user is as simple as calling the \`logout\` method. This method will clear the session data and the user will be logged out from Web3Auth.

\#\# Usage​

\`\`\`  
val logoutCompletableFuture \= web3Auth.logout()

\`\`\`

\# Enable MFA for a User

The \`enableMFA\` method is used to trigger MFA setup flow for users. The method takes \`LoginParams\` which will used during custom verifiers. If you are using default login providers, you don't need to pass \`LoginParams\`. If you are using custom JWT verifiers, you need to pass the JWT token in \`loginParams\` as well.

\#\# Usage​

\`\`\`  
import android.widget.Button  
import com.web3auth.core.Web3Auth  
import android.os.Bundle

class MainActivity : AppCompatActivity() {  
    private lateinit var web3Auth: Web3Auth

     private fun enableMFA() {  
       val completableFuture \= web3Auth.enableMFA()

        completableFuture.whenComplete{\_, error \-\>  
            if (error \== null) {  
                Log.d("MainActivity\_Web3Auth", "Launched successfully")  
                // Add your logic  
            } else {  
                // Add your logic on error  
                Log.d("MainActivity\_Web3Auth", error.message ?: "Something went wrong")  
            }  
        }  
    }

    override fun onCreate(savedInstanceState: Bundle?) {  
        ...  
        // Setup UI and event handlers  
        val enableMFAButton \= findViewById\<Button\>(R.id.enableMFAButton)  
        enableMFAButton.setOnClickListener { enableMFA() }  
        ...  
    }  
    ...  
}

\`\`\`

\# Manage MFA for a User

The \`manageMFA\` method is used to trigger manage MFA flow for users, allowing users to update their MFA settings. The method takes \`LoginParams\` which will used during custom verifiers. If you are using default login providers, you don't need to pass \`LoginParams\`. If you are using custom JWT verifiers, you need to pass the JWT token in \`loginParams\` as well.

\#\# Usage​

\`\`\`  
val manageMFACF \= web3Auth.manageMFA()

manageMFACF.whenComplete{\_, error \-\>  
  if (error \== null) {  
     // Handle success  
  } else {  
     // Handle error  
  }  
}

\`\`\`

\# Launch Wallet Services

The \`launchWalletServices\` method launches a WebView which allows you to use the templated wallet UI services. The method takes\`ChainConfig\` as the required input. Wallet Services is currently only available for EVM chains.

Access to Wallet Services is gated. You can use this feature in \`sapphire\_devnet\` for free. The minimum \[pricing plan\](https://web3auth.io/pricing.html) to use this feature in a production environment is the \*\*Scale Plan\*\*.

\#\# Parameters​

| Parameter | Description |  
| \--- | \--- |  
| chainNamespace | Custom configuration for your preferred blockchain. As of now only EVM supported. Default value is ChainNamespace.EIP155. |  
| decimals? | Number of decimals for the currency ticker. Default value is 18, and accepts Int as value. |  
| blockExplorerUrl? | Blockchain's explorer URL. (for example, https://etherscan.io) |  
| chainId | The chain ID of the selected blockchain in hex String. |  
| displayName? | Display Name for the chain. |  
| logo? | Logo for the selected chainNamespace and chainId. |  
| rpcTarget | RPC Target URL for the selected chainNamespace & chainId. |  
| ticker? | Default currency ticker of the network (for example, ETH) |  
| tickerName? | Name for currency ticker (for example, Ethereum) |

\#\# Usage​

\`\`\`  
val chainConfig \= ChainConfig(  
    chainId \= "0x1",  
    rpcTarget \= "https://rpc.ethereum.org",  
    ticker \= "ETH",  
    chainNamespace \= ChainNamespace.EIP155  
)

val completableFuture \= web3Auth.launchWalletServices(  
    chainConfig  
)

\`\`\`

\# Request Signature

The \`request\` method facilitates the use of templated transaction screens for signing transactions. The method will return \[SignResponse\](https://docs.metamask.io/embedded-wallets/sdk/android/usage/request/\#signresponse). It can be used to sign transactions for any EVM chain and screens can be whitelabeled to your branding.

Please check the list of \[JSON RPC methods\](https://docs.metamask.io/wallet/reference/json-rpc-api/), noting that the request method currently supports only the signing methods.

\#\# Parameters​

| Parameter | Description |  
| \--- | \--- |  
| chainConifg | Defines the chain to be used for signature request. |  
| method | JSON RPC method name in String. Currently, the request method only supports the singing methods. |  
| requestParams | Parameters for the corresponding method. The parameters should be in the list and correct sequence. Take a look at RPC methods to know more. |

\#\# Usage​

\`\`\`  
val params \= JsonArray().apply {  
    // Message to be signed  
    add("Hello, World\!")  
    // User's EOA address  
    add(address)  
}

val chainConfig \= ChainConfig(  
    chainId \= "0x1",  
    rpcTarget \= "https://rpc.ethereum.org",  
    ticker \= "ETH",  
    chainNamespace \= ChainNamespace.EIP155  
)

val signMsgCompletableFuture \= web3Auth.request(  
    chainConfig \= chainConfig,  
    "personal\_sign",  
    requestParams \= params  
)

signMsgCompletableFuture.whenComplete { signResult, error \-\>  
    if (error \== null) {  
        Log.d("Sign Result", signResult.toString())

    } else {  
        Log.d("Sign Error", error.message ?: "Something went wrong")  
    }  
}

\`\`\`

\#\# SignResponse​

| Name | Description |  
| \--- | \--- |  
| success | Determines whether the request was successful or not. |  
| result? | Holds the signature for the request when success is true. |  
| error? | Holds the error for the request when success is false. |

\# Troubleshooting with MetaMask Embedded Wallets

MetaMask Embedded Wallets (formerly Web3Auth) offers SDKs for various libraries across multiple platforms and devices. Thanks to our vibrant community of developers and their various implementations, we have collated some of the top-asked questions as guides to help you understand and figure out some edge cases in the implementations.

If you're still facing errors, you can always ask for help via the following channels:

\- Browse our \[Embedded Wallets Community\](https://builder.metamask.io/c/embedded-wallets/5) to see if anyone has any questions or issues you might be having.  
\- Join our \[Discord\](https://discord.gg/consensys) community and get private integration support or help with your integration.

\#\#\# Explore solutions to common challenges.

\#\#\# Polyfill issues with different bundlers

\# Different private keys/wallet address across integrations

Developers and users frequently face confusion when they get different wallet addresses for multitudes of reasons. This page details possible reasons for different wallet addresses and what to keep in mind while designing your solutions.

\#\# Custom connections​

A custom connection configures the OAuth/OpenID provider that issues the JWT your app uses for login. The Embedded Wallets (Web3Auth) network validates this provider configuration onchain and then verifies the issued JWT.

→ Learn more about creating custom connections, see \[authentication\](https://docs.metamask.io/embedded-wallets/authentication/).

Using the same custom connection configuration across SDKs results in the same wallet address, because wallet derivation depends on the connection and user identity—not the SDK.

You might face errors where users login with different methods (like Google login and email passwordless)—resulting in different wallet addresses/keys. This is because, when you use different login providers, connection details change, even though the ID, sub, email, and other properties remain the same. To control for such cases, use a \*\*group connection\*\*.

\#\#\# Group connections​

A group connection combines multiple login methods to create a single connection so the same wallet address is derived for the same email ID regardless of the login provider, for example, combining Google and email passwordless or Google and GitHub via Auth0 to access the same key for your user.

→ Learn more about \[creating a group connection\](https://docs.metamask.io/embedded-wallets/authentication/group-connections/).

With a group connection, multiple sub-connections are combined and one wallet address is generated. This allows connections with different login providers to be added as sub-connections under one group connection, which allows users to get a single wallet address provided one of the fields (like email) stays the same across all sub-connections.

\#\# Client ID​

To get your client ID, set up a project on the \[Embedded Wallets Dashboard\](https://dashboard.web3auth.io/). A "project" describes the pre-packaged user interface and experience that Embedded Wallets supports you with. The dashboard enables easy and efficient integration with your project, saving you the hassle of building everything from scratch.

→ Learn how to \[create a project and claim your client ID\](https://docs.metamask.io/embedded-wallets/dashboard/).

Wallet addresses change if the client ID changes. Please use the same client ID across all your SDK integrations to standardize the wallet addresses retrieved.

\#\# Environment​

While creating a connection you need to select between \`sapphire\_devnet\`, and \`sapphire\_mainnet\`.

\`sapphire\_devnet\` is a sandbox environment for developers to experiment with. People usually test and finalize their integration here. \`sapphire\_mainnet\` is the production environment for scalable applications.

Every network has different \[nodes\](https://docs.metamask.io/embedded-wallets/infrastructure/nodes-and-dkg/) that issue different keys, this means the wallet addresses changes if you move from one network to another.

\#\# Product​

Different SDKs can derive keys using different inputs and derivation paths. To keep addresses consistent across implementations:

\- Use the same custom connection configuration across platforms  
\- Use the same client ID across integrations  
\- Keep the environment consistent: dev (devnet) vs. prod (mainnet)

\#\#\# Migrating between SDKs​

Whether you're optimizing user flows or trying new features, plan migrations with care to ensure a seamless experience.

Migrations might involve changing wallets, which can lead to loss of access if not handled with care. Ensure all prerequisites are met before migrating and communicate changes clearly to users.

\# JWT errors

To ensure proper authentication with Embedded Wallets, the JWT header must provide the \`kid\` field, while the payload data must provide the \`iat\` field.

When configuring Embedded Wallet's custom authentication, you may encounter JWT errors. Below is a list of these errors and the necessary steps to resolve them:

\- \[Invalid JWT verifiers ID field\](https://docs.metamask.io/embedded-wallets/troubleshooting/jwt-errors/\#invalid-jwt-verifiers-id-field): Error occurred while verifying params could not verify identity  
\- \[Failed to verify JWS signature\](https://docs.metamask.io/embedded-wallets/troubleshooting/jwt-errors/\#failed-to-verify-jws-signature): Error occurred while verifying params unable to verify JWT token  
\- \[Duplicate token\](https://docs.metamask.io/embedded-wallets/troubleshooting/jwt-errors/\#duplicate-token): Could not get result from \[Torus nodes\](https://docs.metamask.io/embedded-wallets/infrastructure/nodes-and-dkg/), duplicate token found  
\- \[Expired token\](https://docs.metamask.io/embedded-wallets/troubleshooting/jwt-errors/\#expired-token): Error occurred while verifying the parameter's time signed is more than 1m0s ago  
\- \[Mismatch JWT Validation field\](https://docs.metamask.io/embedded-wallets/troubleshooting/jwt-errors/\#mismatch-jwt-validation-field)  
\- \[Refresh Tokens?\](https://docs.metamask.io/embedded-wallets/troubleshooting/jwt-errors/\#refresh-tokens-not-supported)

\#\# Invalid JWT verifiers ID field​

\#\#\# Error occurred while verifying params could not verify identity​

"Error occurred while verifying params could not verify identity" can arise when the \`verifierIdField\` of \`extraLoginOptions\` is different from the one you have set up during the creation of Verifiers (\`JWT Verifiers ID\`) on the Embedded Wallets dashboard.

This is the \`JWT Verifiers ID\` field on the \`Verifier Modal\` of the Embedded Wallets dashboard:

Ensure, this matches your code:

\`\`\`  
import { WALLET\_ADAPTERS, CHAIN\_NAMESPACES } from '@web3auth/base'

await web3auth.connectTo(WALLET\_ADAPTERS.AUTH, {  
  loginProvider: 'jwt',  
  extraLoginOptions: {  
    domain: 'YOUR-AUTH0-DOMAIN',  
    verifierIdField: 'sub', // \<-- This is the JWT Verifiers ID field.  
    response\_type: 'token',  
    scope: 'email profile openid',  
  },  
})

\`\`\`

\#\# Failed to verify JWS signature​

\#\#\# Error occurred while verifying params unable to verify JWT token​

"Error occurred while verifying params unable to verify jwt token" could arise because of the following reasons:

\- The verifier for your AuthAdapter might be wrong. Check to ensure the \`verifier\` field is set correctly.  
\- The JWT is not signed with the correct key (JWK).  
\- The JWKS endpoint is not reachable or doesn't return a valid JWK that was used to sign the JWT.  
\- The JWKS endpoint is incorrect on the Embedded Wallets dashboard. Double check to confirm the correct JWKS endpoint.  
\- The JWKS is missing the \`kid\` field.  
\- The \`kid\` present in the JWT header is not present in the JWKS.

Embedded Wallets (Web3Auth) uses the JWKS to:

\- Fetch the provider’s public keys  
\- Find the correct key using the JWT’s \`kid\`  
\- Verify the JWT’s signature

\`sample jwks\`:

\`\`\`  
{  
  "keys": \[  
    {  
      "kty": "RSA",  
      "e": "AQAB",  
      "use": "sig",  
      "kid": "YOUR-KID", // \<-- This is the kid.  
      "n": "YOUR-N",  
      "alg": "RS256" // \<-- This is the algorithm.  
    }  
  \]  
}

\`\`\`

\`sample jwks endpoint\`: \[https://www.googleapis.com/oauth2/v3/certs\](https://www.googleapis.com/oauth2/v3/certs)

\#\# Duplicate token​

\#\#\# Could not get result from Torus nodes duplicate token found​

"Could not get result from torus nodes Duplicate token found" error is thrown when the JWT is sent twice in the same request.

\`\`\`  
await web3auth.connectTo(WALLET\_ADAPTERS.AUTH, {  
  loginProvider: 'jwt',  
  extraLoginOptions: {  
    id\_token: 'ID\_TOKEN', // \<-- JWT should be unique for each request.  
    verifierIdField: 'sub',  
  },  
})

\`\`\`

\#\# Expired token​

\#\#\# Error occurred while verifying paramstimesigned is more than 1m0s ago​

Embedded Wallets accepts only those JWTs whose \`iat\` is less than the current time and is not greater than \`60s\` from current time. Regardless of the \`exp\` field of the JWT.

\- In short, the JWT is considered expired if the \`iat\` is greater than 60 s from current time.

"Error occurred while verifying paramstimesigned is more than 1m0s ago 2022-02-24 13:46:05 \+0000 UTC" error could be because:

\- JWT is expired  
\- The JWT's \`exp\` field is less than the current time  
\- The JWT's \`iat\` field is greater than \`60s\` from current time

\#\# Mismatch JWT validation field​

This error occurred when the validation field in the JWT is not matching with the validation field entered during the creation of Verifiers on the Embedded Wallets dashboard.

This is the \`JWT Validation\` field on the \`Verifier Modal\` of the Embedded Wallets configuration:

Ensure, these fields are present in the JWT Payload and match with the JWT.

\#\# Refresh tokens not supported​

Embedded Wallets does not support refresh tokens to maintain longer sessions, instead we offer \[session management\](https://docs.metamask.io/embedded-wallets/dashboard/advanced/session-management/).

During login with Embedded Wallets, pass the \`sessionTime\` parameter. This allows users to stay authenticated with Embedded Wallets for up to 1 day by default or a maximum of 30 days until they log out or their session data is cleared.

A refresh token is a unique token that can be used to obtain additional access tokens from an Authentication Service Provider. With a refresh token, one can get a new \`id\_token\` to make another login request. This enables users to maintain longer authentication sessions without the need for constant re-login.

While Embedded Wallets, verifies the validity of the \`id\_token\` and compares its payload value to the JWKS provided by either the Auth provider or your custom JWKS, it does not support refresh. Although we do not support refresh tokens to maintain longer sessions, we do offer session management. Session management supports  
dapps to check and maintain existing sessions with Embedded Wallets.

\# Bundler polyfill issues \- React Native Metro

While setting up a new Web3 project from scratch, you might face bundler issues. This can occur because the  
core packages like \`eccrypto\` have dependencies which are not present within the build environment.

To rectify this, the go-to method is to add the missing modules directly into the package, and edit the bundler  
configuration to use those. Although this approach works, it can significantly increase bundle size, leading  
to slower load times and a degraded user experience.

Some libraries rely on environment-specific modules that may be available at runtime in the browser even if  
they are not bundled. Libraries such as Embedded Wallets’ Web3Auth take advantage of this behavior and can  
function correctly without bundling all modules. However, if you are using a library that does not take  
advantage of this, you might face issues.

To avoid unnecessary overhead, include only the required polyfills, test functionality with care, and  
configure your bundler to ignore unresolved modules rather than including them in the final build.

We recommend that you require certain Node polyfills to be added to your project, while testing each of  
its functionalities. At the same time, instruct the bundler to ignore the missing modules, and not include  
them in the build.

In this guide, we provide instructions for adding polyfills in React Native Metro. The steps install the  
missing libraries required for module resolution and then configures Metro so they are not bundled unless  
needed at runtime.

\#\# Step 1: Install the missing modules​

Check for the missing libraries in your build and included packages, and polyfill these. For Web3Auth, you  
need to polyfill the \`buffer\`, \`process\`, \`crypto\` and \`stream\` libraries. For the rest of the libraries,  
we are installing a dummy module called \`empty-module\` which helps us get rid of the warnings while building  
the project.

\`\`\`  
npm install \--save empty-module readable-stream crypto-browserify react-native-get-random-values buffer process

\`\`\`

If you're using any other blockchain library alongside Web3Auth, it's possible that you might need to polyfill more  
libraries. Typically, the libraries like \`browserify-zlib\`, \`assert\`, \`stream-http\`, \`https-browserify\`,  
\`os-browserify\`, \`url\` are commonly required.

\#\# Step 2: Update your metro.config.js​

To make use of the polyfilled modules while building the application, you need to reconfigure your metro  
bundler config.

Create a \`metro.config.js\` for an expo-managed workflow, as it is not present by default.

Learn more about \[customizing a metro bundler\](https://docs.expo.dev/guides/customizing-metro/).

Note that polyfilling is not supported with "Expo Go" app. It's compatible only with Custom Dev Client and Expo Application Services (EAS) builds. Please \[prebuild your expo app\](https://docs.expo.dev/workflow/prebuild/)  
to generate native code based on the version of expo a project has installed, before progressing.

You can copy the following code in your \`metro.config.js\` file. This will tell the bundler to ignore the  
missing modules and include those that are needed.

\#\#\#\# metro.config.js​

\`\`\`  
const { getDefaultConfig, mergeConfig } \= require('@react-native/metro-config')

const defaultConfig \= getDefaultConfig(\_\_dirname)

const config \= {  
  resolver: {  
    extraNodeModules: {  
      assert: require.resolve('empty-module'), // assert can be polyfilled here if needed  
      http: require.resolve('empty-module'), // stream-http can be polyfilled here if needed  
      https: require.resolve('empty-module'), // https-browserify can be polyfilled here if needed  
      os: require.resolve('empty-module'), // os-browserify can be polyfilled here if needed  
      url: require.resolve('empty-module'), // url can be polyfilled here if needed  
      zlib: require.resolve('empty-module'), // browserify-zlib can be polyfilled here if needed  
      path: require.resolve('empty-module'),  
      crypto: require.resolve('crypto-browserify'),  
      stream: require.resolve('readable-stream'),  
    },  
    sourceExts: \[...defaultConfig.resolver.sourceExts, 'svg'\],  
  },  
}

module.exports \= mergeConfig(defaultConfig, config)

\`\`\`

\#\# Step 3: Fix additional dependency issues​

1\. Create a \`globals.js\` at your project root directory and add the following code to it:

\`\`\`  
global.Buffer \= require('buffer').Buffer

// Needed so that 'stream-http' chooses the right default protocol.  
global.location \= {  
  protocol: 'file:',  
}

global.process.version \= 'v16.0.0'  
if (\!global.process.version) {  
  global.process \= require('process')  
  console.log({ process: global.process })  
}

process.browser \= true

\`\`\`

1\. Import the dependencies to \`index.js\` of your project.

For Expo apps, you need to create an entry point, that is, the index.js file. This can be done by following  
the \[naming guide\](https://docs.expo.dev/versions/latest/sdk/register-root-component/\#what-if-i-want-to-name-my-main-app-file-something-other-than-appjs)

\`\`\`  
import { AppRegistry } from 'react-native'  
import './globals'  
import 'react-native-get-random-values'  
import App from './App'  
import { name as appName } from './app.json'  
AppRegistry.registerComponent(appName, () \=\> App)

\`\`\`

\# Bundler polyfill issues \- Nuxt

While setting up a new Web3 project from scratch, you might face bundler issues. This can occur because the core packages like \`eccrypto\` have dependencies which are not present within the build environment.

To rectify this, the go-to method is to add the missing modules directly into the package, and edit the bundler configuration to use those. Although this approach works, it can significantly increase bundle size, leading to slower load times and a degraded user experience.

Some libraries rely on environment-specific modules that may be available at runtime in the browser even if they are not bundled. Libraries such as Embedded Wallets’ Web3Auth take advantage of this behavior and can function correctly without bundling all modules. However, if you are using a library that does not take advantage of this , you might face issues.

To avoid unnecessary overhead, include only the required polyfills, test functionality, and configure your bundler to ignore unresolved modules rather than including them in the final build.

We recommend that you require certain Node polyfills to be added to your project, while testing each of its functionalities. At the same time, instruct the bundler to ignore the missing modules, and not include them in the build.

In this guide, we provide instructions for adding polyfills in Nuxt. The steps install the missing libraries required for module resolution and then configures Nuxt so they are not bundled unless needed at runtime.

\#\# Step 1: Install the missing modules​

Check for the missing libraries in your build and included packages, and accordingly polyfill them. For Web3Auth, you just need to polyfill the \`buffer\` and \`process\` libraries.

\`\`\`  
npm install \--save-dev buffer process

\`\`\`

\#\# Step 2: Create a plugin to polyfill the missing modules​

Create a new plugin file in the \`plugins\` directory of your Nuxt project. This plugin will polyfill the missing modules.

\`\`\`  
// plugins/node.client.ts

import { Buffer } from 'buffer'  
import process from 'process'

globalThis.Buffer \= Buffer  
globalThis.process \= process

export default defineNuxtPlugin({})

\`\`\`

\#\# Step 3: Update your nuxt.config.js​

Additional to the polyfilled modules, you need to update the \`nuxt.config.js\` file to define the \`global\` object.

\`\`\`  
/\* eslint-disable import/no-extraneous-dependencies \*/  
import react from '@vitejs/plugin-react'  
import { defineConfig } from 'vite'

// https://nuxt.com/docs/api/configuration/nuxt-config

export default defineNuxtConfig({  
  devtools: { enabled: true },  
  ssr: false,  
  vite: {  
    define: {  
      global: 'globalThis',  
    },  
  },

  compatibilityDate: '2024-08-08',  
})

\`\`\`

\# Popup blocked issue

This guide explains how to prevent popups from being blocked in browsers like Safari on iOS and macOS devices when using Web3Auth with \`uxMode\` set to popup.

Implementing these strategies requires a balance between technical adjustments in the code and accommodating various browser behaviors and user actions. The goal is to ensure a smooth and uninterrupted authentication process for users across different platforms and browsers.

\#\# Browser restrictions and best practices​

Browsers have specific restrictions and intelligent tracking prevention methods that often block popups. To navigate this, you should understand the heuristics used by different browsers and apply best practices accordingly. This might include instructing users to manually enable popups in their browser settings.

\#\# Optimize the code flow​

One effective approach is to minimize the delay between user interaction and the appearance of the login popup. This can be achieved by separating the initialization of the SDK from the user login method calls. For instance, triggering the \`connectTo\` function on a button click rather than on page load can prevent the popup from being blocked. This method works around the browser's popup-blocking mechanisms, which are more likely to engage when popups do not directly follow a user action.

\#\# Leverage alternative authentication methods​

If the popup issue persists, consider using an alternative \`uxMode\` like \`redirect\` rather than \`popup\`. In general, redirect methods are more reliable and less likely to be blocked by browsers. However, this might impact the user experience, as redirects are typically more disruptive than popups.

\#\# Implement notifications​

You can also implement a notification system within your application that prompts users to allow popups if they are detected as blocked. This user-centric approach can help in cases where browser settings are the root cause of the issue.

\# BigInt error in React production build.

While developing your React app with @web3auth/modal, the application may work correctly in development mode but fail in production with the following error:

Uncaught TypeError: Cannot convert a BigInt value to a number

This happens because the production build relies on Browserslist to determine which browsers to target. If browser versions are not explicitly specified, the build uses the default Browserslist configuration, which may target environments that do not fully support BigInt. This mismatch can result in runtime errors in production.

You can resolve this issue by explicitly defining supported browser versions in your package.json file:

\`\`\`  
"browserslist": {  
    "production": \[  
      "supports bigint",  
      "not dead",  
    \],  
    "development": \[  
      "last 1 chrome version",  
      "last 1 firefox version",  
      "last 1 safari version"  
    \]  
  }

\`\`\`

By adding these lines, you are telling the JavaScript bundlers to use specific versions of the browsers for the production build. After adding the above lines, create the production build again and you should be good to go.

\# SDK errors and warnings

\#\# Web3Auth Web SDKs​

\`@web3auth/modal\`, \`@web3auth/no-modal\`, and other frontend SDKs, including mobiles.

\#\#\# General errors​

| Code | Message | Description |  
| \--- | \--- | \--- |  
| TPC\_NOT\_SUPPORTED | Unable to detect device share. | This may be due to browser security settings. Adjust your current browser settings from 'Strict' to 'Moderate'. Alternatively, log in via a Chrome Browser. |  
| NETWORK\_RESPONSE\_FAILED | Unable to detect login share from the Web3Auth Network. | This may be due to slow internet connection. Check your internet speed and try again. |  
| DUPLICATE\_TOKEN\_FOUND | Unable to verify. | This may be due to invalid login. Kindly log out of your social login provider on your current browser and login again. |  
| BUSY\_NETWORK | Unable to connect to Web3Auth Network. | The Network may be congested. Please try again in 5 minutes. |  
| KEY\_ASSIGN\_FAILED | A key has not been assigned to you. | This might be due to communication with the Web3Auth network nodes. Kindly relogin to try again. If problem persists, please contact support. |  
| VERIFIER\_NOT\_SUPPORTED | Verifier not supported. | Kindly ensure you have a live verifier on the right network (Testnet/Mainnet). Set up / Check verifier status here: https://dashboard.web3auth.io |  
| DEFAULT | There seems to be some bug in the code. | Please contact support to fix this. |

\#\#\# Initialization errors​

| Code | Message | Description |  
| \--- | \--- | \--- |  
| 5001 | Wallet is not found | Error occurred, when there's no wallet found. |  
| 5002 | Wallet is not installed | Error occurred, when the requested wallet is not installed . |  
| 5003 | Wallet is not ready yet | Error occurred, when the wallet is not ready. |  
| 5004 | Wallet window is blocked | Error occurred, when the wallet window is blocked. |  
| 5005 | Wallet window has been closed by the user | Error occurred, when the wallet window is closed by the user. |  
| 5006 | Incompatible chain namespace provided | Error occurred, when the incompatible chainNamespace was passed. |  
| 5007 | Adapter has already been included | Error occurred, when the same adapter is added more than once.. |  
| 5008 | Invalid provider Config | Error occurred, when an invalid provider configurations are being used. |  
| 5009 | Provider is not ready yet | Error occurred, when the provider is not ready and trying to use it |  
| 5010 | Failed to connect with rpc url | Error occurred, when trying to connect the wallet with the RPC URL. |  
| 5011 | Invalid params passed in | Error occurred, when an invalid parameter was passed. |  
| 5013 | Invalid network provided | Error occurred, when an invalid network was provided during initialization. |

\#\#\# Login errors​

| Code | Message | Description |  
| \--- | \--- | \--- |  
| 5111 | Failed to connect with wallet | Upon login, the wallet is unable to connect. |  
| 5112 | Failed to disconnect from wallet | Upon log out, the wallet is unable to disconnect. |  
| 5113 | Wallet is not connected | Throws this error when trying to use a logged out wallet. |  
| 5114 | Wallet popup has been closed by the user | Throws this error when the user has closed the Login Modal. |

\#\#\# JSON RPC errors​

| Code | Message | Description |  
| \--- | \--- | \--- |  
| \-32700 | Parse Error | Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text. |  
| \-32600 | Invalid Request | The JSON sent is not a valid Request object. |  
| \-32601 | Method Not Found | The method does not exist / is not available. |  
| \-32602 | Invalid Params | Invalid method parameter(s). |  
| \-32603 | Internal Error | Internal JSON-RPC error. These can manifest as different generic issues (such as attempting to access a protected endpoint before the user is logged in). |  
| \-32000 to \-32099 | Server Error | Reserved for implementation-defined server errors. |

\#\# Torus EVM and Solana wallet plugin errors​

| Code | Message |  
| \--- | \--- |  
| 5210 | Torus Wallet Plugin is not initialized. |  
| 5211 | Web3Auth is connected to unsupported adapter. Torus wallet connector plugin requires web3auth connected to auth adapter. |  
| 5212 | Provider is required. |  
| 5213 | Web3Auth instance is required while initialization. |  
| 5214 | Web3Auth is not connected. |  
| 5215 | UserInfo is required. |  
| 5216 | Plugin is already initialized. |  
| 5217 | Torus wallet instance is not set. |

\#\# Web3Auth Node SDK​

\`@web3auth/node-sdk\`

\#\#\# Constructor errors​

| Message | Description |  
| \--- | \--- |  
| chainNamespace is required | chainNamespace is required for EVM and Solana Chains. |  
| Please provide a valid clientId in constructor | Invalid clientId was passed in the constructor. |  
| chainId is required for non-OTHER chainNamespace | A Chain ID is required for EVM and Solana Chains. |  
| rpcTarget is required for non-OTHER chainNamespace | An RPC target is required for EVM and Solana Chains. |

\#\#\# Initialization errors​

| Message | Description |  
| \--- | \--- |  
| chainConfig is required for Solana in constructor | When initializing, chainConfig for Solana needs to be passed, else will throw this error. |  
| chainConfig is required for EVM chain in constructor | When initializing, chainConfig for EVM Chains needs to be passed, else will throw this error. |  
| Invalid chainNamespace: ${this.currentChainNamespace} found while connecting to wallet | When initializing, unsupported chainConfig was passed. |

\#\#\# Login errors​

| Message | Description |  
| \--- | \--- |  
| User has already enabled mfa, please use the @web3auth/web3auth-web sdk for login with mfa | A user has enabled 2FA, @web3auth/node-sdk only works for a users who have not enabled MFA. |

\#\#\# Other errors​

Additional errors may be found during \`@web3auth/node-sdk\` implementations:

| Message | Description |  
| \--- | \--- |  
| node results do not match at first lookup | Verifier not supported. |  
| Error occurred while verifying params | Invalid parameter was passed. |  
| Duplicate token found | An already used (JWT)id\_token was passed. |

\#\# Web3Auth infrastructure errors​

| Code | Message |  
| \--- | \--- |  
| 1001 | Unable to delete service provider share |  
| 1002 | Wrong share index |  
| 1003 | Unable to updateSDK |  
| 1101 | Metadata not found, SDK likely not initialized |  
| 1102 | getMetadata errored |  
| 1103 | setMetadata errored |  
| 1104 | previouslyFetchedCloudMetadata provided in initialization is outdated |  
| 1105 | previouslyFetchedCloudMetadata.nonce should never be higher than the latestShareDetails, please contact support |  
| 1201 | Invalid tkeyStore |  
| 1202 | Encryption failed |  
| 1203 | Decryption failed |  
| 1301 | Private key not available. Please reconstruct key first |  
| 1302 | Unable to reconstruct |  
| 1303 | reconstructed key is not pub key |  
| 1304 | Share found in unexpected polynomial |  
| 1305 | Input is not supported |  
| 1306 | no encrypted share store for share exists |  
| 1307 | Share doesn't exist |  
| 1308 | Share was deleted |  
| 1401 | Unable to acquire lock |  
| 1402 | Unable to release lock |  
| 1501 | Private key unavailable |  
| 1502 | Metadata pubkey unavailable |  
| 1503 | getAuthMetadata errored |  
| 1504 | setAuthMetadata errored |  
| 1601 | delete1OutOf1 requires manualSync=true |

\# Supported browsers list

\#\# Supported browsers list​

The Embedded Wallets SDKs require BigInt support, which is not supported by all browsers. The list of browsers along with their versions that support BigInt are listed below. The versions are listed according to this \[page\](https://browsersl.ist/\#q=supports+bigint%2C+not+dead).

\- Chrome 67+  
\- Chrome for Android 107+  
\- Safari 14+  
\- Safari on iOS 14+  
\- Edge 79+  
\- Firefox 68+  
\- Firefox for Android 106+  
\- Opera 54+  
\- Opera Mobile 72+  
\- Samsung Internet 9.2+  
\- UC Browser for Android 13.4+  
\- QQ Browser 13.1+  
\- Android Browser 107+

\#\# Framework-specific note​

When creating your React App in production, follow the recommended steps to \[avoid a BigInt error\](https://docs.metamask.io/embedded-wallets/troubleshooting/react-big-int-error/).

\# Bundler Polyfill issues \- Svelte with Vite

When developing a new Embedded Wallets project with Svelte and Vite, you may encounter bundler issues due to missing polyfills. This commonly occurs with packages like \`eccrypto\` which rely on Node modules not present in the browser environment. Directly adding these modules to your package can solve the issue but may lead to a larger bundle size, affecting load times and user experience.

It's essential to recognize that the required Node polyfills should only be included during development and testing, and the bundler should be instructed to exclude them from the production build.

The following guide provides instructions for adding the necessary polyfills in a Svelte project using Vite.

\#\# Step 1: Install the missing modules​

First, identify the missing libraries in your build. For integrating Web3Auth with Svelte, you will need to polyfill \`buffer\` and \`process\`. For other libraries, use an alternative like the \`empty-module\` to prevent build warnings.

\`\`\`  
npm install \--save-dev buffer process vite-plugin-node-polyfills

\`\`\`

If you're using any other blockchain library alongside Web3Auth, it's possible that you might need to polyfill more libraries. Typically, the libraries like \`crypto-browserify\`,  
\`stream-browserify\`, \`browserify-zlib\`, \`assert\`, \`stream-http\`, \`https-browserify\`, \`os-browserify\`, \`url\`  
are the ones that might be required, with \`crypto-browserify\` and \`url\` being the most common polyfills.

\#\# Step 2: Update your vite.config.js​

Modify your Vite configuration to integrate the polyfills with Svelte as follows:

\`\`\`  
import { sveltekit } from '@sveltejs/kit/vite'  
import { defineConfig } from 'vitest/config'  
import { nodePolyfills } from 'vite-plugin-node-polyfills'

export default defineConfig({  
  plugins: \[  
    nodePolyfills({  
      exclude: \['fs'\],  
      globals: {  
        Buffer: true,  
        global: true,  
        process: true,  
      },  
      protocolImports: true,  
    }),  
    sveltekit(),  
  \],  
  optimizeDeps: {  
    include: \['dayjs/plugin/relativeTime.js', 'dayjs', '@web3auth/ethereum-provider'\],  
  },  
  test: {  
    include: \['src/\*\*/\*.{test,spec}.{js,ts}'\],  
  },  
})

\`\`\`

This configuration sets up the necessary aliases and defines globals for the browser environment, ensuring compatibility and reducing bundle size.

\#\# Step 3: Address additional dependency issues​

If there are additional dependencies that need to be polyfilled, consider adding them to the include array in the \`optimizeDeps\` section of the Vite config. Test your application to ensure that all functionalities work as expected after the polyfills are added.

By following these steps, you should be able to resolve bundler polyfill issues in your Svelte and Vite Embedded Wallets project, leading to a more efficient build and a smoother user experience.

\# Bundler Polyfill issues \- Vite

While setting up a new Web3 project from scratch, you might face bundler issues. This can occur because the  
core packages like \`eccrypto\` have dependencies which are not present within the build environment.

To rectify this, the go-to method is to add the missing modules directly into the package, and edit the bundler  
configuration to use those. Although this approach works, it can significantly increase bundle size, leading  
to slower load times and a degraded user experience.

Some libraries rely on environment-specific modules that may be available at runtime in the browser even if  
they are not bundled. Libraries such as Embedded Wallets’ Web3Auth take advantage of this behavior and can  
function correctly without bundling all modules. However, if you are using a library that does not take  
advantage of this, you might face issues.

To avoid unnecessary overhead, include only the required polyfills, test functionality, and  
configure your bundler to ignore unresolved modules rather than including them in the final build.

We recommend that you require certain Node polyfills to be added to your project, while testing each of  
its functionalities. At the same time, instruct the bundler to ignore the missing modules, and not include  
them in the build.

In this guide, we provide instructions for adding polyfills in Vite.

\#\# Step 1: Install the missing modules​

Check for the missing libraries in your build and included packages, and accordingly polyfill them. For Web3Auth, you just need to polyfill the \`buffer\` and \`process\` libraries.

\`\`\`  
npm install \--save-dev buffer process

\`\`\`

\#\# Step 2: Add the polyfills to your project​

Update the \`index.html\` file to include the polyfills. As shown in the code snippet below we added the \`\<script\>\` tag to include the polyfills.

\`\`\`  
\<\!doctype html\>  
\<html lang="en"\>  
  \<head\>  
    \<script type="module"\>  
      import { Buffer } from 'buffer'  
      import process from 'process'  
      window.Buffer \= Buffer  
      window.process \= process  
    \</script\>  
    \<meta charset="UTF-8" /\>  
    \<link rel="icon" type="image/svg+xml" href="/vite.svg" /\>  
    \<meta name="viewport" content="width=device-width, initial-scale=1.0" /\>  
  \</head\>  
  \<body\>  
    \<div id="root"\>\</div\>  
    \<script type="module" src="/src/main.tsx"\>\</script\>  
  \</body\>  
\</html\>

\`\`\`

\#\# Step 3: Update your vite.config.js​

Next, update the \`nuxt.config.js\` file to define the \`global\` object.

If you're using any other blockchain library alongside Web3Auth, it's possible that you might need to polyfill more libraries. Typically, the libraries like \`crypto-browserify\`,  
\`stream-browserify\`, \`browserify-zlib\`, \`assert\`, \`stream-http\`, \`https-browserify\`, \`os-browserify\`, \`url\`  
are the ones that might be required, with \`crypto-browserify\` and \`url\` being the most common polyfills.

\`\`\`  
/\* eslint-disable import/no-extraneous-dependencies \*/  
import react from '@vitejs/plugin-react'  
import { defineConfig } from 'vite'

// https://vitejs.dev/config/  
export default defineConfig({  
  plugins: \[react()\],  
  // alias are only to be added when absolutely necessary, these modules are already present in the browser environment  
  // resolve: {  
  // alias: {  
  // crypto: "crypto-browserify",  
  // assert: "assert",  
  // http: "stream-http",  
  // https: "https-browserify",  
  // url: "url",  
  // zlib: "browserify-zlib",  
  // stream: "stream-browserify",  
  // },  
  // },  
  define: {  
    global: 'globalThis',  
  },  
})

\`\`\`

\# Bundler Polyfill issues \- Webpack 5

React's development team has officially \*\*deprecated\*\* Create React App (CRA) and Webpack. For more information,  
please refer to \[this Pull Request\](https://github.com/reactjs/react.dev/pull/5487).

While Embedded Wallet's Web3Auth libraries are compatible with CRA, there is a possibility that certain functionalities may not work as expected due to sub-dependencies. We recommend using Vite to set up your React app.

Learn more about \[how to migrate from Create React App to Vite\](https://builder.metamask.io/t/how-to-migrate-from-create-react-app-to-vite/1211).

While setting up a new Web3 project from scratch, you might face bundler issues. This can occur because the  
core packages like \`eccrypto\` have dependencies which are not present within the build environment.

To rectify this, the go-to method is to add the missing modules directly into the package, and edit the bundler  
configuration to use those. Although this approach works, it can significantly increase bundle size, leading  
to slower load times and a degraded user experience.

Some libraries rely on environment-specific modules that may be available at runtime in the browser even if  
they are not bundled. Libraries such as Embedded Wallets’ Web3Auth take advantage of this behavior and can  
function correctly without bundling all modules. However, if you are using a library that does not take  
advantage of this, you might face issues.

To avoid unnecessary overhead, include only the required polyfills, test functionality, and  
configure your bundler to ignore unresolved modules rather than including them in the final build.

We recommend that you require certain Node polyfills to be added to your project, while testing each of  
its functionalities. At the same time, instruct the bundler to ignore the missing modules, and not include  
them in the build.

In this guide, we provide instructions for adding polyfills in of some of the most commonly used web frameworks:

\- \[React\](https://docs.metamask.io/embedded-wallets/troubleshooting/webpack-issues/\#react)  
\- \[Angular\](https://docs.metamask.io/embedded-wallets/troubleshooting/webpack-issues/\#angular)  
\- \[Vue.js\](https://docs.metamask.io/embedded-wallets/troubleshooting/webpack-issues/\#vuejs)  
\- \[Gatsby\](https://docs.metamask.io/embedded-wallets/troubleshooting/webpack-issues/\#gatsby)

\#\# React​

For Create React App (CRA):

1\. Install \`react-app-rewired\` into your application:

\`\`\`  
npm install \--save-dev react-app-rewired

\`\`\`

1\. Check for the missing libraries in your build and included packages, and accordingly polyfill them.  
For Web3Auth, you just need to polyfill the \`buffer\` and \`process\` libraries:

\`\`\`  
npm install \--save-dev buffer process

\`\`\`

If you're using any other blockchain library alongside Web3Auth, it's possible that you might need to polyfill more libraries. Typically, the libraries like \`crypto-browserify\`,  
\`stream-browserify\`, \`browserify-zlib\`, \`assert\`, \`stream-http\`, \`https-browserify\`, \`os-browserify\`, \`url\`  
are the ones that might be required, with \`crypto-browserify\` and \`stream-browserify\` being the most common polyfills.

1\. Create \`config-overrides.js\` in the root of your project folder with the content:

\`\`\`  
const webpack \= require('webpack')

module.exports \= function override(config) {  
  const fallback \= config.resolve.fallback || {}  
  Object.assign(fallback, {  
    crypto: false, // require.resolve("crypto-browserify") can be polyfilled here if needed  
    stream: false, // require.resolve("stream-browserify") can be polyfilled here if needed  
    assert: false, // require.resolve("assert") can be polyfilled here if needed  
    http: false, // require.resolve("stream-http") can be polyfilled here if needed  
    https: false, // require.resolve("https-browserify") can be polyfilled here if needed  
    os: false, // require.resolve("os-browserify") can be polyfilled here if needed  
    url: false, // require.resolve("url") can be polyfilled here if needed  
    zlib: false, // require.resolve("browserify-zlib") can be polyfilled here if needed  
  })  
  config.resolve.fallback \= fallback  
  config.plugins \= (config.plugins || \[\]).concat(\[  
    new webpack.ProvidePlugin({  
      process: 'process/browser',  
      Buffer: \['buffer', 'Buffer'\],  
    }),  
  \])  
  config.ignoreWarnings \= \[/Failed to parse source map/\]  
  config.module.rules.push({  
    test: /\\.(js|mjs|jsx)$/,  
    enforce: 'pre',  
    loader: require.resolve('source-map-loader'),  
    resolve: {  
      fullySpecified: false,  
    },  
  })  
  return config  
}

\`\`\`

1\. Within \`package.json\` change the scripts field for start, build and test. Instead of \`react-scripts\`  
replace it with \`react-app-rewired\`:

\`\`\`  
"scripts": {  
    "start": "react-app-rewired start",  
    "build": "react-app-rewired build",  
    "test": "react-app-rewired test",  
    "eject": "react-scripts eject"  
},

\`\`\`

The missing Node.js polyfills should be included now and your app should be compatible with Embedded Wallet's  
Web3Auth.

If you're using \`craco\`, similar changes need to be made to \`craco.config.js\`

\#\# Angular​

1\. Check for the missing libraries in your build and included packages, and polyfill these. For  
Web3Auth, you need the \`buffer\` and \`process\` libraries. For the rest of the libraries,  
we are installing a dummy module called \`empty-module\` which quiets the warnings while  
building the project.

\`\`\`  
npm install \--save-dev buffer process empty-module

\`\`\`

If you're using any other blockchain library alongside Web3Auth, it's possible that you might need to polyfill more libraries. Typically,  the libraries like \`crypto-browserify\`,  
\`stream-browserify\`, \`browserify-zlib\`, \`assert\`, \`stream-http\`, \`https-browserify\`, \`os-browserify\`, \`url\`  
are the ones that might be required, with \`crypto-browserify\` and \`stream-browserify\` being the most common polyfills.

Within \`tsconfig.json\` add the following \`paths\` in \`compilerOptions\` so Webpack can get the correct dependencies:

\`\`\`  
{  
  "compilerOptions": {  
    "paths" : {  
      "crypto": \["./node\_modules/empty-module"\], // crypto-browserify can be polyfilled here if needed  
      "stream": \["./node\_modules/empty-module"\], // stream-browserify can be polyfilled here if needed  
      "assert": \["./node\_modules/empty-module"\], // assert can be polyfilled here if needed  
      "http": \["./node\_modules/empty-module"\], // stream-http can be polyfilled here if needed  
      "https": \["./node\_modules/empty-module"\], // https-browserify can be polyfilled here if needed  
      "os": \["./node\_modules/empty-module"\], // os-browserify can be polyfilled here if needed  
      "url": \["./node\_modules/empty-module"\], // url can be polyfilled here if needed  
      "zlib": \["./node\_modules/empty-module"\], // browserify-zlib can be polyfilled here if needed  
      "process": \["./node\_modules/process"\],  
    }  
  }  
}

\`\`\`

1\. Add the following lines to \`polyfills.ts\` file:

\`\`\`  
;(window as any).global \= window  
global.Buffer \= global.Buffer || require('buffer').Buffer  
global.process \= global.process || require('process')

\`\`\`

\#\# Vue.js​

1\. Check for the missing libraries in your build and included packages, and accordingly polyfill them.  
For Web3Auth, you just need to polyfill the \`buffer\` and \`process\` libraries:

\`\`\`  
npm install \--save-dev buffer process

\`\`\`

If you're using any other blockchain library alongside Web3Auth, it's possible that you might need to polyfill more libraries. Typically, the libraries like \`crypto-browserify\`,  
\`stream-browserify\`, \`browserify-zlib\`, \`assert\`, \`stream-http\`, \`https-browserify\`, \`os-browserify\`, \`url\`  
are the ones that might be required, with \`crypto-browserify\` and \`stream-browserify\` being the most common polyfills.

1\. Add the following lines to \`vue.config.js\`

\`\`\`  
const { defineConfig } \= require('@vue/cli-service')  
const { ProvidePlugin } \= require('webpack')  
const { BundleAnalyzerPlugin } \= require('webpack-bundle-analyzer')  
module.exports \= defineConfig({  
  transpileDependencies: true,  
  lintOnSave: false,  
  configureWebpack: config \=\> {  
    config.devtool \= 'source-map'  
    config.resolve.symlinks \= false  
    config.resolve.fallback \= {  
      crypto: false, // crypto-browserify can be polyfilled here if needed  
      stream: false, // stream-browserify can be polyfilled here if needed  
      assert: false, // assert can be polyfilled here if needed  
      os: false, // os-browserify can be polyfilled here if needed  
      https: false, // https-browserify can be polyfilled here if needed  
      http: false, // stream-http can be polyfilled here if needed  
      url: 'url', // url is needed if using \`signer.provider.send\` method for signing from ethers.js  
      zlib: false, // browserify-zlib can be polyfilled here if needed  
    }  
    config.plugins.push(new ProvidePlugin({ Buffer: \['buffer', 'Buffer'\] }))  
    config.plugins.push(new ProvidePlugin({ process: \['process/browser'\] }))  
    config.plugins.push(  
      new BundleAnalyzerPlugin({  
        analyzerMode: 'disabled',  
      })  
    )  
  },  
})

\`\`\`

\#\# Gatsby​

\#\#\#\# Can't resolve object.assign/polyfill​

1\. Check for the missing libraries in your build and included packages, and polyfill these.  
For Web3Auth, you need to polyfill the \`buffer\` and \`process\` libraries:

\`\`\`  
npm install \--save-dev buffer process

\`\`\`

If you're using any other blockchain library alongside Web3Auth, it's possible that you might need to polyfill more libraries. Typically, the libraries like \`crypto-browserify\`,  
\`stream-browserify\`, \`browserify-zlib\`, \`assert\`, \`stream-http\`, \`https-browserify\`, \`os-browserify\`, \`url\`  
are the ones that might be required, with \`crypto-browserify\` and \`stream-browserify\` being the most common polyfills.

1\. Add the following lines to \`gatsby-node.js\`

\`\`\`  
exports.onCreateWebpackConfig \= ({ actions, plugins, getConfig }) \=\> {  
  const webpack \= require('webpack')  
  const path \= require('path')  
  const config \= getConfig()  
  if (config.externals && config.externals\[0\]) {  
    config.externals\[0\]\['node:crypto'\] \= require.resolve('crypto-browserify')  
  }  
  actions.setWebpackConfig({  
    ...config,  
    resolve: {  
      fallback: {  
        crypto: false,  
        stream: false,  
        assert: require.resolve('assert/'),  
        http: false,  
        https: false,  
        os: false,  
        url: false,  
        zlib: false,  
        'object.assign/polyfill': path.resolve('./node\_modules/object.assign/polyfill.js'),  
      },  
    },  
    plugins: \[  
      plugins.provide({ process: 'process/browser' }),  
      new webpack.ProvidePlugin({  
        Buffer: \['buffer', 'Buffer'\],  
      }),  
    \],  
  })  
}

\`\`\`

