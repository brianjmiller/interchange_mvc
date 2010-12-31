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
    "ic-renderer-form",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererForm = Y.Base.create(
            "ic_renderer_form",
            Y.IC.RendererBase,
            [],
            {
                _form_node:      null,

                _action:         null,
                _content_config: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this._action         = config.action;
                    this._content_config = config.content;
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._form_node      = null;
                    this._action         = null;
                    this._content_config = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Y.log(Clazz.NAME + "::renderUI - _content_config: " + Y.dump(this._content_config));
                    Clazz.superclass.renderUI.apply(this, arguments);

                    this._form_node = Y.Node.create('<form></form>');

                    this._content_config.render = this._form_node;
                    Y.IC.Renderer.buildContent(this._content_config);

                    this.get("contentBox").setContent(this._form_node);
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");

                    this._form_node.delegate(
                        "click",
                        this.submit,
                        "button.submit",
                        this
                    );
                },

                submit: function (e) {
                    Y.log(Clazz.NAME + "::submit");

                    e.preventDefault();

                    this._form_node.one(".error_msg").setContent("");

                    Y.io(
                        this._action,
                        {
                            // TODO: make this configurable
                            method: 'POST',
                            form: {
                                id: this._form_node.get("id")
                            },
                            data: {
                                _format: "json"
                            },
                            on: {
                                success: Y.bind(this._onRequestSuccess, this),
                                failure: Y.bind(this._onRequestFailure, this)
                            }
                        }
                    );
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestFailure");
                    Y.log(Clazz.NAME + "::_onRequestFailure - response: " + Y.dump(response));
                    this._form_node.one(".error_msg").setContent("Request failed" + " (" + response.status + " - " + response.statusText + ")");
                },

                _onRequestSuccess: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestSuccess");
                    Y.log(Clazz.NAME + "::_onRequestSuccess - response: " + Y.dump(response));

                    var new_data;
                    try {
                        new_data = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        Y.log(Clazz.NAME + "::_onRequestSuccess - Can't parse JSON: " + e, "error");

                        return;
                    }
                    if (new_data) {
                        if (new_data.code > 0) {
                            this.get("contentBox").setContent(new_data.value.response.content);
                        }
                        else {
                            this._form_node.one(".error_msg").setContent(new_data.exception);
                        }
                    }
                }
            },
            {
                ATTRS: {}
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-form-css",
            "ic-renderer-base"
        ]
    }
);
