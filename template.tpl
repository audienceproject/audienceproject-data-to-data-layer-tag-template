___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "audienceproject_data_to_datalayer",
  "version": 1,
  "securityGroups": [],
  "displayName": "AudienceProject Data to dataLayer",
  "brand": {
    "id": "audienceproject",
    "displayName": "AudienceProject",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABCUlEQVR4Ae3YAUZEURTG8VuaSkhPoIT2MPsIaGPRFgJQqwjaQaidTAeAEHOevqt+P74FzPnPgzv4dwAAAAAAAAAAAACAs9q2scuxjk1tO/kuaqs7qD3Udnvuo3Y7+q5qu8l3VyvzRxAgH0GAfAQB8hEEyEcQIB9BgHwEAfIRBMhHECAfQYB8BAHaER4bP+K9duMxbq4vARFEQAQRaDipfTYiPA32dlx7bhz/rbYMHN/xcXzH58fjvzSO/1o7H9+d1u4n3/Vf/ud7DQ0eX4Dw8QUIH1+A8PEFCB9fgPDxBQgfX4Dw8QXIHl+A4PEFCB9fgKPa0thmrOOwtky+zQAAAAAAAAAAAAD4fV/wwCitwu3Q7AAAAABJRU5ErkJggg\u003d\u003d"
  },
  "description": "Push AudienceProject Data to dataLayer on your websites.",
  "containerContexts": [
    "WEB"
  ],
  "categories": [
    "ANALYTICS"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "customerId",
    "displayName": "Customer ID",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "help": "Your AudienceProject customer ID."
  },
  {
    "type": "CHECKBOX",
    "name": "integrateWithCmp",
    "checkboxText": "Integrate with TCF 2.0 API",
    "simpleValueType": true,
    "subParams": [
      {
        "type": "CHECKBOX",
        "name": "waitForCmpConsent",
        "checkboxText": "Wait for explicit consent from user",
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "integrateWithCmp",
            "paramValue": true,
            "type": "EQUALS"
          }
        ],
        "help": "Should we wait for explicit CMP consent from user."
      }
    ],
    "help": "Should we integrate with CMP to check storage and personalisation access."
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const callInWindow = require('callInWindow');
const copyFromWindow = require('copyFromWindow');
const createQueue = require('createQueue');
const encodeUriComponent = require('encodeUriComponent');
const getReferrerUrl = require('getReferrerUrl');
const getUrl = require('getUrl');
const injectScript = require('injectScript');
const localStorage = require('localStorage');
const logToConsole = require('logToConsole');

logToConsole('Customer ID is “' + data.customerId + '”');
logToConsole('Integrate with TCF 2.0 API is ' + (data.integrateWithCmp ? 'enabled' : 'disabled'));
logToConsole('Wait for explicit consent from user is ' + (data.waitForCmpConsent ? 'enabled' : 'disabled'));

let allowStorageAccess = true;
let allowPersonalization = true;

let gdprApplies = null;
let consentString = '';

const requestDomains = {
  regular: 'pdw-usr.userreport.com',
  nonPersonalised: 'dnt-userreport.com',
};

const templateId = 'audienceproject-data-to-data-layer-tag-template';

const useCmp = (callback) => {
  if (typeof copyFromWindow('__tcfapi') !== 'function') {
    logToConsole('No TCF 2.0 API found…');
    return;
  }

  let shouldIgnoreCmpEvents = false;

  const vendorAudienceProject = 394;
  const purposeUseDevice = 1;
  const purposeCreateAdsProfile = 3;

  logToConsole('Using TCF 2.0 API…');
  callInWindow('__tcfapi', 'addEventListener', 2, (model) => {
    if (shouldIgnoreCmpEvents) {
      return;
    }
    logToConsole('TCF response:', model);

    if (model.gdprApplies === false ||
      !data.waitForCmpConsent ||
      ['tcloaded', 'useractioncomplete'].indexOf(model.eventStatus) > -1
    ) {
      const hasVendor = model.gdprApplies === false || (
        model.vendor && model.vendor.consents &&
          model.vendor.consents[vendorAudienceProject] &&
        model.purpose && model.purpose.consents
      );

      gdprApplies = model.gdprApplies;
      consentString = model.tcString;
      allowStorageAccess = hasVendor && model.purpose.consents[purposeUseDevice];
      allowPersonalization = hasVendor && model.purpose.consents[purposeCreateAdsProfile];
      logToConsole('Storage access is ' + (allowStorageAccess ? 'enabled' : 'disabled'));
      logToConsole('Personalization is ' + (allowPersonalization ? 'enabled' : 'disabled'));

      shouldIgnoreCmpEvents = true;
      callback();
    }
  });
};

const getScriptUrl = () => {
  const domain = allowPersonalization ? requestDomains.regular : requestDomains.nonPersonalised;
  let url = 'https://' + domain + '/js/v2/partner/' + encodeUriComponent(data.customerId) + '/uid';

  const params = [];

  const paramUrl = getUrl();
  if (paramUrl) {
    params.push('med', paramUrl);
  }

  const paramReferrer = getReferrerUrl();
  if (paramReferrer) {
    params.push('ref', paramReferrer);
  }

  const localStorageDsuKey = 'apr_dsu';
  const paramDsu = allowStorageAccess && localStorage.getItem(localStorageDsuKey);
  if (paramDsu) {
    params.push('dsu', paramDsu);
  }

  if (typeof gdprApplies === 'boolean') {
    params.push('gdpr', gdprApplies ? 1 : 0);
  }
  if (consentString) {
    params.push('gdpr_consent', consentString);
  }

  params.push('appid', templateId);

  params.forEach((param, index) => {
    const paramJoiner = index ? '&' : '?';
    const partPrefix = index % 2 ? '=' : paramJoiner;
    url += partPrefix + encodeUriComponent(param);
  });

  return url;
};

const loadData = () => {
  const url = getScriptUrl();
  logToConsole('Loading AudienceProject Data from “' + url + '”');

  const handleScriptLoad = () => {
    logToConsole('AudienceProject Data loaded');

    const apDataKeyValues = copyFromWindow('apDataKeyValues');
    logToConsole('AudienceProject Data:', apDataKeyValues);

    const dataLayerPush = createQueue('dataLayer');
    dataLayerPush({
      event: 'audienceProjectData.loaded',
      audienceProjectData: apDataKeyValues,
    });

    logToConsole('AudienceProject Data pushed to dataLayer');
    data.gtmOnSuccess();
  };

  const handleScriptError = () => {
    logToConsole('AudienceProject Data failed to load');
    data.gtmOnFailure();
  };

  injectScript(url, handleScriptLoad, handleScriptError, templateId);
};

if (data.integrateWithCmp) {
  useCmp(() => loadData());
} else {
  loadData();
}


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "__tcfapi"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "apDataKeyValues"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "dataLayer"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://pdw-usr.userreport.com/js/v2/partner/*"
              },
              {
                "type": 1,
                "string": "https://dnt-userreport.com/js/v2/partner/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_local_storage",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "apr_dsu"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_referrer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 12/10/2021, 14:47:38
