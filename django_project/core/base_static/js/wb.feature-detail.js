/**
 * Feature form latitude / longitude input on change handler
 * On input change will move the marker and center the map
 * Used in water point add and water point update pages
 * @param options
 */
function attributesFormLatLngInputOnChange (options) {

    var featureForm = _.get(options , 'payload.form');

    var coords = featureForm.getFormFieldValues(['_latitude', '_longitude']);

    var lastMarker = _.last(WB.mapInstance.markerLayer().getLayers());

    lastMarker.setLatLng([coords._latitude, coords._longitude]);

    WB.mapInstance.leafletMap().setView({
        lat: coords._latitude,
        lng: coords._longitude
    }, 10);
}


var FEATURE_DETAIL_EVENTS_MAPPING = {
    latLng: {
        selector: '[data-group-name="basic"]',
        eventType: 'input',
        cbFunc: attributesFormLatLngInputOnChange
    }
};


function parseAttributesForm(content, parseHidden ) {

    parseHidden = parseHidden || true;
    var groupSelector = '[data-group-name]';
    var formFieldSelector = 'input, select';
    var hiddenFieldsId = 'basic_feature_data';

    var allGroups = content.querySelectorAll(groupSelector);

    var values = {};

    var groupsCnt = allGroups.length;

    var groupName;

    for (var i = 0; i < groupsCnt; i += 1) {

        groupName = allGroups[i].dataset.groupName;

        var inputs = allGroups[i].querySelectorAll(formFieldSelector);

        for (var j = 0; j < inputs.length; j += 1) {
            values[groupName + '/' + inputs[j].name] = inputs[j].value;
        }

    }

    // parse hidden inputs
    if (parseHidden === true) {
        var hidden_inputs = document.getElementById(hiddenFieldsId).querySelectorAll('input');

        for (var h = 0; h < hidden_inputs.length; h += 1) {
            values[hidden_inputs[h].name + ''] = hidden_inputs[h].value;
        }
    }

    return values;
}


function SimpleForm(config) {
    this.options = config || {};

    this.isEnabled = config.isEnabled === true;
    this.isBtnVisible = config.isBtnVisible === true;

    this.parent = false;
    this.formDomObj = false;
    this.updateBtn = false;
    this.customEventMapping = config.customEventMapping || FEATURE_DETAIL_EVENTS_MAPPING;

    this.parent = document.getElementById(this.options.parentId);
    this.formDomObj = document.getElementById(this.options.formId);
    this.formParentObj = this.formDomObj.parentNode;
    this.init();
}

SimpleForm.prototype = {
    // on first init formDomObj is undefined
    // formDomObj is used on form error cb
    init: function (formDomObj) {

        if (formDomObj) {
            this.formDomObj = formDomObj;
        }


        this.formFieldset = this.formDomObj.querySelector('fieldset');

        this.formFields = this.getFormFields();

        this.enableForm(this.isEnabled);


        if (this.options.submitBtnSelector) {
            this.updateBtn = this.formDomObj.querySelector(this.options.submitBtnSelector);
        }

        this.showUpdateButton(this.isBtnVisible);

        if (this.options.accordionConf) {
            this.initAccordion();
        }
        this.addEvents();
    },


    replaceFormMarkup: function (htmlString) {

         this.formParentObj.innerHTML = htmlString;

        this.init(this.formParentObj.firstElementChild);
    },

    showUpdateButton: function (show) {
        if (this.updateBtn) {
            this.updateBtn.style.display = show === true ? 'block' : 'none';
        }
    },

    initAccordion: function (selector) {
        var conf = this.options.accordionConf;
        var accordion = selector ? $(selector) : $(this.formDomObj).find(conf.selector);
        accordion.accordion(conf.opts);
    },

    /**
     * "Parse" form to get all form fields (will include all valid HTML fields - form.elements)
     * - returns object with key/val field pairs
     * - field name represents the key, val is the dom obj
     *
     * @param form
     * @returns {object}
     */
    getFormFields: function (form) {
        const fields = form ? form : this.formDomObj.elements;
        return Object.keys(fields).reduce(
            function (acc, cur, i) {
                acc[fields[cur].name] = fields[cur];
                return acc;
            }, {}
        )
    },

    /**
     * Reduce form elements to key (field name) - value pairs, field must have a name
     * @param fieldNames
     * @param formFields
     * @returns {*}
     */
    getFormFieldValues: function (fieldNames, formFields) {
        const fields = formFields ? formFields : this.formDomObj.elements;

        return fieldNames.reduce(
            function (acc, cur, i) {
                acc[fields[cur].name] = fields[cur].value;
                return acc;
            }, {}
        )
    },

    /**
     * Set form field value form a key/val pair
     * - key represents the field name, val the value
     * - the field name must exist in this.formFields
     * @param fieldData
     */
    setFormFieldValues: function (fieldData) {
        var self = this;
        Object.keys(fieldData).forEach(function (fieldName) {
            if (self.formFields[fieldName]) {
                self.formFields[fieldName].value = fieldData[fieldName];
            }
        });
    },

    /**
     * Set / Toggle form active state (enabled / disabled)
     *
     * if isEnabled is not set toggle current state
     * @param isEnabled
     * @returns {*|boolean}
     */
    enableForm: function (isEnabled) {
        var changeActiveStateTo = isEnabled === undefined ? !this.isEnabled : isEnabled;

        if (changeActiveStateTo === true) {
            this.formFieldset.removeAttribute("disabled");
            this.isEnabled = true;
        } else {
            this.formFieldset.setAttribute("disabled", true);
            this.isEnabled = false;
        }
        return this.isEnabled;

    },

    addEvents: function () {
        var self = this;

        if (this.updateBtn) {

            this.formDomObj.addEventListener('onsubmit', function (e) {
                e.preventDefault();
                return false;
            });

            // add click event to form parent (must exist)
            // the form will be replaced so form events will be lost
            WB.utils.addEvent(this.parent, 'click', function (e) {
                if (e.target === self.updateBtn) {
                    var formData = parseAttributesForm(self.formDomObj);

                    if (self.options.onSubmit && self.options.onSubmit instanceof Function) {
                        self.options.onSubmit(formData, self)
                    }
                }
            });

        }

        // init custom events on form dom elements
        WB.utils.initEventsFromConf(this.customEventMapping, this.parent, {form: self});

    }
};

