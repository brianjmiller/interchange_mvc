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
    "ic-manage-widget-dashboard",
    function(Y) {
        var ManageDashboard;

        var Lang = Y.Lang,
            Node = Y.Node
        ;

        ManageDashboard = function (config) {
            ManageDashboard.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageDashboard,
            {
                NAME: "ic_manage_dashboard",
                ATTRS: {
                    update_interval: {
                        value: "60",
                        validator: Lang.isNumber
                    },
                    last_updated: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageDashboard,
            Y.Widget,
            {
                initializer: function(config) {
                    Y.log("dashboard initializer");
                },

                renderUI: function() {
                    var contentBox = this.get("contentBox");

                    // fill the content area with enough to scroll
                    contentBox.setContent("");
                    var content = '<div>The Dashboard w00t w00t</div>';
                    for (var i = 0; i < 100; i++) {
                        content += '<div>The Dashboard w00t w00t</div>';
                    }
                    contentBox.appendChild(
                        Node.create(content)
                    );
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageDashboard = ManageDashboard;
    },
    "@VERSION@",
    {
        requires: [
            "widget",
        ]
    }
);
