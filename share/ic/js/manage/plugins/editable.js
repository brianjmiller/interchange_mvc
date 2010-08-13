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
        
        Editable.ATTRS = {
            func_code: {
                value: null
            },

            mode: {
                value: null
            },

            properties_mode: {
                value: null
            },

            pk_fields: {
                value: null
            },

            value: {
                value: null
            },

            multiple: {
                value: null
            },

            useDefaultOption: {
                value: true
            },

            choices: {
                value: null
            },

            field_name: {
                value: null
            },

            field_type: {
                value: null,
                setter: function (type) {
                    // Y.log('editable::field_type setter - type=' + type);
                    var field_class;
                    try {
                        field_class = Y.IC[type] || Y[type];
                        if (Y.Lang.isFunction(field_class)) {
                            return field_class;
                        }
                        else {
                            return type;
                        }
                    }
                    catch (err) {
                        return type;
                    }
                }                
            }
        };

        Y.extend (
            Editable,
            Y.Plugin.Base,       // what to extend
            {                    // prototype overrides/additions

// recovering some whitespace...

    _orig_value: null,
    _handlers: null,
    _field: null,

    initializer: function () {
        // Y.log('editable::initializer');
        // do general enhancement to the host element
        var host = this.get('host');
        host.set('title', 'Click to Edit');
        //  add an icon and some hover effects indicating 'editable'
        host.addClass('editable');
        this._bindUI();
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
        this._field = null;
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

    _createForm: function (data) {
        // Y.log('editable::_createForm');
        var host, form, fields, action;

        this._clearError();

        action = '/manage/function/' + this.get('func_code')
        fields = [
            {
                name: '_mode',
                value: this.get('mode'),
                type: 'hidden'
            },
            {
                name: '_properties_mode',
                value: this.get('properties_mode'),
                type: 'hidden'
            },
            {
                name: this.get('field_name'),
                value: this.get('value') || '',
                type: this.get('field_type') || 'text',
                multiple: this.get('multiple'),
                useDefaultOption: this.get('use_default_option'),
                choices: Y.clone(this.get('choices'))
            },
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
        
        fields = this.get('pk_fields').concat(fields);
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

        Y.each(form.get('fields'), function (v) {
            if (v.get('name') === this.get('field_name')) {
                this._field = v;
            }
        }, this);
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
            this._handleFailure(e);
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
            host.setContent(this._field.get('value'));
            this._finishEditting();
        }
        else {
            this._handleFailure(response);
        }
    },

    _handleFailure: function (e) {
        Y.log('editable::_handleFailure');
        var err_node, hr, cr, err_width, host = this.get('host');
        try {
            e.halt();
        }
        catch (err) {
            // Y.log(err);
        }
        if (e.exception) {
            err_node = Y.Node.create(
                '<div class="error_msg">' + e.exception + '</div>'
            )
        }
        else {
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
        this._field = null;
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
