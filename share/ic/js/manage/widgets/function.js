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
    "ic-manage-widget-function",
    function(Y) {
        var ManageFunction;

        var Lang = Y.Lang,
            Node = Y.Node
        ;

        ManageFunction = function (config) {
            ManageFunction.superclass.constructor.apply(this, arguments);
            this.publish('manageFunction:loaded', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
            this.publish('manageFunction:metadata', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
        };

        Y.mix(
            ManageFunction,
            {
                NAME: "ic_manage_function",
                ATTRS: {
                    code: {
                        value: null
                    },
                    kind: {
                        value: null
                    },
                    addtl_args: {
                        value: null,
                        setter: function (new_val) {
                            // container.js stingifies the new_val...
                            if (new_val === 'undefined') {
                                return null;
                            }
                            else {
                                return new_val;
                            }
                        }
                    }
                }
            }
        );

        Y.extend(
            ManageFunction,
            Y.IC.ManageWidget,
            {
                _meta_data: null,
                _content_node: null,

                initializer: function(config) {
                    // Y.log('function::initializer code -> addtl_args');
                    var code = this.get('code');
                    var addtl_args = this.get('addtl_args');
                    // Y.log(code);
                    // Y.log(addtl_args);

                    var url = "/manage/function/" + code + 
                        "/0?_mode=config&_format=json";

                    if (addtl_args) {
                        url = url + "&" + addtl_args;
                    }
                    // Y.log("Url: " + url, "debug");
                    Y.io(
                        url,
                        {
                            sync: false,
                            on: {
                                success: Y.bind(this._parseMetaData, this),
                                failure: function (txnId, response) {
                                    Y.log("Failed to get function meta data", "error");
                                }
                            }
                        }
                    );
                },

                renderUI: function() {
                    // Y.log('function::renderUI');

                    // add a container
                    this._content_node = Y.Node.create(
                        '<div id="' + this.get('code') + '">Loading...</div>'
                    );
                    var cb = this.get('contentBox');
                    cb.setContent("");
                    cb.prepend(this._content_node);
                },

                updateAddtlArgs: function (addtl_args) {
                    this.set('addtl_args', addtl_args);
                },

                _parseMetaData: function(txnId, response) {
                    try {
                        this._meta_data = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        Y.log("Can't parse JSON: " + e, "error");
                        return;
                    }
                    if (this._meta_data) {
                        this.fire('manageFunction:metadata');
                        this._buildUI();
                    }
                },

                _buildUI: function() {
                    // override
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageFunction = ManageFunction;
    },
    "@VERSION@",
    {
        requires: [
            "widget",
            "event-custom",
            "json-parse"
        ]
    }
);



