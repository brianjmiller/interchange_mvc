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
    "ic-manage-window-content-layout-base",
    function(Y) {
        var ManageWindowContentLayoutBase; 

        ManageWindowContentLayoutBase = function (config) {
            ManageWindowContentLayoutBase.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentLayoutBase,
            {
                NAME:  "ic_manage_content_layout_base",
                ATTRS: {
                    unit_names: {
                        value: null
                    }
                },

                // prevent second box in two box structure, IOW we only need the bounding box
                CONTENT_TEMPLATE: null
            }
        );
        Y.extend(
            ManageWindowContentLayoutBase,
            Y.Widget,
            {
                _layout: null,
                
                destructor: function () {
                    Y.log("manage_window_content_layout_base::destructor");

                    this._layout = null;
                },

                renderUI: function () {
                    //Y.log("manage_window_content_layout_base::renderUI");
                },

                syncUI: function () {
                    //Y.log("manage_window_content_layout_base::syncUI");
                    this._layout.render();

                    this.hide();
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentLayoutBase = ManageWindowContentLayoutBase;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-layout-base-css",
            "widget"
        ]
    }
);
