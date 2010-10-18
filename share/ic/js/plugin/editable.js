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
    "ic-plugin-editable",
    function(Y) {
        var Editable;

        Editable = function (config) {
            Editable.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            Editable,
            {
                NS:    'editable',
                NAME:  'ic_plugin_editable',
                ATTRS: {
                    // info on how to build the form
                    form_config: {
                        value: null
                    }
                }
            }
        );

        Y.extend (
            Editable,
            Y.Plugin.Base,
            {
                _form:           null,
                _form_node:      null,

                _handlers:       null,

                // function provided by the host to run when sucessful submission of
                // an edit occurs to allow it to set new content, etc.
                _host_content_change_callback: null,

                initializer: function (config) {
                    Y.log("plugin_editable::initializer");

                    this._form_node_id = Y.guid();
                    this._form_node = Y.Node.create('<div id="' + this._form_node_id + '"></div>');
                    Y.log("plugin_editable::initializer - _form_node: " + this._form_node);
                    Y.log("plugin_editable::initializer - Y.one(_form_node): " + Y.one(this._form_node_id));

                    if (config.updated_content_handler) {
                        this._host_content_change_callback = config.updated_content_handler;
                    }

                    var host = this.get('host');
                    host.set('title', 'Click to Edit');
                    // add an icon and some hover effects indicating 'editable'
                    host.addClass('editable');

                    this._bindUI();
                }, 

                destructor: function () {
                    Y.log('plugin_editable::destructor');

                    // remove any classes
                    var host = this.get('host');
                    host.removeClass('editting');
                    host.removeClass('editable');
                    host.removeClass('hover');
                    host.removeClass('error');

                    // detach any events
                    this._detachUI();

                    // free any objects
                    this._action         = null;
                    this._pk_fields      = null;
                    this._fields_present = null;
                    this._controls       = null;
                    this._handlers       = null;

                    this._form.destroy(true);
                },

                _bindUI: function () {
                    Y.log('plugin_editable::_bindUI');
                    var host = this.get('host');

                    // TODO: these can be switched to onHostEvent correct?
                    this._handlers = [];
                    this._handlers.push(
                        host.on(
                            'mouseover',
                            function () {
                                this.addClass('hover');
                            }
                        )
                    );
                    this._handlers.push(
                        host.on(
                            'mouseout',
                            function () {
                                this.removeClass('hover');
                            }
                        )
                    );
                    this._handlers.push(
                        host.on('click', Y.bind(this._onClick, this))
                    );
                },

                _detachUI: function () {
                    Y.log('plugin_editable::_detachUI');
                    var host = this.get('host');

                    Y.each(
                        this._handlers,
                        function (v) {
                            host.detach(v);
                        }
                    );
                    this._handlers = [];
                },

                _onClick: function (e) {
                    Y.log('plugin_editable::_onClick');

                    // this has to come first so that the node is already in the DOM
                    // so that the calendar will function properly, if it gets switched
                    // to handle everything internally without querying the DOM then
                    // this could be moved until after rendering the form
                    //
                    // TODO: rename it display form node since that is really what it
                    //       is doing
                    this._displayForm();

                    if (! this._form) {
                        this._createForm();
                        this._renderForm();
                    }

                    this._beginEditing();
                },

                _createForm: function () {
                    Y.log('plugin_editable::_createForm');
                    this._clearError();

                    Y.log("plugin_editable::_createForm - form_config: " + Y.dump(form_config));
                    var form_config = this.get("form_config");

                    // TODO: should this be turned off?
                    form_config.skipValidationBeforeSubmit = true;

                    var form = new Y.IC.Form (form_config);

                    form.after("successful_response", Y.bind(this._afterFormSuccessfulResponse, this));
                    form.after("failed_response", Y.bind(this._afterFormFailedResponse, this));
                    form.on("ic_form_reset", Y.bind(this._onReset, this));

                    this._form = form;
                },

                _renderForm: function () {
                    Y.log('plugin_editable::_renderForm - host: ' + this.get("host"));
                    Y.log('plugin_editable::_renderForm - _form_node: ' + this._form_node);
                    this._form.render(this._form_node);
                },

                _displayForm: function () {
                    Y.log('plugin_editable::_displayForm');

                    Y.log('plugin_editable::_displayForm - host: ' + this.get("host"));
                    Y.log('plugin_editable::_displayForm - _form_node: ' + this._form_node);
                    this.get("host").append(this._form_node);
                },

                _removeForm: function (e) {
                    Y.log('plugin_editable::_removeForm');

                    var host     = this.get('host');
                    var err_node = host.one('.error_msg');

                    if (err_node) {
                        host.append(err_node);
                        err_node.set('title', 'Click to close.');
                        err_node.on('click', Y.bind(this._clearError, this));
                    }

                    this._finishEditing();
                },

                _clearError: function (e) {
                    Y.log('plugin_editable::_clearError');
                    if (e) {
                        try {
                            e.halt();
                        }
                        catch (err) {
                            Y.log("Can't halt event in _clearError: " + err, "error");
                        }
                    }

                    var host     = this.get('host');
                    var err_node = host.one('.error_msg');
                    if (err_node) {
                        err_node.detach('click');
                        err_node.remove();

                        host.removeClass('error');
                    }
                },

                _afterFormSuccessfulResponse: function (response) {
                    Y.log('plugin_editable::_afterFormSuccessfulResponse');

                    // we need to provide the response value to the host
                    // (or a host's callback) to have it update the content
                    if (this._host_content_change_callback) {
                        this._host_content_change_callback(response.value);
                    }

                    this._removeForm();
                },

                _afterFormFailedResponse: function (e) {
                    Y.log('plugin_editable::_afterFormFailedResponse');
                    var err_node, err_msg, hr, cr, err_width;

                    var host = this.get('host');
                    //try {
                        //e.halt();
                    //}
                    //catch (err) {
                        //Y.log("Can't halt error in form failure: " + err, "error");
                    //}

                    if (e.exception) {
                        Y.log("plugin_editable::_afterFormFailedResponse: Exception: " + e.exception);
                        err_msg  = e.exception.message || e.exception;
                        err_node = Y.Node.create(
                            '<div class="error_msg">' + err_msg + '</div>'
                        );
                    }
                    else {
                        Y.log("plugin_editable::_afterFormFailedResponse: Error: " + e);
                        err_node = Y.Node.create(
                            '<div class="error_msg">' + e + '</div>'
                        )
                    }

                    //cr        = host.ancestor('div').get('region');
                    //hr        = host.get('region');
                    //err_width = cr.width + cr.left - (hr.left + hr.width + 30);

                    //err_node.setStyle('width', err_width + 'px');

                    host.append(err_node);
                    host.addClass('error');

                    //this._removeForm();
                },

                _beginEditing: function () {
                    Y.log('plugin_editable::_beginEditing');
                    var host = this.get('host');

                    host.addClass('editting');
                    host.removeClass('editable');
                    host.removeClass('error');

                    this._detachUI();

                    // focus the first non-hidden form control
                    Y.some(
                        this._form.get('fields'),
                        function (v) {
                            Y.log("v.name: " + v.name);
                            if (v.name !== "hidden-field" && v.name !== "ic_formfield_radio" && v.name !== "choice-field") {
                                v._fieldNode.focus();
                                return true;
                            }
                        }
                    );
                },

                _finishEditing: function () {
                    Y.log('plugin_editable::_finishEditing');
                    var host = this.get('host');

                    host.removeClass('editting');
                    host.removeClass('hover');
                    host.addClass('editable');

                    this._bindUI();
                },

                _onReset: function () {
                    Y.log('plugin_editable::_onReset');
                }
            }
        );

        Y.namespace("IC.Plugin");
        Y.IC.Plugin.Editable = Editable;
    },
    "@VERSION@",
    {
        requires: [
            "ic-plugin-editable-css",
            "plugin",
            //"io",
            "json-parse",
            "ic-form"
        ]
    }
);
