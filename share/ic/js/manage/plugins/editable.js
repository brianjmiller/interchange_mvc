/*
    Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
       
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see: http://www.gnu.org/licenses/ 
*/

YUI.add(
    "ic-manage-plugin-editable",
    function(Y) {

        var Editable = function (config) {
            Editable.superclass.constructor.apply(this, arguments);
        };

        Editable.NAME = 'ic_manage_plugin_editable';
        Editable.NS = 'editable';
        

        // NA!!! refactor this - it now gets only pk_settings and form_data
        Editable.ATTRS = {
            form_data: {
                value: null
            },

            pk_settings: {
                value: null
            },

            func_code: {
                value: null
            },

            mode: {
                value: 'store'
            },

            properties_mode: {
                value: 'basic'
            },

            pk_fields: {
                value: []
            },

            fields_present: {
                value: []
            },

            controls: {
                value: []
            }
        };

        Y.extend (
            Editable,
            Y.Plugin.Base,       // what to extend
            {                    // prototype overrides/additions

// recovering some whitespace...

    _orig_value: null,
    _handlers: null,

    initializer: function () {
        // Y.log('editable::initializer');
        // do general enhancement to the host element
        var host;
        if (this._parseConfig()) {
            host = this.get('host');
            host.set('title', 'Click to Edit');
            //  add an icon and some hover effects indicating 'editable'
            host.addClass('editable');
            this._bindUI();
        }
    }, 

    destructor: function () {
        // Y.log('editable::destructor');
        // remove any classes
        var host = this.get('host');
        host.removeClass('editting');
        host.removeClass('editable');
        host.removeClass('hover');
        host.removeClass('error');

        // detach any events
        this._detachUI();

        // free any objects
        this._orig_value = null;
        this._handlers = null;
    },

    _bindUI: function () {
        // Y.log('editable::_bindUI');
        var host = this.get('host');
        this._handlers = [];
        this._handlers.push(
            host.on('mouseover', function () { this.addClass('hover'); })
        );
        this._handlers.push(
            host.on('mouseout', function () { this.removeClass('hover'); })
        );
        this._handlers.push(
            host.on('click', Y.bind(this._createForm, this))
        );
    },

    _detachUI: function () {
        // Y.log('editable::_detachUI');
        var host = this.get('host');
        Y.each(this._handlers, function (v) {
            host.detach(v);
        });
        this._handlers = [];
    },

    _parseConfig: function () {
        // Y.log('editable::_parseConfig');
        var pk_settings = this.get('pk_settings'), 
            form_data = this.get('form_data'),
            pk_fields = this.get('pk_fields'), 
            controls = this.get('controls'),
            fields_present = this.get('fields_present');

        // parse the pk_settings into what used to be pk_fields
        Y.each(pk_settings, function (v) {
            if (Y.Lang.isValue(v.field) && Y.Lang.isValue(v.value)) {
                pk_fields.push({
                    name: '_pk_' + v.field,
                    value: v.value,
                    type: 'hidden'
                });
            }
        });

        // make an array of hidden fields for each 'present field'
        Y.each(form_data.fields_present, function (v) {
            fields_present.push({
                name: 'fields_present[]',
                value: v,
                type: 'hidden'
            });
        });

        // parse form_data into everything else
        this.set('func_code', form_data.action);
        Y.each(form_data.field_defs, function (v) {
            Y.each(v.controls, function (control) {
                var field_class;
                try {
                    field_class = Y.IC[control.type] || Y[control.type];
                    if (Y.Lang.isFunction(field_class)) {
                        control.type = field_class;
                    }
                }
                catch (err) {
                    // Y.log(err);
                }
                controls.push(control);
            }, this);
        }, this);

        if (pk_fields.length && controls.length) {
            return true;
        }
        else {
            return false;
        }
    },

    _createForm: function () {
        Y.log('editable::_createForm');
        var host, form, fields, controls, hidden, buttons, action;

        this._clearError();

        action = '/manage/function/' + this.get('func_code');
        controls = Y.clone(this.get('controls'));
        hidden = [
            {
                name: '_mode',
                value: this.get('mode'),
                type: 'hidden'
            },
            {
                name: '_properties_mode',
                value: this.get('properties_mode'),
                type: 'hidden'
            }
        ];
        buttons = [
            {
                name: 'submit',
                label: 'Submit',
                type: 'submit'
            },
            {
                name: 'reset',
                label: 'Cancel',
                type: 'reset'
            }
        ];

        fields = [].concat(this.get('pk_fields'), this.get('fields_present'),
                           hidden, controls, buttons);

        Y.log('fields:');
        Y.log(fields);

        form = new Y.IC.ManageEIPForm({
            action: action,
            method: 'post',
            fields: fields,
            skipValidationBeforeSubmit: true
        });

        form.on('manageEIPForm:reset', Y.bind(this._removeForm, this));
        form.on('success', Y.bind(this._handleSuccess, this));
        form.on('failure', Y.bind(this._handleFailure, this));

        host = this.get('host');
        this._orig_value = host.get('innerHTML');
        host.setContent('');
        form.render(host);
        this._beginEditting();
    },

    _removeForm: function (e) {
        // Y.log('editable::_removeForm');
        var host = this.get('host');
        var err_node = host.one('.error_msg');
        host.setContent(this._orig_value);
        if (err_node) {
            host.append(err_node);
            err_node.set('title', 'Click to close.');
            err_node.on('click', Y.bind(this._clearError, this));
        }
        this._finishEditting();
    },

    _clearError: function (e) {
        // Y.log('editable::_clearError');
        try {
            e.halt();
        }
        catch (err) {
            // Y.log(err);
        }
        var host = this.get('host');
        var err_node = host.one('.error_msg');
        if (err_node) {
            err_node.detach('click');
            err_node.remove();
            host.removeClass('error');
        }
    },

    _handleSuccess: function (e) {
        // Y.log('editable::_handleSuccess');
        var response, host;
        try {
            response = Y.JSON.parse(e.response.responseText);
        }
        catch (err) {
            Y.log("Can't parse JSON: " + err, 'error');
            Y.log(e);
            this._handleFailure("Can't parse JSON response: " + err);
            return;
        }
        try {
            e.halt();
        }
        catch (err) {
            // Y.log(err);
        }
        if (response.response_code === 1) {
            host = this.get('host');
            host.setContent(response.value);
            this._finishEditting();
        }
        else {
            this._handleFailure(response);
        }
    },

    _handleFailure: function (e) {
        Y.log('editable::_handleFailure');
        var err_node, err_msg, hr, cr, err_width, host = this.get('host');
        try {
            e.halt();
        }
        catch (err) {
            // Y.log(err);
        }
        if (e.exception) {
            Y.log('Editable Field Failure.  Exception:');
            Y.log(e.exception);
            err_msg = e.exception.message || e.exception;
            err_node = Y.Node.create(
                '<div class="error_msg">' + err_msg + '</div>'
            )
        }
        else {
            Y.log('Editable Field Failure.  Error:');
            Y.log(e);
            err_node = Y.Node.create(
                '<div class="error_msg">' + e + '</div>'
            )
        }
        cr = host.ancestor('div').get('region');
        hr = host.get('region');
        err_width = cr.width + cr.left - (hr.left + hr.width + 30);
        err_node.setStyle('width', err_width + 'px');
        host.append(err_node);
        host.addClass('error');
        this._removeForm();
    },

    _beginEditting: function () {
        // Y.log('editable::_beginEditting');
        var host = this.get('host');
        host.addClass('editting');
        host.removeClass('editable');
        host.removeClass('error');
        this._detachUI();
    },

    _finishEditting: function () {
        // Y.log('editable::_finishEditting');
        var host = this.get('host');
        host.removeClass('editting');
        host.removeClass('hover');
        host.addClass('editable');
        this._bindUI();
    },

    _toggleLoading: function () {
        // toggle a loading class on the host
    }

// giving back previously recovered whitespace
            }
        );

        Y.namespace("IC");
        Y.IC.ManageEditable = Editable;

    },
    "@VERSION@",
    {
        requires: [
            "plugin",
            "io",
            "json-parse",
            "ic-manage-editinplaceform",
            "ic-manage-plugin-editable-css"
        ]
    }
);
