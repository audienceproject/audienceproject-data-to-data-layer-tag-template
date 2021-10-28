___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
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
    "help": "Your AudienceProject customer ID.",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "CHECKBOX",
    "name": "integrateWithCmp",
    "checkboxText": "Integrate with TCF 2.0 API",
    "help": "Should we integrate with CMP to check storage and personalisation access.",
    "simpleValueType": true,
    "subParams": [
      {
        "type": "CHECKBOX",
        "name": "waitForCmpConsent",
        "checkboxText": "Wait for explicit consent from user",
        "help": "Should we wait for explicit CMP consent from user.",
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "integrateWithCmp",
            "paramValue": true,
            "type": "EQUALS"
          }
        ]
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "audiencesKeyValueMapping",
    "displayName": "Audiences Key/Value Mapping JSON",
    "help": "Your mapping for converting AudienceProject audiences into additional key/value params.",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "REGEX",
        "args": [
          "^{.*}$"
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const callInWindow = require('callInWindow');
const copyFromWindow = require('copyFromWindow');
const createQueue = require('createQueue');
const encodeUriComponent = require('encodeUriComponent');
const getReferrerUrl = require('getReferrerUrl');
const getType = require('getType');
const getUrl = require('getUrl');
const injectScript = require('injectScript');
const JSON = require('JSON');
const localStorage = require('localStorage');
const logToConsole = require('logToConsole');
const makeInteger = require('makeInteger');
const makeString = require('makeString');
const Object = require('Object');

logToConsole('Customer ID is “' + data.customerId + '”');
logToConsole('Integrate with TCF 2.0 API is ' + (data.integrateWithCmp ? 'enabled' : 'disabled'));
logToConsole('Wait for explicit consent from user is ' + (data.waitForCmpConsent ? 'enabled' : 'disabled'));

const audiencesKeyValueMapping = data.audiencesKeyValueMapping ? JSON.parse(data.audiencesKeyValueMapping) : {};
logToConsole('Audiences Key/Value Mapping JSON is “' + JSON.stringify(audiencesKeyValueMapping) + '”');

let allowStorageAccess = true;
let allowPersonalization = true;
let gdprApplies = null;
let consentString = null;

const templateId = 'audienceproject-data-to-data-layer-tag-template:2';

const useCmp = (callback) => {
  if (typeof copyFromWindow('__tcfapi') !== 'function') {
    logToConsole('No TCF 2.0 API found…');
    callback();
    return;
  }

  let shouldIgnoreCmpEvents = false;

  logToConsole('Using TCF 2.0 API…');
  callInWindow('__tcfapi', 'addEventListener', 2, (model, success) => {
    if (shouldIgnoreCmpEvents) {
      return;
    }

    logToConsole('TCF response:', model, success);
    if (!success) {
      return;
    }

    gdprApplies = model.gdprApplies;
    consentString = model.tcString;

    if (model.gdprApplies === false) {
      logToConsole('GDPR is not applies…');
      callback();
      return;
    }

    if (data.waitForCmpConsent &&
      model.eventStatus !== 'tcloaded' &&
      model.eventStatus !== 'useractioncomplete'
    ) {
      logToConsole('Waiting for explicit consent…');
      return;
    }
    shouldIgnoreCmpEvents = true;

    const vendorAudienceProject = 394;
    const purposeUseDevice = 1;
    const purposeCreateAdsProfile = 3;

    const hasVendor = model.vendor && model.vendor.consents && model.vendor.consents[vendorAudienceProject];
    const hasPurpose = id => model.purpose && model.purpose.consents && model.purpose.consents[id];

    allowStorageAccess = hasVendor && hasPurpose(purposeUseDevice);
    allowPersonalization = hasVendor && hasPurpose(purposeCreateAdsProfile);
    logToConsole('Storage access is ' + (allowStorageAccess ? 'enabled' : 'disabled'));
    logToConsole('Personalization is ' + (allowPersonalization ? 'enabled' : 'disabled'));

    callback();
  });
};

const getScriptUrl = () => {
  const domain = allowPersonalization ? 'pdw-usr.userreport.com' : 'dnt-userreport.com';
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

  params.push('appid', templateId);

  if (typeof gdprApplies === 'boolean') {
    params.push('gdpr', makeInteger(gdprApplies));
  }
  if (typeof consentString === 'string') {
    params.push('gdpr_consent', consentString);
  }

  params.forEach((param, index) => {
    const paramJoiner = index ? '&' : '?';
    const partPrefix = index % 2 ? '=' : paramJoiner;
    url += partPrefix + encodeUriComponent(param);
  });

  return url;
};

const getAudienceProjectData = () => {
  const apDataKeyValues = copyFromWindow('apDataKeyValues') || {};
  logToConsole('AudienceProject Data Key/Values:', apDataKeyValues);

  const apDataAudiences = copyFromWindow('apDataAudiences') || [];
  logToConsole('AudienceProject Data Audiences:', apDataAudiences);

  const data = {};

  Object.keys(apDataKeyValues).forEach((key) => {
    data[key] = apDataKeyValues[key];
  });

  const audiencesKeyValueMappingIndex = Object.keys(audiencesKeyValueMapping).reduce((memo, key) => {
    audiencesKeyValueMapping[key].forEach(value => {
      memo[value] = key;
    });
    return memo;
  }, {});

  apDataAudiences.forEach(value => {
    const key = 'ap_' + (audiencesKeyValueMappingIndex[value] || 'x');
    const valueFixed = makeString(value);

    if (typeof data[key] === 'undefined') {
      data[key] = [valueFixed];
    }
    else if (getType(data[key]) !== 'array') {
      data[key] = [data[key], valueFixed];
    }
    else {
      data[key].push(valueFixed);
    }
  });

  return data;
};

const loadData = () => {
  const url = getScriptUrl();
  logToConsole('Loading AudienceProject Data from “' + url + '”');

  const handleScriptLoad = () => {
    logToConsole('AudienceProject Data loaded');

    const audienceProjectData = getAudienceProjectData();
    logToConsole('AudienceProject Data for dataLayer:', audienceProjectData);

    const dataLayerPush = createQueue('dataLayer');
    dataLayerPush({
      event: 'audienceProjectData.loaded',
      audienceProjectData: audienceProjectData,
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
                    "string": "apDataAudiences"
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

scenarios:
- name: Script failed
  code: |-
    mock('injectScript', (url, onSuccess, onFailure) => {
      if (url === scriptUrlRegular) return onFailure();
      return fail();
    });

    runCode({
      customerId: 'test'
    });

    assertApi('injectScript').wasCalled();
    assertApi('createQueue').wasNotCalled();

    assertApi('gtmOnFailure').wasCalled();
- name: no CMP
  code: |-
    mock('injectScript', (url, onSuccess) => {
      if (url === scriptUrlRegular) return onSuccess();
      return fail();
    });

    runCode({
      customerId: 'test'
    });

    assertApi('injectScript').wasCalled();
    assertApi('createQueue').wasCalled();

    assertApi('gtmOnSuccess').wasCalled();
- name: CMP failed
  code: |-
    mock('injectScript', (url, onSuccess) => {
      if (url === scriptUrlRegular) return onSuccess();
      return fail();
    });

    runCode({
      customerId: 'test',
      integrateWithCmp: true,
    });

    assertApi('injectScript').wasCalled();
    assertApi('createQueue').wasCalled();

    assertApi('gtmOnSuccess').wasCalled();
- name: CMP with no gdpr
  code: |-
    mock('injectScript', (url, onSuccess) => {
      if (url === scriptUrlRegularNoGdpr) return onSuccess();
      return fail();
    });

    mock('copyFromWindow', (key) => {
      if (key === '__tcfapi') return () => {};
      if (key === 'apDataKeyValues') return { a: 1 };
      if (key === 'apDataAudiences') return [2];
      return fail();
    });

    mock('callInWindow', (path, arg1, arg2, arg3) => {
      if (path === '__tcfapi') return arg3({
        gdprApplies: false
      }, true);
      return fail();
    });

    runCode({
      customerId: 'test',
      integrateWithCmp: true,
    });


    assertApi('injectScript').wasCalled();
    assertApi('createQueue').wasCalled();

    assertApi('gtmOnSuccess').wasCalled();
- name: CMP with no vendor
  code: |-
    mock('injectScript', (url, onSuccess) => {
      if (url === scriptUrlNonPersonalisedGdpr) return onSuccess();
      return fail();
    });

    mock('copyFromWindow', (key) => {
      if (key === '__tcfapi') return () => {};
      if (key === 'apDataKeyValues') return { a: 1 };
      if (key === 'apDataAudiences') return [2];
      return fail();
    });

    mock('callInWindow', (path, arg1, arg2, arg3) => {
      if (path === '__tcfapi') return arg3({
        gdprApplies: true,
      }, true);
      return fail();
    });

    runCode({
      customerId: 'test',
      integrateWithCmp: true,
    });

    assertApi('injectScript').wasCalled();
    assertApi('createQueue').wasCalled();

    assertApi('gtmOnSuccess').wasCalled();
- name: CMP with no purposes
  code: |-
    mock('injectScript', (url, onSuccess) => {
      if (url === scriptUrlNonPersonalisedGdpr) return onSuccess();
      return fail();
    });

    mock('copyFromWindow', (key) => {
      if (key === '__tcfapi') return () => {};
      if (key === 'apDataKeyValues') return { a: 1 };
      if (key === 'apDataAudiences') return [2];
      return fail();
    });

    mock('callInWindow', (path, arg1, arg2, arg3) => {
      if (path === '__tcfapi') return arg3({
        gdprApplies: true,
        vendor: { consents: { 394: true } },
      }, true);
      return fail();
    });

    runCode({
      customerId: 'test',
      integrateWithCmp: true,
    });

    assertApi('injectScript').wasCalled();
    assertApi('createQueue').wasCalled();

    assertApi('gtmOnSuccess').wasCalled();
- name: CMP with no explicit consent
  code: |-
    mock('injectScript', (url, onSuccess) => {
      if (url === scriptUrlRegularGdpr) return onSuccess();
      return fail();
    });

    mock('copyFromWindow', (key) => {
      if (key === '__tcfapi') return () => {};
      if (key === 'apDataKeyValues') return { a: 1 };
      if (key === 'apDataAudiences') return [2];
      return fail();
    });

    mock('callInWindow', (path, arg1, arg2, arg3) => {
      if (path === '__tcfapi') return arg3({
        gdprApplies: true,
        vendor: { consents: { 394: true } },
        purpose: { consents: { 1: true, 3: true } },
      }, true);
      return fail();
    });

    runCode({
      customerId: 'test',
      integrateWithCmp: true,
      waitForCmpConsent: true,
    });

    assertApi('injectScript').wasNotCalled();
    assertApi('createQueue').wasNotCalled();

    assertApi('gtmOnSuccess').wasNotCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: CMP
  code: |-
    mock('injectScript', (url, onSuccess) => {
      if (url === scriptUrlRegularGdpr) return onSuccess();
      return fail();
    });

    mock('copyFromWindow', (key) => {
      if (key === '__tcfapi') return () => {};
      if (key === 'apDataKeyValues') return { a: 1 };
      if (key === 'apDataAudiences') return [2, 3];
      return fail();
    });

    mock('callInWindow', (path, arg1, arg2, arg3) => {
      if (path === '__tcfapi') return arg3({
        gdprApplies: true,
        vendor: { consents: { 394: true } },
        purpose: { consents: { 1: true, 3: true } },
        eventStatus: 'useractioncomplete',
        tcString: 'abc',
      }, true);
      return fail();
    });

    runCode({
      customerId: 'test',
      integrateWithCmp: true,
      waitForCmpConsent: true,
      audiencesKeyValueMapping: '{"z": [2]}',
    });

    assertApi('injectScript').wasCalled();
    assertApi('createQueue').wasCalled();

    assertApi('gtmOnSuccess').wasCalled();
setup: |-
  mock('getUrl', '__URL__');
  mock('getReferrerUrl', '__REFERRER__');

  const origin = 'https://pdw-usr.userreport.com';
  const originDnt = 'https://dnt-userreport.com';
  const path = '/js/v2/partner/test/uid?med=__URL__&ref=__REFERRER__&appid=audienceproject-data-to-data-layer-tag-template%3A2';

  const scriptUrlRegular = origin + path;
  const scriptUrlRegularNoGdpr = origin + path + '&gdpr=0';
  const scriptUrlNonPersonalisedGdpr = originDnt + path + '&gdpr=1';
  const scriptUrlRegularGdpr = origin + path + '&gdpr=1&gdpr_consent=abc';


___NOTES___

Created on 26/10/2021, 18:28:48
