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
    "ic-plugin-editable-in_place",
    function(Y) {
        var EditableInPlace;

        EditableInPlace = function (config) {
            EditableInPlace.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            EditableInPlace,
            {
                NS:    'editable_in_place',
                NAME:  'ic_plugin_editable_in_place',
                ATTRS: {
                }
            }
        );

        Y.extend (
            EditableInPlace,
            Y.IC.Plugin.Editable,
            {
                _orig_content: null,

                //initializer: function () {
                    //Y.log("plugin_editable_in_place::initializer");
                //}, 

                destructor: function () {
                    Y.log("plugin_editable_in_place::destructor");
                    this._orig_content = null;
                },

                _displayForm: function () {
                    Y.log("plugin_editable_in_place::_displayForm");
                    var host = this.get("host");

                    this._orig_content = host.get("innerHTML");
                    this.get("host").setContent("");

                    Y.IC.Plugin.EditableInPlace.superclass._displayForm.apply(this, arguments);
                },

                _removeForm: function (bool, e) {
                    Y.log("plugin_editable_in_place::_removeForm");

                    this.get("host").setContent(this._orig_content);

                    Y.IC.Plugin.EditableInPlace.superclass._removeForm.apply(this, arguments);
                },

                _afterFormSuccessfulResponse: function (response) {
                    Y.log("plugin_editable_in_place::_handleSuccessResponse");

                    Y.log("plugin_editable_in_place::_handleSucessResponse - _orig_content: " + this._orig_content);
                    Y.log("plugin_editable_in_place::_handleSucessResponse - response.value: " + response.value);

                    if (this._host_content_change_callback) {
                        this._host_content_change_callback(response.value);
                    }

                    // we don't want to call our own _removeForm because it will restore the original content
                    // but we do still need to remove the form
                    Y.IC.Plugin.EditableInPlace.superclass._removeForm.apply(this, arguments);
                },

                _onReset: function (e) {
                    Y.log("plugin_editable_in_place::_onReset");

                    Y.IC.Plugin.EditableInPlace.superclass._onReset.apply(this, arguments);

                    this._removeForm();
                }
            }
        );

        Y.namespace("IC.Plugin");
        Y.IC.Plugin.EditableInPlace = EditableInPlace;
    },
    "@VERSION@",
    {
        requires: [
            "ic-plugin-editable"
        ]
    }
);
