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
    "ic-manage-window-content-layout-full",
    function(Y) {
        var ManageWindowContentLayoutFull;

        ManageWindowContentLayoutFull = function (config) {
            ManageWindowContentLayoutFull.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentLayoutFull,
            {
                NAME:  "ic_manage_content_layout_full",
                ATTRS: {
                    unit_names: {
                        value: [
                            "center"
                        ]
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentLayoutFull,
            Y.IC.ManageWindowContentLayoutBase,
            {
                initializer: function (config) {
                    //Y.log("manage_window_content_layout_full::initializer");
                    this._layout = new Y.YUI2.widget.Layout(
                        this.get("contentBox")._node,
                        {   
                            units: [
                                {   
                                    position: "center",
                                    body:     "manage_content_layout_full_body",
                                    zIndex:   0,
                                    scroll:   true
                                }
                            ]
                        }
                    );
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentLayoutFull = ManageWindowContentLayoutFull;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-layout-base",
            "yui2-layout",
            "yui2-resize"
        ]
    }
);
