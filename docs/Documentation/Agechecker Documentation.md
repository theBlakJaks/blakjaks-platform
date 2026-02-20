# **AgeChecker.Net API**

### **Build a custom integration with our scripts and API.**

To install AgeChecker.Net on a custom website or platform without official support, you will have to build a custom integration using the client API and optional server API.

The client side includes a configuration script to change the options of the popup and an external script that loads the popup. You can also develop a seamless integration using our API without the popup.

On the server side, you can validate the verification for added security. When a verification is created, it is given a unique identifier known as the verification UUID. The unique key for your domain is known as the API Key. Verifications can also be created from the server. (e.g. a user can be verified when a signup form is submitted)

* [Client API Documentation](https://agechecker.net/account/install/custom/client)  
* [Server API Documentation](https://agechecker.net/account/install/custom/server)

# **Client API Documentation**

The AgeChecker.Net popup is powered by a single JavaScript file which attaches the popup to a DOM element, and loads the popup (including the CSS and template) when triggered.

A few configuration options can be specified in order to customize the popup.

This script should be placed on your checkout page and configured to attach to a checkout button, terms of service checkbox, or another element near the end of the checkout process.

### **Options:**

The script accepts many configuration options through a global object named "AgeCheckerConfig". Create this object **before** loading the script.

Below is the script loader that we use to load AgeChecker.Net. It prevents the user from bypassing the popup by disabling JavaScript or blocking our script, and can be configured to only load the script on one page.

\<**noscript**\>\<**meta** http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</**noscript**\>  
\<**script**\>  
(**function**(w,d) {  
  **var** config \= {  
    element: "\#checkout-button",  
    key: "Your API KEY",  
  };  
   
  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document);

\</**script**\>

#### **Fields:**

| Option Name | Description |
| :---- | :---- |
| key | The API key for the domain. You can find this on the websites tab in your account panel. abcd1p5NqQt7D1aaQsfkdcGubKeb9rJ5 |
| element | A selector for the element the popup event will be attached to. This can be an ID such as "\#checkout-button" or a more complex selector such as "\#checkout .form-2 .button" This field can also instead be set to an array of selectors, so the popup can attach to multiple elements. (e.g. \["\#checkout-button", "\#alt-btn"\]) This field is only required in **auto** mode. \#checkout-button |
| bind\_all | Determines if the popup should bind to every instance of an element selector listed in "config.element". false |
| session | UUID for a session. Session options will be applied to the verification upon creation. If a verification was already started under the session, it will resume the previous verification. (See the /v1/session/create endpoint in our [Server API documentation](https://agechecker.net/account/install/custom/server) for info on creating a session) not set |
| platform\_elements | Allow AgeChecker to attach to a default set of element selectors specific to platforms. Can be set to "false" to disable these default element selectors from being attached to. true |
| background | The background shown behind the popup. This is applied to a CSS background property, so any valid CSS background can be used (such as colors, gradients, and images) rgba(0,0,0,0.7) |
| font | The font shown in the popup. This is applied to a CSS font property, so any valid CSS font can be used. 'Muli', 'Arial', 'Helvetica', sans-serif |
| accent\_color | The accent color of the popup used on the stripe and buttons. This may also be any valid CSS background property. linear-gradient(135deg, \#7fc24c 0%,\#04a1bf 100%) |
| input\_focus\_color | The outline color of input boxes when a user clicks/focuses on them. \#80bdff |
| logo\_url | Full URL path to your logo image to be displayed instead of the standard "Age Verification" heading. not set |
| logo\_height | The height of the logo displayed with config property "logo\_url". This is applied to a CSS height property, so any valid CSS height can be used. initial |
| wording | Object containing wording customization options for popup text. Properties: \- info\_type (Changes mentions of "billing information". Values: shipping, none) wording: { info\_type: "shipping" } |
| events | Array of events to trigger the popup on the element. \["mousedown", "touchstart", "click"\] |
| autoload | If false, an instance of the popup loader will not be created. (You must use the API to create an instance, which searches for the element, binds to it, and eventually triggers the popup) If autoload is false then you do not need to specify a key or element, as you will specify them in the individual AgeCheckerAPI.createInstance(config) calls. true |
| mode | Mode of the popup. "manual" mode allows the popup to be shown when needed through the client API. "auto" mode will show the popup when the element is triggered. auto |
| call\_events | Allows the events to be called automatically by the script when the customer is verified. (For example, to proceed to the next checkout step automatically.) true |
| rebind | Enables the popup to bind events to the element multiple times if the element is removed or altered. true |
| debug | Enables logging of events to the console. If the popup is not being triggered, enable debugging to look for errors. true |
| defer\_submit | Prevents the popup from closing until the callback passed in the onclosed function is called. This allows you to wait for blocking events before submitting the page. false |
| rename\_element | Enables changing of the element text. If a span or input element is found on the element, "Verify Age & " will be preprended to it. (Case is taken into consideration) The resulting text could be "Verify Age & Check Out", for example. true |
| require\_email | Enables the requirement of email collection, if an email can not be automatically retrieved from the checkout page the verification popup will require the user to submit their email address at the data entry step. To use a custom field for the email field, set fields.contact\_email. false |
| add\_comment | Enables adding the verification UUID as a comment to the order if a comment field is found. To use a custom field for the comment field, set fields.comments. true |
| comment\_details | Adds additional info (the customer's name) to the comment (if possible). false |
| fields | Custom input fields to pull customer data from to populate the popup fields. The script has a list of default fields for the most common e-commerce platforms, however you can add your own. If the popup asks for the customer's name, address, etc., then use the fields object to customize where the data is pulled from, or use the data object to pass your own customer information. The following fields can be customized with a CSS selector, ID, or an array of selectors: first\_name, last\_name, full\_name, address, zip, country, state, city, dob\_month, dob\_day, dob\_year, contact\_email, and comments. If using an array, the first selector found from left to right will take priority. Field "full\_name" only needs to be used if the first and last name are located in the same input box. fields: { address: "\#form\_address1", zip: ".checkout\_step\_3 input\[name=zip\]", first\_name: \["\#name\_billing", "\#name\_shipping"\]} |
| ignore\_fields | Disables pulling customer data and synchonizing it with any fields on the page. Use this when you pass custom data with the data object and do not want to sync to any fields. false |
| disable\_fields | Makes the input fields read-only to prevent the user from modifying their information after being verified. true |
| show\_close | Allows the user to close the popup before submitting their age verification. Use with caution, as certain elements used in the checkout process may be altered when the popup first launches. false |
| show\_continue\_shopping | Displays a "Continue Shopping" button when the popup is first launched. If enabled in conjunction with the "show\_close" option, it will simply hide the popup and stay on the current page. Otherwise, it will redirect the user to the home page. false |
| next\_btn\_mode | The display of the "Next" button in the popup while action is required. Available options are "hidden" or "disabled". hidden |
| redirect\_url | If set, customer will be redirected to provided URL upon continuing after successful verification instead of closing the popup and returning to the page. not set |
| prescan | Searches for input fields on any page and uses their values as a fallback if the fields are not found on the popup page. For example, if the customer enters their billing on one step and the popup is shown on another step, this will remember what they entered before. false |
| data | Data passed to the popup to populate the fields. The value passed for each field will set the value of each input in the popup and each field on the page (if any). This can be used to fill in the popup with customer information already on file. data: { address: "1234 Somewhere St.", zip: "%VAR\_CUSTOMER\_ZIP%" } |
| temp\_elements | A list of elements to be replaced with an age verification popup trigger until age verification is successfully completed. Value must be an array of objects with the following properties; "Element": The query selector of the element to be replaced. "customizeElement": A function called when the element is created, it is called with one argument containing the created element. This can be used to customize the element. (Optional) "wording": Replace the wording of the element, the default wording is "Verify Age". (Optional) "classList": An array of strings containing class names to be applied to the created element. (Optional) "useDiv": If set to true, the created element will be a div element instead of the default button element. (Optional) "useDefaultStyling": If set to true, the created element will be pre-styled to appear as a rounded edge button. (Optional) temp\_elements: \[{ element: "\#paypal-btn", wording: "Verify Age & Continue to PayPal", classList: \["btn", "btn-primary"\] }\] |
| wrap\_element | Wraps the trigger element with a div that the events will bind to. Use this if your checkout button has click events that are taking priority over our script. false |
| bind\_form\_submit | If binded element is part of a form, this will patch the form's submit function if possible to trigger the element's AgeChecker event handler. true |
| scroll\_into\_view | Enables scrolling back to the clicked element when the popup is closed. May need to be disabled if CSS is conflicting. true |
| notify\_on\_complete | Sends a notification to the main email address associated with your account or the email specified under website settings when the verification is complete (Accepted or Denied). false |
| onready | A function called when the script has loaded and initialized. At this point the client API can now be used. If autoload is true for the created AgeChecker instance, onready will also be called with an argument containing the instance's API functions. |
| ontrigger | A function called when an element AgeChecker is attached to is triggered. ("auto" mode only) It is called with one argument containing the DOM element of the attached element that was triggered. Calling **return** "cancel\_trigger" in this function will stop AgeChecker's popup trigger and the default events on the element from calling. Calling **return** "perform\_default" in this function will skip AgeChecker's popup trigger, but continue to perform the default events on the element. (e.g. submitting order) ontrigger: function(element) { ... } |
| onshow | A function called when the verification popup is displayed. May be triggered multiple times if the close button is enabled. |
| onhide | A function called when the verification popup is closed (hidden) before the verification is submitted. Requires the show\_close option to be enabled. |
| onpresubmit | A function called before the initial verification request is sent. It gives you a chance to process the customer data and close the popup or continue with the process. (For example, this could be used to lookup the customer's information in your own database). The first argument contains the customer data. The second argument is a function to continue with processing the verification as normal. The third argument is a function to cancel the verification and continue with checkout. The fourth argument is a function to modify the customer data. (e.g. change({ first\_name: "John" })) onpresubmit: function(data, done, cancel, change) { ... } |
| oncreated | A function called when the intitial verification request is submitted and a response is received. onstatuschanged may be called immediately after if the request was approved automatically. It is called with two arguments, the first containing the uuid of the verification and the data that was sent. The second argument is a function to cancel the verification and continue with checkout. oncreated: function(verification, cancel) { ... } |
| onstatuschanged | A function for adding custom behavior to the popup. This will be called whenever a status is received, which can either be: "accepted", "denied", "signature", "photo\_id", or "pending". It is called with one argument that contains the uuid and status of the verification. onstatuschanged: function(verification) { ... } |
| onclosed | A function called when the popup is closed by the user after the verification is accepted. If defer\_submit is true, the callback (passed as an argument) must be called to close the popup. onclosed: function(done) { ... } |

#### **API:**

The client API can be used once the popup is ready. Use the config.onready event to interact with the API.

The API differs depending on the loading mode. For the default config, an instance is created automatically. An "instance" refers to the code that scans for the element on the page, binds to it, and eventually triggers the popup. (This is most likely what you want)

To run multiple instances on a page (for example, two different buttons which require two different configs), you must set autoload to false and use the createInstance method to create instances in the onready method of the config. See the examples page for more details. Note: If you want to use the same configuration for multiple buttons, you can just specify an array for the elements config.

| Method Name | Description |
| :---- | :---- |
| show(\<optional\>uuid: string) | Shows the AgeChecker.Net popup and resumes the verification process if a UUID is passed as a parameter. AgeCheckerAPI.show() |
| unbind() | Disables the event listener so the bound element will not trigger the popup. Note: This method is only available when using an instance created with createInstance. It is not available through the global AgeCheckerAPI object which would make it easy for users to run and bypass the popup. instanceApi.unbind() |
| createInstance(config: AgeCheckerConfig) | Creates a new AgeChecker.Net instance (see the notes above for definition). Must be using autoload: false in the config, as an instance is automatically created by default. See the examples page for more details. When using autoload: false, the only available API method from the global AgeCheckerAPI object is createInstance, however createInstance will return a specific API object for each new instance, which contains the standard show and unbind functions. AgeCheckerAPI.createInstance(config) |

# **Client API Examples**

## **1\. Attach popup to checkout button**

The following example is the simplest AgeChecker.Net implementation. It causes the age verification popup to appear when the order button is clicked.

**Script:**  
\<**noscript**\>\<**meta** http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</**noscript**\>  
\<**script**\>  
(**function**(w,d) {  
  **var** config \= {  
    key: "API KEY",  
    element: "\#order"  
  };  
    
  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document);

\</**script**\>

**Button:**

\<**button** id="order"\>Place Order\</**button**\>

## **2\. Use custom input fields**

The following example specifies custom input fields to pull customer information from. Our popup will check for the customer's name and address so the customer doesn't have to type their information twice. Additionally, the fields will be "synced" to our popup. If the customer doesn't fill out the input fields before loading the popup, we will synchronize the values from our popup to the values in your form. The input fields will also be disabled to prevent editing, so the information on your checkout page will match the information submitted to us.

Custom input fields are only necessary for custom/unsupported platforms. The popup is pre-loaded with many of the common field names for e-commerce sites. Any CSS selector is valid for the field name. If you already have the customer's information stored in a variable, see example \#5 for another option.

\<**noscript**\>\<**meta** http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</**noscript**\>  
\<**script**\>  
(**function**(w,d) {  
  **var** config \= {  
    key: "API KEY",  
    element: "\#order",  
    fields: {  
      first\_name: "\#checkout .billing\_container .firstname",  
      last\_name: "\#checkout .billing\_container .lastname",  
      address: "\#checkout .billing\_container .address\_line1",  
      zip: "\#checkout .billing\_container .zip",  
      city: "\#checkout .billing\_container .city",  
      country: "\#checkout .billing\_container select.country",  
      state: "\#checkout .billing\_container select.state",  
      comments: "\#checkout \#order\_notes"  
    }  
  };  
    
  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document);

\</**script**\>

The comments field, if specified, will be used to add a comment to a textbox. The comment will provide the UUID of the verification. The customer's name can also be added to the comments field by setting comment\_details: **true** in the config. This is a decent alternative when server-side verification is not available.

## **3\. Show popup on page load and remember user**

The following example shows the popup when the page is loaded, instead of when an element is clicked. When the user is verified, a cookie is set so the popup is not shown again.

The mode is set to manual which allows the popup to be triggered manually. The onready callback is ran when AgeChecker.Net is loaded. From here, AgeCheckerAPI.show() is called to launch the popup. If the user is accepted, it is recorded in a cookie using the onclosed callback.

\<**noscript**\>\<**meta** http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</**noscript**\>  
\<**script**\>  
(**function**(w,d) {  
  **if** (getCookie("ac\_custom\_verified")) **return**;  
  **var** config \= {  
    mode: "manual",  
    key: "API KEY",  
    onready: **function**() {  
      AgeCheckerAPI.show();  
    },  
    onclosed: **function**() {  
      setCookie("ac\_custom\_verified", **true**);  
    }  
  };  
    
  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document);

\</**script**\>

Note: The setCookie and getCookie method implementations not shown.

## **4\. Resume popup**

The following example launches the popup and resumes the age verification process on the appropriate step. This is useful in cases where the initial verification is handled externally, such as though a signup or checkout form.

The idea for this implementation is that the customer's information and date of birth is collected through a signup form, and then verified on your server. If they are accepted then the customer never sees the AgeChecker.Net popup, however if a signature or photo ID is required, you can easily launch the popup and resume the verification.

// Send signup data to your server (where age verification will be run using the server-side API)  
$.ajax({  
  type: "POST",  
  url: "your-server/api/signup",  
  data: {  
    firstname: "John",  
    lastname: "Doe",  
    state: "CA",  
    address: // etc, etc...  
  },  
  success: **function**(result) {    
    // If account was verified, go to account page, if not, show age verification popup to collect signature and/or photo ID.  
    **if** (result.verified)  
      nextPage();  
    **else**  
      AgeCheckerAPI.show(result.agechecker\_uuid);  
  }

});

## **5\. Use existing customer data**

The following example is similar to example \#2, except that custom data is loaded directly from properties instead of from existing input fields. Our popup will populate the input fields of our popup with the data you pass.

For example, if you ask for the customer's date of birth when they register, you can pass the DOB and other information to our popup so the customer doesn't have to input it again. This can be done on many e-commerce platforms by using template variables.

Note that if there are fields on the page (such as those asking for customer information on a checkout page), they will be synced with this data as well.

\<noscript\>\<meta http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</noscript\>  
\<script\>  
(**function**(w,d) {  
  **var** config \= {  
    key: "API KEY",  
    element: "\#order",  
    data: {  
      // Option 1: Pass data as literal:  
      first\_name: "John",  
      last\_name: "Doe",  
      dob\_day: 1,  
      dob\_month: 1,  
      dob\_year: 1990,  
        
      // Option 2: Pass data as variable:  
      address: customerInfo.address  
      zip: customerInfo.zip,  
        
      // Option 3: Pass data as template variable (some e-commerce platforms support something similar)  
      city: "%VAR\_CUSTOMER\_CITY%",  
      country: "{customer.country}",  
      state: \<?php **echo** "\\"" . $state . "\\"" ; ?\>  
    }  
  };  
    
  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document);

\</script\>

## **6\. Integrate your own database**

This example allows you to integrate your own database. If you already have verified customers or you would like to add your own verification rules, you can use the onpresubmit callback to add your own logic before the verification is submitted to us.

\<**noscript**\>\<**meta** http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</**noscript**\>  
\<**script**\>  
(**function**(w,d) {  
  **var** config \= {  
    key: "API KEY",  
    element: "\#order",  
    onpresubmit: **function**(data, done, cancel) {  
      // The customer data is available in data.customer  
      // Send this data to your server or add your own code here to bypass the verification.  
      // (for example, if the customer is already verified in your own database).  
   
      // Call done() to continue with the verification process as normal.  
      // Call cancel() to cancel the verification process and submit the checkout form.  
    }  
  };  
   
  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document); 

\</**script**\>

## **7\. Customize the color and background**

The button and stripe color (the accent color), and the background color/image can be customized on the popup. You can use any valid CSS background for the accent color and background.

* **Examples:**  
  * gray  
  * \#2f9fe6  
  * rgba(0,0,0,0.5)  
  * linear-gradient(135deg, \#7fc24c 0%,\#04a1bf 100%)  
  * https://example.com/image.png

\<**noscript**\>\<**meta** http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</**noscript**\>  
\<**script**\>  
(**function**(w,d) {  
  **var** config \= {  
    key: "API KEY",  
    element: "\#order",  
    background: "rgba(0,0,0,0.7)",  
    accent\_color: "red"  
  };

  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document); 

\</**script**\>

## **8\. Create multiple instances**

To run multiple instances on a page (for example, two different buttons which require two different configs), you must set autoload to false and use the createInstance method to create instances in the onready method of the config. See the examples page for more details. Note: If you want to use the same configuration for multiple buttons, you can just specify an array for the elements config.

Consider an example where a page has a senior discount link and a standard age verification popup on the checkout button. The link to verify those over 55 should apply a discount when the user is verified, and it should also disable the standard age verification check so the user doesn't get verified twice.

In this situation we can set autoload to false to prevent an instance from being created automatically. Once the API is ready, we can create two instances for each situation. The return value of createInstance is an API object specific to the instance, which is then used to unbind the event so that the standard verification is not required.

\<**noscript**\>\<**meta** http-equiv="refresh" content="0;url=https://agechecker.net/noscript"\>\</**noscript**\>  
\<**script**\>  
(**function**(w,d) {  
  **var** config \= {  
    autoload: **false**,  
    onready: **function**() {  
   
      // Create an instance for the regular over 21 verification on the checkout button.  
      **var** regularVerification \= AgeCheckerAPI.createInstance({  
        key: "REGULAR API KEY",  
        element: "\#place-order",  
      });  
   
       // Create an instance for the senior discount verification.  
      AgeCheckerAPI.createInstance({  
        key: "SENIOR DISCOUNT API KEY",  
        element: "\#senior-discount",  
        rename\_element: **false**,  
        onclosed: **function**() {  
          // Upon being verified for the senior discount, unbind the event trigger from the checkout button.  
          regularVerification.unbind()  
   
          // **TODO:** Apply discount  
        }  
      });  
    }  
  };  
   
  w.AgeCheckerConfig=config;**if**(config.path&&(w.location.pathname+w.location.search).indexOf(config.path)) **return**;  
  **var** h=d.getElementsByTagName("head")\[0\];**var** a=d.createElement("script");a.src="https://cdn.agechecker.net/static/popup/v1/popup.js";a.crossOrigin="anonymous";  
  a.onerror=**function**(a){w.location.href="https://agechecker.net/loaderror";};h.insertBefore(a,h.firstChild);  
})(window, document);

\</**script**\>

# **Server API Documentation**

The server-side API allows your own server to create and validate verification requests. To develop a complete custom integration you can use this API to replicate the steps our popup performs.

An example use case could be an order form on your website that collects the user's information and date of birth and then calls our API.

Once you have collected this information and submitted a verification request, you will instantly receive a response indicating if the user has been verified.

If the user was unable to be verified, you can then show our popup only if a signature, photo ID, or phone validation is required (or even develop your own photo ID uploader) by using the AgeCheckerAPI.show(uuid) method on the client. You can also have a text or email message sent to the customer with a link to complete their age verification.

## **Credentials:**

Find your account's secret key and API keys in your [website manager](https://agechecker.net/account/websites).

## **Error Handling:**

If an error occurs due to invalid data or a backend issue, an error status code will be returned with an error property on the response object.

Example: (Status: 400 Bad Request)

{  
  "error": {  
    "code": "invalid\_token",  
    "message": "Domain token was not recognized."  
  }

}

## **API Endpoints:**

### **https://api.agechecker.net/v1/create**

Creates a new verification request from a customer's information.

**Request:**

{  
  // Your domain's API key:  
  "key": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9",

  // Your account's secret key: (May also be passed with the X-AgeChecker-Secret header)  
  "secret": "sample\_secret5e9",

  // Customer data:  
  "data": {  
    "first\_name": "John",  
    "last\_name": "Doe",  
    "address": "1000 Main Street",  
    "city": "Somewhere",  
    "state": "CA", // 2 character state (or province if outside U.S.)  
    "zip": "12345",  
    "country": "US", // 2 character country ISO code  
    "dob\_day": 1,  
    "dob\_month": 1,  
    "dob\_year": 1990,

    // Optional  
    "email": "john@example.com",  
  },

  // Optional configuration settings:  
  // (The secret key must be included to access options)  
  "options": {  
    // Custom minimum age.  
    // If not specified, the minimum age for the buyer or seller will apply.  
    // Accepted values are between 18 and 75\.  
    "min\_age": 19,

    // IP address of the customer.  
    // Required if doing any international verifications.  
    // Recommended to allow us to properly ban fraudulent users. (Your server IP will NOT be mistakenly banned if this is missing)  
    "customer\_ip": "xxx.xxx.xxx.xxx",

    // If a signature, photo ID, or phone validation is required, send a text and/or email with a link to complete their verification.  
    // Use this if you are not handling ID uploads in your checkout process.  
    // Requires data.phone or data.email to be specified.  
    "contact\_customer": **false**,

    // If a signature, photo ID, or phone validation is required, a request will be made to the callback URL when the  
    // status of the verification is updated. (e.g. when the verification is accepted  
    // or denied after the customer uploads an ID at a later time)  
    "callback\_url": "https://example.com/api/agechecker",

    // Optional custom data.  
    // Must be a pair of string keys and values, limited to 10 keys with a maximum length of 25 characters  
    // for the key and 250 characters for the value. This can be used for attaching custom data,  
    // such as the customer ID or order reference number. It will appear in the verification dashboard and the /v1/status endpoint.  
    "metadata": {  
      "my custom key": "some value"  
    }  
  },

  // Optional wording customization options  
  "wording": {

    // Changes mentions of "billing information" in the AgeChecker client popup  
    // and customer contact email to a different term.  
    // Values: shipping, none  
    "info\_type": "shipping"  
  },

  // Optional session UUID (See /v1/session/create endpoint)  
  "session": ""

}

**Response:**

{  
  // Unique verification identifier:  
  // Will not be returned for an error or not\_created status  
  "uuid": "sample\_uuidf0xJcZBX0t59SVYa106rt",

  // Verification status:  
  // Will not be returned if an error occurs  
  // (accepted, denied, signature, photo\_id, phone\_validation, pending, or not\_created)  
  "status": "photo\_id"

}

The verification's UUID will be used to refer to it for all future requests. The status messages refer to the following:

* **Accepted:** The verification request was approved.  
* **Denied:** The verification request was denied. The customer may be underage or submitted an invalid ID (blurry, wrong name, etc.)  
* **Signature:** An e-signature is required from the customer.  
* **Photo ID:** A photo ID is required, the customer has not yet uploaded it.  
* **Phone Validation:** Customer must validate their mobile phone number via SMS code.  
* **Pending:** A photo ID was uploaded and is awaiting manual approval.  
* **Not Created:** Either the customer does not meet the minimum age requirement, their location is blocked, verification is disabled for their region, or they are banned from our system. **Note: A UUID is not returned.**  
* **Error:** An error occurred which prevented your request from being fulfilled. Typically due to missing or invalid data.

**Notes:**

* Please validate that the date of birth of the customer is above the minimum age for their region, or handle the error appropriately if you do send an underage date of birth.  
* If you customize your website's preset and set a state or region to "Disable Verification" or "Block Location", please handle the not\_created status that you will receive if the customer's location matches one of your rules.  
* In order to set a custom minimum age (for example, if you build your own age rules) or use anything in the "options" object, you must also pass your account's secret key, found on the websites tab of your account dashboard.  
* You should pass the customer's IP address so that we can use it to allow international customers to be verified without photo ID. (If you don't, your server IP will be used which may lead to unexpected behavior) It will also allow us to properly block fradulent users.

---

### **https://api.agechecker.net/v1/fraud-risk**

Creates a new fraud risk verification request using a customer's Email, Name, Address, and Date of Birth.

**Note: All subjects are expected to be located in the United States.**

**Request:**

{  
  // Your domain’s API key  
  "key": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9",

  // Your account secret key  
  "secret": "sample\_secret5e9",

  // Customer data  
  "data": {  
    "email": "john@doe.com",  
    "first\_name": "John",  
    "last\_name": "Doe",  
    "address": "1000 Main St",  
    "city": "Somewhere",  
    "state": "NJ",   // 2 character state  
    "zip": "12345",  
    "country": "US", // Country code must be US  
    "dob\_month": "1",  
    "dob\_day": "1",  
    "dob\_year": "1990",

    // Optional  
    "customer\_ip": "111.22.33.444",  
    "shipping\_country": "US",  
    "shipping\_city": "Elsewhere",  
    "shipping\_state": "CA",  
    "shipping\_address": "2000 Second St",  
    "shipping\_zip": "54321"  
  },

}

**Response:**

{  
  // Unique verification identifier  
  "uuid": "sample\_uuidf0xJcZBX0t59SVYa106rt",

  // Fraud risk score from 1-999  
  "score": 60,

  // Fraud Risk Status:  
  // (“Very Low”, “Low”, “Moderate”, “Review”, “High” or “Very High”)  
  "fraud\_risk": "Very Low"

}

The verification's UUID will be used to refer to it for all future requests.

**Score:** An integer 1-999 (inclusive) representing the level of risk determined. Lower scores are determined to be less likely to be fraud.

**Fraud Risk:** Human-readable status of the fraud risk score. Statuses may be subject to change.

---

### **https://api.agechecker.net/v1/status/**

### **uuid**

### **A verification UUID**

Returns the status of a verification request. Usually used to poll the API for the status of a pending photo ID upload or to validate that the request was accepted.

Note: Consider using the callback\_url option instead of polling.

If you specify your secret using the X-AgeChecker-Secret header, you will also receive a copy of the verification data (the domain api key, buyer object, the date it was created, and metadata if any is stored)

**Request:**

GET \- https://api.agechecker.net/v1/status/sample\_uuidf0xJcZBX0t59SVYa106rt

**Response:**

{  
  // Verification status:  
  // (accepted, denied, signature, photo\_id, phone\_validation, sms\_sent, or pending)  
  "status": "denied",

  // Deny reason:  
  // Only included if request was denied  
  // (invalid\_id, underage, info\_missing, info\_mismatch, blocked, fake\_id, blank\_id, expired, selfie\_mismatch, selfie\_id\_missing, selfie\_not\_provided, sms\_failed, both\_sides\_needed)  
  "reason": "underage",

  // (\!) The below lines are only sent if the account secret is specified in the X-AgeChecker-Secret header

  // The domain api key used in creating the verification  
  "key": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9",

  // Verification object containing the buyer and date created  
  "verification": {  
      "buyer": { "first\_name": "TEST", ... },  
      "created": "2020-05-21T17:09:23.312Z"  
   },

  // The optional metadata sent when creating the verification  
  "metadata": { ... }

}

The status of the verification will be one of the strings listed above. If the request was denied, the reason property will be one of the following:

* **Invalid ID:** The uploaded image was not an ID.  
* **Underage:** We determined the user was underage.  
* **Info Missing:** The date of birth and/or name were missing or obscured.  
* **Info Mismatch:** The name on the ID did not match the name submitted.  
* **Blocked:** The user was banned. (Most commonly due to repeated attempts from underage buyers, abuse of our service, fake IDs, etc.)  
* **Fake ID:** The user uploaded a fake or sample image of an ID.  
* **Blank ID:** The uploaded image was blank or corrupted.  
* **Expired ID:** The ID document has expired and is not a legal method of verification.  
* **Selfie Mismatch:** The selfie does not match the face on the ID.  
* **Selfie ID Missing:** ID is missing or unclear in the selfie image.  
* **Selfie Not Provided:** A selfie image with matching ID was not provided.  
* **SMS Failed:** Incorrect phone validation code.  
* **Both Sides Needed:** Both sides of the ID are needed to see the required information.

---

### **https://api.agechecker.net/v1/latest**

Returns the most recent verification from your account within the past 90 days.

If you specify a domain api key using the X-AgeChecker-Key header, we will only search for verifications from that specific site.

**Request:**

GET \- https://api.agechecker.net/v1/latest

**HTTP Headers:**

{  
  // Your account's secret key  
  "X-AgeChecker-Secret": "sample\_secret5e9",

  // Domain api key (optional)  
  "X-AgeChecker-Key": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9"

}

**Response:**

{  
  // Verification uuid:  
  "uuid": "sample\_uuidf0xJcZBX0t59SVYa106rt",

  // Verification created date/time (UTC):  
  "created": "2022-10-31T23:28:23.105Z",  
    
  // Verification status:  
  // (accepted, denied, signature, photo\_id, phone\_validation, sms\_sent, or pending)  
  "status": "accepted",

  // Domain api key used in creating the verification  
  "key": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9",

  // Domain name associated with the api key above  
  "domain": "example.com"

}

---

### **https://api.agechecker.net/v1/session/create**

Creates a new session. Sessions allow you to pass in preconfigured settings to a client-side verification request, including options that are usually only available in our server API with an account secret. You first create a new session using this endpoint on your server, and can then pass the session UUID into our client API or v1/create endpoint to apply those options upon verification creation. (See the "session" option in our [Client API documentation](https://agechecker.net/account/install/custom/client), or "session" property in the v1/create request)

Alternatively, you can also send users a direct link to perform the verification. See the "output" object in the request body below.

**Request:**

{  
  // Your domain's API key:  
  "key": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9",

  // Your account's secret key: (May also be passed with the X-AgeChecker-Secret header)  
  "secret": "sample\_secret5e9",

  // Flow type may be set when creating a session. Available options are;  
  // "default": Standard verification flow. Buyer data will be passed in or gathered from within the popup (if client API is used).  
  // "ocr": OCR verification flow. Buyer data will be pulled from the verification image submitted.  
  // **NOTE:** "ocr" flow type must be enabled on your account in order to be used.  
  "flow\_type": "default",

  // Options that will be passed into the verification when performed  
  // (customer\_ip cannot be passed into this object, and must still be specified in v1/create if relevant to your setup)  
  "options": {  
    // Custom minimum age.  
    // If not specified, the minimum age for the buyer or seller will apply.  
    // Accepted values are between 18 and 75\.  
    "min\_age": 19,

    // If a signature, photo ID, or phone validation is required, send a text and/or email with a link to complete their verification.  
    // Use this if you are not handling ID uploads in your checkout process.  
    // **NOTE:** This requires data.phone or data.email to be specified in the later performed v1/create call. If these are not supplied, this will be ignored.  
    "contact\_customer": **false**,

    // A request will be made to the callback URL on each step of the verification (Including when the verification is first created)  
    "callback\_url": "https://example.com/api/agechecker",

    // Optional custom data.  
    // Must be a pair of string keys and values, limited to 10 keys with a maximum length of 25 characters  
    // for the key and 250 characters for the value. This can be used for attaching custom data,  
    // such as the customer ID or order reference number. It will appear in the verification dashboard and the /v1/status endpoint.  
    "metadata": {  
      "my custom key": "some value"  
    }  
  },

  // Optional wording customization options  
  "wording": {

    // Changes mentions of "billing information" in the AgeChecker client popup  
    // and customer contact email to a different term.  
    // Values: shipping, none  
    "info\_type": "shipping"  
  },

  // Optional request output  
  "output": {

    // When set to true, the request response will contain a direct link to perform a verification tied to the session  
    "link": **true**,

    // When set to true, the request response will contain the base64 url for a QR code image, that points to the direct verification link  
    "qr": **true**  
  }

}

**Response:**

{  
  // Session uuid:  
  "uuid": "sample\_uuidf0xJcZBX0t59SVYa106rt",

  // (\!) Below only included if specified in "output" object of request

  // Direct link to perform a verification tied to the session  
  "link": "https://verify.agechecker.net/s/sample\_uuidf0xJcZBX0t59SVYa106rt",

  // Base64 url for a QR code image, that points to the direct verification link  
  "qr": "data:image/png;base64,iVGDVw1KGgoFFFFBS...."

}

**Notes:**

* Only one verification can be performed per session.  
* Session UUIDs can only be applied to verifications being created under the same API key.

---

### **https://api.agechecker.net/v1/session/get/**

### **uuid**

### **A session UUID**

Returns info from session. Includes the domain API key the session was made for, the performed verification, and frontend data such as wording.

**Request:**

GET \- https://api.agechecker.net/v1/session/get/sample\_uuidf0xJcZBX0t59SVYa106rt

**Response:**

{  
  // Domain API key that the session was made for  
  "website": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9",

  // UUID of the performed verification. (Will be null if no verification has been initiated yet)  
  "verification": "sample\_uuidf0xJcZBX0t59SVYa106rt",

  // Included if "wording" was passed in to original session creation request  
  "wording": { ... }

}

---

## **Verification Webhook:**

When creating a verification request using the server side API, you can handle the signature or photo ID upload step on your own site using the AgeCheckerAPI.show(uuid) method on the client. However, you can also use the contact\_customer option to send the customer an email and/or text with a link to complete their verification. In this case you will likely need to know when the customer is verified so that you can approve their order. This can be done using the callback\_url option, which will make a request from our system to yours when the verification status is updated, such as when the verification is denied or approved. (Please note that a verification can be approved after it has been denied already. This occurs when the user uploads an invalid ID but later uploads a valid one.)

We will send a PUT request to the callback URL with the following data in JSON format:

{  
  // Verification UUID  
  "uuid": "sample\_uuidf0xJcZBX0t59SVYa106rt",

  // Verification status:  
  // (accepted, denied)  
  "status": "denied",

  // Deny reason:  
  // Only included if request was denied.  
  // (invalid\_id, underage, info\_missing, info\_mismatch, blocked, fake\_id, blank\_id, expired, selfie\_mismatch, selfie\_id\_missing, selfie\_not\_provided, sms\_failed, both\_sides\_needed)  
  "reason": "underage"

}

The request will also have the "X-AgeChecker-Signature" header which should be used to verify that the request came from us. You will need to calculate the base64encoded HMAC hash of the request body using the SHA1 algorithm and your account's secret as the key. Below is an example in NodeJS:

**const** crypto \= require('crypto');  
**function** **verifySignature**(data, headers) {  
  **const** key \= headers\['X-AgeChecker-Signature'\];  
  **const** hash \= crypto.createHmac('sha1', "ACCOUNT SECRET HERE")  
    .update(JSON.stringify(data))  
    .digest('base64');

  **return** crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(key));

}

**If you would like to receive a webhook for all requests (such as those created through the popup), contact us to setup an automatic webhook for your account.**

# **Server API Examples**

## **1\. Validate a verification**

Server-side validation is highly recommended to prevent users from bypassing the client side script (although we have added many countermeasures to prevent this).

The client script will add a hidden field named "agechecker\_uuid" to all forms on the page once the customer is verified, it is up to you on whether you use this token to validate that the verification was completed successfully.

To extract the verification UUID, get "agechecker\_uuid" from the form data.

#### **Examples:**

**PHP:**

$uuid \= $\_POST\["agechecker\_uuid"\];

**Node.JS (Express):**

**var** uuid \= req.body.agechecker\_uuid;

To validate this token, a GET request in JSON format needs to be sent to **https://api.agechecker.net/v1/status/\<uuid\>**

**Response:**

{  
    "status": "accepted|denied|signature|photo\_id|pending"

}

If the response is anything but "accepted", you should not allow the transaction to continue. It may be possible that the popup did not load for the user in the case they are using an old browser or there was an error.

If the verification was not found at all, you will receive an error with the code **uuid\_not\_found**.

## **2\. Create a verification**

It may be useful to create a verification request from your server. For example, when the user submits an order or completes a signup form.

A verification request can be created and you will receive a result in around a second. If a signature or photo ID is required, you can launch our popup with the client-side API. This is a great option for creating a seamless integration where our popup is only shown if a signature or photo ID is required. In this case, most customers would simply fill out your form and never see the age verification popup.

Send a POST request in JSON format to **https://api.agechecker.net/v1/create**

{  
  "key": "sample\_keyt7D1aaQsfkdcGubKeb9rJ9",  
  "data": {  
    "address": "1000 Main Street",  
    "city": "Somewhere",  
    "country": "US",  
    "dob\_day": 1,  
    "dob\_month": 1,  
    "dob\_year": 1990,  
    "first\_name": "John",  
    "last\_name": "Doe",  
    "state": "CA",  
    "zip": "12345"  
  }

}

# **Test Buyers**

Whether you have a custom AgeChecker installation or one of our official ones, you might want to test different verification scenarios on your setup before going live. Below are test buyer names that you can input into a verification to trigger specific verification statuses, in order to simulate how your setup will handle different verification scenarios. These names work on both the Client API and Server API.

Note that only the name on the verification is what triggers the test status, so you can use any address, city, state, etc. This allows you to test any location-based age settings you may have set as well.

## **Developer Mode**

By default, these test buyer names will not trigger it's counterpart test status. In order to enable this functionality, you will need to enable **Developer Mode** in your [website manager](https://agechecker.net/account/websites).

You will not be charged for verifications that use test buyer names in the "Name List" below when Developer Mode is enabled. These verifications will be marked with (Test) in your website's verification log.

**NOTE:** After you are done testing, remember to turn **Developer Mode** back to disabled.

#### **Name List:**

| First & Last Name | Test Status |
| :---- | :---- |
| JOHN DOE | Instant Acceptance |
| JANE DOE | Further Verify (Photo-ID Accept) |
| FRANK DOE | Further Verify (Photo-ID Denial) |
| GRACE DOE | Banned |

#### **Glossary:**

| Test Status | Outcome |
| :---- | :---- |
| Instant Acceptance | Verification is marked as accepted instantly after submitting the verification. With a real buyer, this would occur when the buyer is found in our databases. If your website's age settings has "Require ID" or other requirements enabled and the verification's location meets the criteria, the verification will go through those requirements first. If Photo-ID is required, it will be marked as accepted once an image is submitted. |
| Further Verify | Verification will not verify instantly, and will require further verification. If photo ID is prompted, verification will be marked as **accepted** if the test buyer's test status ends with (Photo-ID Accept), or be marked as **denied** if the test status ends in (Photo-ID Denial). With a real buyer, this would occur when the buyer could not be found in our databases. |
| Banned | Verification is marked as blocked and does not continue. With a real buyer, this would occur if the customer was banned globally through our system, or was banned through your AgeChecker dashboard. |

## **Other Functionality**

All test buyer names have the following behavior unless stated otherwise:

**Phone Validation**

When a test buyer verification requires phone validation, a mock phone validation will initiate. When asked for a phone number, submit any phone number. Then, when the verification is pending the code, use the code **111111** to pass the phone validation. Or, use any other code to fail the phone validation.

For the sake of testing, any phone number will be accepted, and an SMS message will not actually be sent.

With a real buyer, phone validation would only accept legitimate U.S. phone numbers that can be found in public records that match the buyer's information, and would send the code to the buyer's phone number through SMS.

# **Enhanced Verification Modes**

The rules below apply to a website (api key) when an enhanced verification rule (such as an ID or Phone requirement) is enabled for one or more locations. Our system combines a Base Rule \+ Modifier to determine the verification process that each customer must complete.

## **Base Rules**

**Every Time:** (Default) Run enhanced verification against a customer every time they submit a verification from the website.

**One Time:** (Formerly "First Time Only") Run enhanced verification against each customer one time. Customers will automatically pass subsequent verifications as long as they complete the enhanced verification process once. Customers who previously passed via Instant Match must complete enhanced verification one time.

**Unverified Only:** Run enhanced verification against new customers after the rule is enabled. Customers who have been previously verified via Instant Match do not need to complete the enhanced verification process.

## **Rule Modifiers**

Modifiers are applied to "One Time" and "Unverified Only" rules.

**Website / API Key:** (Default) Customers who have been verified on the specific website (api key) will be automatically verified moving forward.

**Any Matching Domain:** Customers who have been verified across sites from the same root domain will be automatically verified. For instance, if the website enforcing this rule is *example.com*, an individual who has been verified on a related domain such as *subdomain.example.com* would be automatically verified.

**Any Site in Account:** Customers who have been verified across any site defined in your account (regardless of domain name) would be automatically verified.

## **Examples**

The examples below illustrate rules being applied to *example.com*

**One Time** from **Website / API Key:** A customer must complete the enhanced verification one time on example.com. This matches the behavior of the previous option "First Time Only".

**One Time** from **Any Matching Domain:** If a customer completed enhanced verification on *subdomain.example.com*, they are automatically verified on *example.com*. If they completed enhanced verification on *example2.com*, they still need to complete enhanced verification on *example.com*.

**One Time** from **Any Site in Account:** If a customer completed enhanced verification on *example2.com* (or any other website defined in the account), they are automatically verified on *example.com*.

**Unverified Only** from **Website / API Key:** A customer can be automatically verified on *example.com* if they completed any form of verification (including Instant Match) on the *same site*.

**Unverified Only** from **Any Matching Domain:** A customer can be automatically verified on *example.com* if they completed any form of verification (including Instant Match) on another site with the same root domain such as *subdomain.example.com*.

**Unverified Only** from **Any Site in Account:** A customer can be automatically verified on *example.com* if they completed any form of verification (including Instant Match) on any other domain in the account such as *example2.com*.

## **Order of Precedence**

If enhanced verification rules are applied across multiple geographic layers (such as State-specific and Country-specific rules), the location with the highest level of strictness (highest rank) is applied.

| Rank | Base Rule | Modifier |
| :---- | :---- | :---- |
| 1 | Every Time |  |
| 2  | One Time | Website / API Key |
| 3  | One Time | Any Matching Domain |
| 4  | One Time | Any Site in Account |
| 5  | Unverified Only | Website / API Key |
| 6  | Unverified Only | Any Matching Domain |
| 7  | Unverified Only | Any Site in Account |

