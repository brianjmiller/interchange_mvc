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
    "ic-manage-window-content-layout-h_divided",
    function(Y) {
        var ManageWindowContentLayoutHDivided;

        ManageWindowContentLayoutHDivided = function (config) {
            ManageWindowContentLayoutHDivided.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentLayoutHDivided,
            {
                NAME:  "ic_manage_content_layout_h_divided",
                ATTRS: {
                    unit_names: {
                        value: [
                            "top",
                            "center"
                        ]
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentLayoutHDivided,
            Y.IC.ManageWindowContentLayoutBase,
            {
                initializer: function (config) {
                    //Y.log("manage_window_content_layout_h_divided::initializer");

                    this._layout = new Y.YUI2.widget.Layout(
                        this.get("contentBox")._node,
                        {   
                            units: [
                               {   
                                    position: "top",
                                    body:     "manage_content_layout_h_divided_top_body",
                                    zIndex:   0,
                                    scroll:   false,
                                    resize:   false,
                                    height:   189
                                },  
                                {   
                                    position: "center",
                                    header:   "Horizontal Divide Center Unit",
                                    body:     "manage_content_layout_h_divided_center_body",
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
        Y.IC.ManageWindowContentLayoutHDivided = ManageWindowContentLayoutHDivided;
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
